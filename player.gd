extends CharacterBody2D

# Constants
const H_VELOCITY: float = 300.0
const V_VELOCITY: float = -400.0
const DASH_VELOCITY: float = 600.0
const HURT_DURATION: float = 0.3
const LAND_DURATION: float = 0.1
const MELEE_DAMAGE: float = 25.0
const ANIMATIONS: Array = [
	"idle",
	"walk",
	"dash",
	"fall",
	"fall",
	"land",
	"attack",
	"shoot",
	"hurt",
	"die",
	"interact",
]

# Variables
@export var magic_projectile_: PackedScene
@onready var sprite_: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_: Area2D = $Area2D
var current_direction_: float = 1.0
var current_state_: PlayerState = PlayerState.IDLE
var health_: float = 100.0
var damage_taken_: float = 0.0
var hurt_timer_: float = 0.0
var land_timer_: float = 0.0
var attack_damage_: float = 0.0
var jump_count_: int = 0
var blood_acquired_: bool = false

# Signals
signal player_interact_(enemy: Node2D, damage: float, blood_acquired: bool)
signal player_die_

# --------------- State Machine Begin -------------------

enum PlayerState {
	IDLE = 0,
	WALK = 1,
	DASH = 2,
	JUMP = 3,
	FALL = 4,
	LAND = 5,
	ATTACK = 6,
	SHOOT = 7,
	HURT = 8,
	DIE = 9,
	INTERACT = 10,
}


func state_change_(new_state: PlayerState) -> void:
	if new_state == current_state_:
		return
	
	match new_state:
		PlayerState.LAND:
			land_timer_ = LAND_DURATION
			jump_count_ = 0
		PlayerState.HURT:
			hurt_timer_ = HURT_DURATION
		PlayerState.ATTACK:
			attack_damage_ = MELEE_DAMAGE
		PlayerState.INTERACT:
			attack_damage_ = 0.0
	
	current_state_ = new_state


func state_process_(delta: float) -> void:
	match current_state_:
		PlayerState.IDLE:
			state_idle_()
		PlayerState.WALK:
			state_walk_()
		PlayerState.DASH:
			state_dash_()
		PlayerState.JUMP:
			state_jump_()
		PlayerState.FALL:
			state_fall_()
		PlayerState.LAND:
			state_land_(delta)
		PlayerState.ATTACK:
			state_attack_()
		PlayerState.SHOOT:
			state_shoot_()
		PlayerState.HURT:
			state_hurt_(delta)
		PlayerState.DIE:
			state_die_()
		PlayerState.INTERACT:
			state_interact_()


func state_idle_() -> void:
	# Smooth transition to a stop if player was previously
	# moving before transitioning to this state.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY)
	
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		current_direction_ = direction
		state_change_(PlayerState.WALK)
	elif Input.is_action_just_pressed("jump"):
		state_change_(PlayerState.JUMP)
	elif Input.is_action_just_pressed("attack"):
		state_change_(PlayerState.ATTACK)
	elif Input.is_action_just_pressed("shoot"):
		state_change_(PlayerState.SHOOT)
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
	elif Input.is_action_just_pressed("interact"):
		state_change_(PlayerState.INTERACT)
	elif not is_on_floor():
		state_change_(PlayerState.FALL)
	else:
		sprite_.animation = ANIMATIONS[PlayerState.IDLE]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_walk_() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	velocity.x = direction * H_VELOCITY
	
	if direction == 0.0:
		state_change_(PlayerState.IDLE)
	elif Input.is_action_just_pressed("jump"):
		state_change_(PlayerState.JUMP)
	elif Input.is_action_just_pressed("attack"):
		state_change_(PlayerState.ATTACK)
	elif Input.is_action_just_pressed("shoot"):
		state_change_(PlayerState.SHOOT)
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
	elif Input.is_action_just_pressed("interact"):
		state_change_(PlayerState.INTERACT)
	else:
		current_direction_ = direction
		sprite_.animation = ANIMATIONS[PlayerState.WALK]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_dash_() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		current_direction_ = direction
	velocity.x = current_direction_ * DASH_VELOCITY
	
	sprite_.animation = ANIMATIONS[PlayerState.DASH]
	#sprite_.animation = "dash_2"
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	await sprite_.animation_finished
	
	if not is_on_floor():
		state_change_(PlayerState.FALL)
	else:
		state_change_(PlayerState.IDLE)


func state_jump_() -> void:
	jump_count_ += 1
	velocity.y = V_VELOCITY
	# Begin falling as soon as the player jumps.
	state_change_(PlayerState.FALL)


func state_fall_() -> void:
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0:
		current_direction_ = direction
	velocity.x = direction * H_VELOCITY
	
	if is_on_floor():
		state_change_(PlayerState.LAND)
	elif Input.is_action_just_pressed("jump") and jump_count_ < 2:
		state_change_(PlayerState.JUMP)
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
	elif Input.is_action_just_pressed("shoot"):
		state_change_(PlayerState.SHOOT)
	else:
		sprite_.animation = ANIMATIONS[PlayerState.FALL]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_land_(delta: float) -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	
	land_timer_ -= delta
	var direction: float = Input.get_axis("move_left", "move_right")
	if land_timer_ <= 0.0:
		if direction != 0.0:
			current_direction_ = direction
			state_change_(PlayerState.WALK)
		else:
			state_change_(PlayerState.IDLE)
	else:
		sprite_.animation = ANIMATIONS[PlayerState.LAND]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_attack_() -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	attack_area_.monitoring = true
	attack_area_.monitorable = true
	attack_area_.scale.x = current_direction_ / absf(current_direction_)
	sprite_.animation = ANIMATIONS[PlayerState.ATTACK]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	# Wait for the animation to finish. The player is locked
	# into the attack animation.
	await sprite_.animation_finished
	attack_area_.monitoring = false
	attack_area_.monitorable = false
	
	var direction: float = Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		current_direction_ = direction
		state_change_(PlayerState.WALK)
	else:
		state_change_(PlayerState.IDLE)


func state_shoot_() -> void:
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	
	var projectile: Area2D = magic_projectile_.instantiate()
	projectile.current_direction_ = current_direction_
	projectile.position.y = position.y
	projectile.position.x = position.x
	projectile.magic_projectile_contact_.connect(_on_magic_projectile_landed)
	
	sprite_.animation = ANIMATIONS[PlayerState.SHOOT]
	sprite_.flip_h = current_direction_ < 0.0
	sprite_.play()
	await sprite_.animation_finished
	
	get_tree().current_scene.add_child(projectile)
	
	
	if not is_on_floor():
		state_change_(PlayerState.FALL)
	else:
		state_change_(PlayerState.IDLE)


func state_hurt_(delta: float) -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	
	health_ -= damage_taken_
	damage_taken_ = 0.0
	if health_ <= 0.0:
		state_change_(PlayerState.DIE)
	
	hurt_timer_ -= delta
	var direction: float = Input.get_axis("move_left", "move_right")
	if hurt_timer_ <= 0.0:
		if direction != 0.0:
			current_direction_ = direction
			state_change_(PlayerState.WALK)
		else:
			state_change_(PlayerState.IDLE)
	else:
		sprite_.animation = ANIMATIONS[PlayerState.HURT]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_die_() -> void:
	player_die_.emit()
	# Play death animation.
	sprite_.animation = ANIMATIONS[PlayerState.DIE]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	await sprite_.animation_finished
	
	# Show game over screen.
	# Restart current level.
	queue_free()


func state_interact_() -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	attack_area_.monitoring = true
	attack_area_.monitorable = true
	attack_area_.scale.x = current_direction_ / absf(current_direction_)
	sprite_.animation = ANIMATIONS[PlayerState.INTERACT]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	# Wait for the animation to finish. The player is locked
	# into the attack animation.
	await sprite_.animation_finished
	attack_area_.monitoring = false
	attack_area_.monitorable = false
	
	state_change_(PlayerState.IDLE)

# --------------- State Machine End -------------------

# ------------- Godot Overrides Begin -----------------

func _ready() -> void:
	attack_area_.monitoring = false
	attack_area_.monitorable = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	state_process_(delta)
	move_and_slide()

# -------------- Godot Overrides End --------------------

# -------------- Local Helpers Begin --------------------

func on_melee_damage_(body: Node2D, damage: float) -> void:
	if body == self:
		damage_taken_ = damage
		state_change_(PlayerState.HURT)

# --------------- Local Helpers End ---------------------

# ----------------- Signals Begin -----------------------

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is StaticBody2D:
		blood_acquired_ = true
		body.queue_free()
	else:
		player_interact_.emit(body, attack_damage_, blood_acquired_)
	

func _on_magic_projectile_landed(body: Node2D, damage: float) -> void:
	player_interact_.emit(body, damage, blood_acquired_)

# ------------------ Signals End -------------------------
