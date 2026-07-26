extends Node

const PLAYER_SCALE: float = 5.0
const DRACULA_SCALE: float = 1.5

const LEVELS: Array = [
	"res://levels/tutorial.tscn"
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
	
	dracula_.position = current_level_.dracula_spawn_point_.position
	dracula_.scale *= DRACULA_SCALE
	dracula_.player_ = player_
	dracula_.player_.player_interact_.connect(dracula_.on_melee_damage_)
	
	current_level_.player_ = player_
	current_level_.dracula_ = dracula_
	current_level_.exit_door_.player_entered_door_.connect(current_level_.on_player_entered_door_)
	current_level_.exit_door_.player_exited_door_.connect(current_level_.on_player_exited_door_)
	current_level_.level_end_.connect(on_level_end_)


func change_level_():
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
	player_.visible = true
	dracula_.visible = true


func on_level_end_():
	print("level ended signal received")
	player_.visible = false
	dracula_.visible = false
	#change_level_()
