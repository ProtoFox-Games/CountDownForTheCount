class_name PlayerStateMachine extends Node

enum PlayerState {
	IDLE,
	WALK,
	JUMP,
}

var player: CharacterBody2D = null

func _init(player_in: CharacterBody2D) -> void:
	player = player_in

func enter_state(state: PlayerState) -> void:
	match state:
		PlayerState.IDLE:
			var anim: AnimatedSprite2D = player.get_node("AnimatedSprite2D")
			anim.animation = "idle_right"
			anim.play()

func exit_state(state: PlayerState) -> void:
	pass
	

func PlayerStateMachine_process(delta: float) -> void:
	pass
	
func change_state(state: PlayerState) -> void:
	pass
	
