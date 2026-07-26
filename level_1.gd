extends Level

@export var enemy_scene: PackedScene

func setup_enemies_() -> void:
	# Setup enemies
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	connect_enemy_to_player_(enemy)
	enemy.scale *= ENEMY_SCALE
	enemy.position = $EnemySpawnPoint1.position
	add_child(enemy)
	
	var enemy1: CharacterBody2D = enemy_scene.instantiate()
	connect_enemy_to_player_(enemy1)
	enemy1.scale *= ENEMY_SCALE
	enemy1.position = $EnemySpawnPoint2.position
	add_child(enemy1)
	
	super.set_physics_process(true)
	set_physics_process(true)
	night_timer_.start()

# ----------------- Helper Functions -------------------------:

func level_init_() -> void:
	# Setup HUD
	hud_ = hud_scene_.instantiate()
	player_.player_health_change_.connect(hud_.on_health_changed_)
	hud_.timer_ = night_timer_
	cycle_.connect(hud_.on_cycle_passed_)
	add_child(hud_)
	
	# Setup light source.
	sun_path_ = light_source_scene_.instantiate()
	add_child(sun_path_)
	set_sun_path_curve_()
	sun_path_follow_ = sun_path_.get_node("PathFollow2D")
	light_source_ = sun_path_follow_.get_node("PointLight2D")
	light_source_.enabled = false
	
	player_.light_source_ = light_source_
	
	# Setup enemies
	var enemy: CharacterBody2D = enemy_scene.instantiate()
	connect_enemy_to_player_(enemy)
	enemy.scale *= ENEMY_SCALE
	enemy.position = $EnemySpawnPoint1.position
	add_child(enemy)
	
	var enemy1: CharacterBody2D = enemy_scene.instantiate()
	connect_enemy_to_player_(enemy1)
	enemy1.scale *= ENEMY_SCALE
	enemy1.position = $EnemySpawnPoint2.position
	add_child(enemy1)
	
	super.set_physics_process(true)
	set_physics_process(true)
	night_timer_.start()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	super._ready()
	player_spawn_point_ = $PlayerSpawnPoint
	dracula_spawn_point_ = $DraculaSpawnPoint
	blood_source_ = $BloodSource
	exit_door_ = $ExitDoor


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
