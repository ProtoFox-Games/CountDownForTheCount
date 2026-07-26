extends CanvasLayer

var timer_: Timer

func on_health_changed_(damage: float) -> void:
	$HealthBar.value -= damage


func on_cycle_passed_(cycle: int) -> void:
	var sprite: AnimatedSprite2D = get_node("DraculaHead" + str(cycle))
	sprite.hide()


func _physics_process(_delta: float) -> void:
	if timer_:
		$Timer.text = str(timer_.time_left).pad_decimals(0)
