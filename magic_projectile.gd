extends Area2D

const H_VELOCITY: float = 400.0
const PROJECTILE_DAMAGE: float = 25.0

@onready var sprite_: AnimatedSprite2D = $AnimatedSprite2D
var current_direction_: float
var is_moving_: float
var body_count_:int

signal magic_projectile_contact_(body: Node2D, damage: float)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	is_moving_ = 1.0
	body_count_ = 0
	sprite_.animation = "fly"
	sprite_.flip_h = current_direction_ < 0.0
	sprite_.play()


func _physics_process(delta: float) -> void:
	position.x += H_VELOCITY * delta * current_direction_ * is_moving_


func _on_body_entered(body: Node2D) -> void:
	if body_count_ >= 1:
		is_moving_ = 0.0
		magic_projectile_contact_.emit(body, PROJECTILE_DAMAGE)
		sprite_.animation = "land"
		sprite_.flip_h = current_direction_ < 0.0
		sprite_.play()
		await sprite_.animation_finished
		queue_free()
	else:
		body_count_ += 1
		return
