extends Node2D

@export var enemy_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	enemy.player = $Player
	enemy.position.x = 150
	enemy.position.y = 275
	enemy.scale.x = 1.5
	enemy.scale.y = 1.5
	
	var enemy2: CharacterBody2D = enemy_scene.instantiate()
	enemy2.player = $Player
	enemy2.position.x = 500
	enemy2.position.y = 275
	enemy2.scale.x = 1.5
	enemy2.scale.y = 1.5
	
	add_child(enemy)
	add_child(enemy2)
	
