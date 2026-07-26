extends CharacterBody2D

# Constants
const H_VELOCITY: float = 150.0
const HURT_DURATION: float = 0.3
const ACTIVATION_DISTANCE: float = 100.0
const ATTACK_DISTANCE: float = 50.0
const MELEE_DAMAGE: float = 10
const ANIMATIONS: Array = [
	"idle",
	"walk",
	"attack",
	"hurt",
	"die",
	"celebrate"
]

# Variables
@onready var sprite_: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area_: Area2D = $Area2D
var player_: CharacterBody2D = null
var current_direction_: float = 1.0
var current_state_: EnemyState = EnemyState.IDLE
var health_: float = 50
var hurt_timer_: float = 0.0
var damage_taken_: float = 0.0

signal enemy_attack_(player: CharacterBody2D, damage: float, _unused: bool)

# --------------- State Machine Begin -------------------

enum EnemyState {
	IDLE = 0,
	WALK = 1,
	ATTACK = 2,
	HURT = 3,
	DIE = 4,
	CELEBRATE = 5
}


func state_change_(new_state: EnemyState) -> void:
	if new_state == current_state_:
		return
	
	match new_state:
		EnemyState.HURT:
			hurt_timer_ = HURT_DURATION
	
	current_state_ = new_state


func state_process_(delta: float) -> void:
	match current_state_:
		EnemyState.IDLE:
			state_idle_()
		EnemyState.WALK:
			state_walk_()
		EnemyState.ATTACK:
			state_attack_()
		EnemyState.HURT:
			state_hurt_(delta)
		EnemyState.DIE:
			state_die_()
		EnemyState.CELEBRATE:
			state_celebrate_()

func state_idle_() -> void:
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY)
	var direction = 0.0
	if is_enemy_activated_():
		direction = get_enemy_direction_()
	
	if direction != 0.0:
		current_direction_ = direction
		state_change_(EnemyState.WALK)
	else:
		sprite_.animation = ANIMATIONS[EnemyState.IDLE]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_walk_() -> void:
	var direction: float = get_enemy_direction_()
	velocity.x = direction * H_VELOCITY
	
	if not is_enemy_activated_():
		state_change_(EnemyState.IDLE)
	elif is_within_range_():
		state_change_(EnemyState.ATTACK)
	else:
		current_direction_ = direction
		sprite_.animation = ANIMATIONS[EnemyState.WALK]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_attack_() -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	current_direction_ = get_enemy_direction_()
	attack_area_.scale.x = current_direction_
	sprite_.animation = ANIMATIONS[EnemyState.ATTACK]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	attack_area_.monitoring = true
	attack_area_.monitorable = true
	
	# Wait for the animation to finish. The enemy is locked
	# into the attack animation.
	await sprite_.animation_finished
	attack_area_.monitoring = false
	attack_area_.monitorable = false
	
	if not is_within_range_():
		state_change_(EnemyState.WALK)
	elif not is_enemy_activated_():
		state_change_(EnemyState.IDLE)


func state_hurt_(delta: float) -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	
	health_ -= damage_taken_
	damage_taken_ = 0
	
	hurt_timer_ -= delta
	if hurt_timer_ <= 0.0:
		if health_ <= 0.0:
			state_change_(EnemyState.DIE)
		elif is_within_range_():
			state_change_(EnemyState.ATTACK)
		elif is_enemy_activated_():
			state_change_(EnemyState.WALK)
		else:
			state_change_(EnemyState.IDLE)
	else:
		sprite_.animation = ANIMATIONS[EnemyState.HURT]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_die_() -> void:
	# Play death animation.
	sprite_.animation = ANIMATIONS[EnemyState.DIE]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	await sprite_.animation_finished
	
	# Signal to level to remove node from scene.
	queue_free()


func state_celebrate_() -> void:
	sprite_.animation = ANIMATIONS[EnemyState.CELEBRATE]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()


# --------------- State Machine End -------------------

# ------------- Godot Overrides Begin -----------------

func _ready() -> void:
	player_.player_interact_.connect(on_melee_damage_)
	player_.player_die_.connect(on_player_death_)
	attack_area_.monitoring = false
	attack_area_.monitorable = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	state_process_(delta)
	move_and_slide()

# -------------- Godot Overrides End --------------------

# -------------- Local Helpers Begin --------------------

func is_enemy_activated_() -> bool:
	return absf(player_.position.x - position.x) < ACTIVATION_DISTANCE and absf(player_.position.y - position.y) < ACTIVATION_DISTANCE

func is_within_range_() -> bool:
	return absf(player_.position.x - position.x) < ATTACK_DISTANCE and absf(player_.position.y - position.y) < ATTACK_DISTANCE

func get_enemy_direction_() -> float:
	return (player_.position.x - position.x) / absf(player_.position.x - position.x)

func on_melee_damage_(enemy: CharacterBody2D, damage: float, _ba: bool) -> void:
	if enemy == self:
		damage_taken_ = damage
		state_change_(EnemyState.HURT)

func on_player_death_() -> void:
	state_change_(EnemyState.CELEBRATE)

# --------------- Local Helpers End ---------------------

# ----------------- Signals Begin -----------------------

func _on_area_2d_body_entered(body: Node2D) -> void:
	enemy_attack_.emit(body, MELEE_DAMAGE, false)

# ------------------ Signals End -------------------------
