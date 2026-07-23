extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0

var p_dir: Vector2 = Vector2.RIGHT

func _physics_process(delta: float) -> void:
	if Input.is_action_pressed("ui_right"):
		velocity.x = SPEED * Input.get_action_strength("ui_right")
		p_dir = Vector2.RIGHT
		if is_on_floor():
			$AnimatedSprite2D.animation = "walk_right"
			$AnimatedSprite2D.flip_h = false
	if Input.is_action_pressed("ui_left"):
		velocity.x = -1 * SPEED * Input.get_action_strength("ui_left")
		p_dir = Vector2.LEFT
		if is_on_floor():
			$AnimatedSprite2D.animation = "walk_right"
			$AnimatedSprite2D.flip_h = true
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		$AnimatedSprite2D.animation = "jump"
		$AnimatedSprite2D.flip_h = p_dir.x < 0
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		$AnimatedSprite2D.animation = "jump"
	if not Input.is_anything_pressed():
		velocity.x = 0
		$AnimatedSprite2D.animation = "idle_right"
		$AnimatedSprite2D.flip_h = p_dir.x < 0
	
	$AnimatedSprite2D.play()
	move_and_slide()
