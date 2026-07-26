class_name Tutorial extends Level


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("tutorial ready")
	player_spawn_point_ = $PlayerSpawnPoint
	dracula_spawn_point_ = $DraculaSpawnPoint
	blood_source_ = $BloodSource
	exit_door_ = $ExitDoor


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	super._process(delta)
