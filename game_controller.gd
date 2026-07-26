extends Node

const PLAYER_SCALE: float = 5.0
const DRACULA_SCALE: float = 1.5
const PLAYER_Z_INDEX: int = 5

const LEVELS: Array = [
	"res://levels/tutorial.tscn",
	"res://levels/Lvl_1.tscn",
]

var current_level_: Level = null
var current_level_number_: int = 0
@onready var player_: CharacterBody2D = $Player
@onready var dracula_: CharacterBody2D = $Dracula


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var level_scene: PackedScene = load(LEVELS[current_level_number_])
	current_level_ = level_scene.instantiate()
	add_child(current_level_)
	player_.position = current_level_.player_spawn_point_.position
	player_.scale *= PLAYER_SCALE
	player_.z_index = PLAYER_Z_INDEX
	player_.player_die_.connect(on_game_over_)
	
	dracula_.position = current_level_.dracula_spawn_point_.position
	dracula_.scale *= DRACULA_SCALE
	dracula_.z_index = PLAYER_Z_INDEX
	dracula_.player_ = player_
	dracula_.player_.player_interact_.connect(dracula_.on_melee_damage_)
	dracula_.dracula_die_.connect(on_game_over_)
	
	current_level_.player_ = player_
	current_level_.dracula_ = dracula_
	current_level_.exit_door_.player_entered_door_.connect(current_level_.on_player_entered_door_)
	current_level_.exit_door_.player_exited_door_.connect(current_level_.on_player_exited_door_)
	current_level_.level_end_.connect(on_level_end_)
	current_level_.level_fail_.connect(on_game_over_)
	current_level_.level_init_()


func change_level_(level: int) -> void:
	if current_level_number_ == 2:
		current_level_number_ = 0
	if current_level_number_ == level:
		player_.position = current_level_.player_spawn_point_.position
		dracula_.position = current_level_.dracula_spawn_point_.position
		#current_level_.level_init_()
		var enemy = get_tree().get_first_node_in_group("enemies")
		if enemy == null:
			current_level_.setup_enemies_()
		else:
			enemy.enemy_reset_()
		dracula_.dracula_reset_()
		player_.player_reset_()
		current_level_.hud_.get_node("DraculaHead1").visible = true
		current_level_.hud_.get_node("DraculaHead2").visible = true
		current_level_.hud_.get_node("DraculaHead3").visible = true
		current_level_.hud_.get_node("DraculaHead4").visible = true
		current_level_.hud_.get_node("DraculaHead5").visible = true
		current_level_.cycles_ = 0
		current_level_.hud_.get_node("HealthBar").value = 100.0
		return
		
	current_level_number_ += 1
	current_level_.queue_free()
	
	var level_scene: PackedScene = load(LEVELS[current_level_number_])
	current_level_ = level_scene.instantiate()
	add_child(current_level_)
	
	player_.position = current_level_.player_spawn_point_.position
	dracula_.position = current_level_.dracula_spawn_point_.position
	
	current_level_.player_ = player_
	current_level_.dracula_ = dracula_
	current_level_.exit_door_.player_entered_door_.connect(current_level_.on_player_entered_door_)
	current_level_.exit_door_.player_exited_door_.connect(current_level_.on_player_exited_door_)
	current_level_.level_end_.connect(on_level_end_)
	current_level_.level_init_()
	dracula_.dracula_reset_()
	player_.player_reset_()
	current_level_.hud_.get_node("HealthBar").value = 100.0
	current_level_.hud_.get_node("DraculaHead1").visible = true
	current_level_.hud_.get_node("DraculaHead2").visible = true
	current_level_.hud_.get_node("DraculaHead3").visible = true
	current_level_.hud_.get_node("DraculaHead4").visible = true
	current_level_.hud_.get_node("DraculaHead5").visible = true
	current_level_.cycles_ = 0
	player_.visible = true
	dracula_.visible = true


func on_level_end_():
	player_.visible = false
	dracula_.visible = false
	change_level_(current_level_number_ + 1)


func on_game_over_():
	dracula_.dracula_reset_()
	player_.player_reset_()
	change_level_(current_level_number_)
