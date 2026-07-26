@abstract class_name Level extends Node2D

const ENEMY_SCALE: float = 1.5
const DAY_DURATION: int = 5
const NIGHT_DURATION: int = 10
const SUN_OFFSET_X: float = 500.0
const SUN_POSITION_Y: float = 0.0
const SUN_DELTA: float = 0.002

# Components of light source.
@export var light_source_scene_: PackedScene
var sun_path_: Path2D
var sun_path_follow_: PathFollow2D
var light_source_: PointLight2D

# These must be included in the level scene editor as
# nodes.
var blood_source_: StaticBody2D
var exit_door_: Area2D
var player_spawn_point_: Marker2D
var dracula_spawn_point_: Marker2D

# Timer is created in code.
var day_timer_: Timer
var night_timer_: Timer

# Number of day night cycles that have passed.
var cycles_: int
var in_door_area_: bool

@export var hud_scene_: PackedScene
var hud_: CanvasLayer

# Managed by GameManager
# Do not instantiate new objects of these.
# Essentially just pointers.
var player_: CharacterBody2D
var dracula_: CharacterBody2D

signal cycle_(cycle: int)
signal level_end_

# --------------- Functions to override ---------------------

# Define any enemies in the level, or define enemy spawn
# behavior. Connect enemy and player signals.
@abstract func level_init_() -> void

# ----------------- Helper Functions -------------------------

func connect_enemy_to_player_(enemy: CharacterBody2D) -> void:
	enemy.player_ = player_
	enemy.enemy_attack_.connect(player_.on_melee_damage_)
	enemy.enemy_attack_.connect(dracula_.on_melee_damage_)


func setup_hud_() -> void:
	hud_ = hud_scene_.instantiate()
	player_.player_health_change_.connect(hud_.on_health_changed_)
	hud_.timer_ = night_timer_
	cycle_.connect(hud_.on_cycle_passed_)
	add_child(hud_)


func setup_light_source_() -> void:
	sun_path_ = light_source_scene_.instantiate()
	add_child(sun_path_)
	set_sun_path_curve_()
	sun_path_follow_ = sun_path_.get_node("PathFollow2D")
	light_source_ = sun_path_follow_.get_node("PointLight2D")
	light_source_.enabled = false
	
	player_.light_source_ = light_source_


func setup_day_night_timers_() -> void:
	day_timer_ = Timer.new()
	day_timer_.process_callback = Timer.TIMER_PROCESS_PHYSICS
	day_timer_.wait_time = DAY_DURATION
	day_timer_.one_shot = false
	day_timer_.autostart = false
	day_timer_.timeout.connect(on_day_timer_timeout_)
	add_child(day_timer_)
	
	night_timer_ = Timer.new()
	night_timer_.process_callback = Timer.TIMER_PROCESS_PHYSICS
	night_timer_.wait_time = NIGHT_DURATION
	night_timer_.one_shot = false
	night_timer_.autostart = false
	night_timer_.timeout.connect(on_night_timer_timeout_)
	add_child(night_timer_)


func set_sun_path_curve_() -> void:
	var curve: Curve2D = Curve2D.new()
	curve.add_point(Vector2(player_.position.x - SUN_OFFSET_X, SUN_POSITION_Y))
	curve.add_point(Vector2(player_.position.x + SUN_OFFSET_X, SUN_POSITION_Y))
	sun_path_.curve = curve


func on_day_timer_timeout_() -> void:
	day_timer_.stop()
	cycles_ += 1
	if cycles_ == 5:
		# Show game over screen
		pass
	cycle_.emit(6 - cycles_)
	light_source_.enabled = false
	hud_.timer_ = night_timer_
	night_timer_.start()


func on_night_timer_timeout_() -> void:
	night_timer_.stop()
	set_sun_path_curve_()
	sun_path_follow_.progress = 0.0
	light_source_.enabled = true
	hud_.timer_ = day_timer_
	day_timer_.start()


func on_player_entered_door_():
	in_door_area_ = true


func on_player_exited_door_():
	in_door_area_ = false

# ------------------- Godot Overrides -------------------------

func _ready() -> void:
	cycles_ = 0
	in_door_area_ = false
	setup_day_night_timers_()
	set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("open") and in_door_area_ and dracula_.healed_:
		var sprite: AnimatedSprite2D = exit_door_.get_node("AnimatedSprite2D")
		sprite.play("open")
		await sprite.animation_finished
		level_end_.emit()
		
	sun_path_follow_.progress_ratio = move_toward(sun_path_follow_.progress_ratio, 1.0, SUN_DELTA)
