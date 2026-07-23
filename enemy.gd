extends CharacterBody2D


const SPEED = 150.0

var player: CharacterBody2D = null

func _physics_process(delta: float) -> void:
	position.x = move_toward(position.x, player.position.x, 0.5)
	print("player pos: ", player.position.x)
	print("", velocity.x)
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if absf(position.x - player.position.x) < 50:
		velocity.x = 0
		$AnimatedSprite2D.animation = "attack"
		$AnimatedSprite2D.flip_h = player.position.x < position.x
	elif player.position.x > position.x:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = false
	elif player.position.x < position.x:
		$AnimatedSprite2D.animation = "walk"
		$AnimatedSprite2D.flip_h = true
	else:
		velocity.x = 0
		$AnimatedSprite2D.animation = "idle"
		$AnimatedSprite2D.flip_h = player.position.x < position.x
	
	$AnimatedSprite2D.play()
	move_and_slide()
