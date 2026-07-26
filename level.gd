@abstract class_name Level extends Node2D

var blood_source_: StaticBody2D
var exit_door_: Area2D
var player_spawn_point_: Marker2D
var dracula_spawn_point_: Marker2D
var player_: CharacterBody2D
var dracula_: CharacterBody2D
var in_door_area_: bool

signal level_end_

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("open") and in_door_area_ and dracula_.healed_:
		var sprite: AnimatedSprite2D = exit_door_.get_node("AnimatedSprite2D")
		sprite.play("open")
		await sprite.animation_finished
		level_end_.emit()


func on_player_entered_door_():
	in_door_area_ = true


func on_player_exited_door_():
	in_door_area_ = false
