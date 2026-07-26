extends Area2D

signal player_entered_door_
signal player_exited_door_


func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_entered_door_.emit()


func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_exited_door_.emit()
