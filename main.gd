extends Node2D

@export var enemy_scene: PackedScene
var ticks: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ticks = 0
	$Dracula.player_ = $Player
	$Dracula.player_.player_interact_.connect($Dracula.on_melee_damage_)
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	enemy.player_ = $Player
	enemy.position.x = 150
	enemy.position.y = 275
	enemy.scale.x = 1.5
	enemy.scale.y = 1.5
	enemy.enemy_attack_.connect($Player.on_melee_damage_)
	
	var enemy2: CharacterBody2D = enemy_scene.instantiate()
	enemy2.player_ = $Player
	enemy2.position.x = 500
	enemy2.position.y = 275
	enemy2.scale.x = 1.5
	enemy2.scale.y = 1.5
	enemy2.enemy_attack_.connect($Player.on_melee_damage_)
	
	add_child(enemy)
	#add_child(enemy2)
	

func _physics_process(delta: float) -> void:
	ticks += 1
	if ticks == 300:
		$DirectionalLight2D.enabled = false
	if ticks == 600:
		$DirectionalLight2D.enabled = true
		ticks = 0
