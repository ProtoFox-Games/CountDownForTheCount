extends Node2D
@export var enemy_scene: PackedScene
var light_destination: float

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	light_destination = 1.0
	$Player.light_source_ = $Path2D/PathFollow2D/PointLight2D
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
	$Path2D/PathFollow2D.progress_ratio = move_toward($Path2D/PathFollow2D.progress_ratio, light_destination, 0.001)
	if $Path2D/PathFollow2D.progress_ratio == 1.0:
		light_destination = 0.0
		$Path2D/PathFollow2D/PointLight2D.enabled = false
	if $Path2D/PathFollow2D.progress_ratio == 0.0:
		light_destination = 1.0
		$Path2D/PathFollow2D/PointLight2D.enabled = true
