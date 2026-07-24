extends CharacterBody2D

# Constants
const H_VELOCITY: float = 300.0
const V_VELOCITY: float = -400.0
const DASH_VELOCITY: float = 600.0
const HURT_DURATION: float = 0.5
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
	"hurt",
	"die"
]

# Variables
@onready var sprite_: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_: Area2D = $Area2D
var current_direction_: float = 1.0
var current_state_: PlayerState = PlayerState.IDLE
var health_: float = 100.0
var damage_taken_: float = 0.0
var hurt_timer_: float = 0.0
var land_timer_: float = 0.0

# Signals
signal player_attack_(enemy: CharacterBody2D, damage: float)
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
	HURT = 7,
	DIE = 8
}


func state_change_(new_state: PlayerState) -> void:
	if new_state == current_state_:
		return
	
	match new_state:
		PlayerState.LAND:
			land_timer_ = LAND_DURATION
		PlayerState.HURT:
			hurt_timer_ = HURT_DURATION
	
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
		PlayerState.HURT:
			state_hurt_(delta)
		PlayerState.DIE:
			state_die_()

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
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
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
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
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
	# No double jump implemented...
	# Maybe we can transform into a bat?
	if not is_on_floor():
		return
	
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
	elif Input.is_action_just_pressed("dash"):
		state_change_(PlayerState.DASH)
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
	player_attack_.emit(body, MELEE_DAMAGE)

# ------------------ Signals End -------------------------
