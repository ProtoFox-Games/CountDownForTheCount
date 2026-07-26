extends CharacterBody2D

# Constants
const H_VELOCITY: float = 300.0
const V_VELOCITY: float = -400.0
const HURT_DURATION: float = 0.3
const PLAYER_DISTANCE: float = 75.0
const ANIMATIONS: Array = [
	"idle",
	"walk",
	"hurt",
	"die",
	"weakened",
	"die_weakened",
	"resurrection"
]

# Variables
@onready var sprite_: AnimatedSprite2D = $AnimatedSprite2D
var player_: CharacterBody2D
var current_direction_: float = 1.0
var current_state_: DraculaState = DraculaState.WEAKENED
var health_: float = 1.0
var hurt_timer_: float = 0.0
var damage_taken_: float = 0.0
var healed_: bool = false

signal dracula_die_

# --------------- State Machine Begin -------------------

enum DraculaState {
	IDLE = 0,
	WALK = 1,
	HURT = 2,
	DIE = 3,
	WEAKENED = 4,
	DIE_WEAKENED = 5,
	RESURRECTION = 6
}


func state_change_(new_state: DraculaState) -> void:
	if new_state == current_state_:
		return
	
	match new_state:
		DraculaState.HURT:
			hurt_timer_ = HURT_DURATION
	
	current_state_ = new_state


func state_process_(delta: float) -> void:
	match current_state_:
		DraculaState.IDLE:
			state_idle_()
		DraculaState.WALK:
			state_walk_()
		DraculaState.HURT:
			state_hurt_(delta)
		DraculaState.DIE:
			state_die_()
		DraculaState.WEAKENED:
			state_weakened_()
		DraculaState.DIE_WEAKENED:
			state_die_weakened_()
		DraculaState.RESURRECTION:
			state_resurrection_()


func state_idle_() -> void:
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY)
	if player_ != null and not is_within_distance_():
		current_direction_ = get_dracula_direction_()
		state_change_(DraculaState.WALK)
	else:
		sprite_.animation = ANIMATIONS[DraculaState.IDLE]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_walk_() -> void:
	var direction: float = get_dracula_direction_()
	velocity.x = direction * H_VELOCITY
	
	if is_within_distance_():
		state_change_(DraculaState.IDLE)
	else:
		current_direction_ = direction
		sprite_.animation = ANIMATIONS[DraculaState.WALK]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_hurt_(delta: float) -> void:
	# Slow down faster than normal.
	velocity.x = move_toward(velocity.x, 0.0, H_VELOCITY * 2.0)
	
	health_ -= damage_taken_
	damage_taken_ = 0
	
	hurt_timer_ -= delta
	if hurt_timer_ <= 0.0:
		if health_ <= 0.0 and not healed_:
			state_change_(DraculaState.DIE_WEAKENED)
		elif health_ <= 0.0:
			state_change_(DraculaState.DIE)
		elif player_ != null and not is_within_distance_():
			state_change_(DraculaState.WALK)
		else:
			state_change_(DraculaState.IDLE)
	else:
		sprite_.animation = ANIMATIONS[DraculaState.HURT]
		sprite_.flip_h = current_direction_ < 0
		sprite_.play()


func state_die_() -> void:
	# Pan camera to focus on dracula.
	dracula_die_.emit()
	
	# Play death animation.
	sprite_.animation = ANIMATIONS[DraculaState.DIE]
	sprite_.flip_h = current_direction_ < 0
	sprite_.play()
	
	await sprite_.animation_finished
	
	queue_free()
	# Show game over screen.


func state_weakened_() -> void:
	if healed_:
		state_change_(DraculaState.RESURRECTION)
	else:
		sprite_.animation = ANIMATIONS[DraculaState.WEAKENED]
		sprite_.play()


func state_die_weakened_() -> void:
	# Pan camera to focus on dracula.
	dracula_die_.emit()
	
	sprite_.animation = ANIMATIONS[DraculaState.DIE_WEAKENED]
	sprite_.play()
	
	await sprite_.animation_finished
	
	queue_free()
	# Show game over screen.


func state_resurrection_() -> void:
	health_ = 100.0
	sprite_.animation = ANIMATIONS[DraculaState.RESURRECTION]
	sprite_.play()
	await sprite_.animation_finished
	
	state_change_(DraculaState.IDLE)

# --------------- State Machine End -------------------

# ------------- Godot Overrides Begin -----------------

#func _ready() -> void:
	#player_.player_interact_.connect(on_melee_damage_)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	state_process_(delta)
	move_and_slide()

# -------------- Godot Overrides End --------------------

# -------------- Local Helpers Begin --------------------

func get_dracula_direction_() -> float:
	return (player_.position.x - position.x) / absf(player_.position.x - position.x)


func is_within_distance_() -> bool:
	return absf(position.x - player_.position.x) < PLAYER_DISTANCE


func on_melee_damage_(enemy: Node2D, damage: float, blood_acquired: bool) -> void:
	
	if enemy == self:
		if blood_acquired and damage == 0.0:
			healed_ = true
		elif blood_acquired and damage > 0.0:
			damage_taken_ = damage
			state_change_(DraculaState.HURT)
		elif not blood_acquired and damage == 0.0:
			return
		else:
			damage_taken_ = damage
			state_change_(DraculaState.HURT)


func on_player_death_() -> void:
	state_change_(DraculaState.WEAKENED)

# --------------- Local Helpers End ---------------------

# ----------------- Signals Begin -----------------------

# ------------------ Signals End -------------------------
