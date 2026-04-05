extends Node2D

const FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const FIRST_SPAWN_POINT: String = "InitialSpawn"

func _ready() -> void:
	GameManager.enter_gameplay()
	SceneManager.initialize(self, FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	DialogueManager.bootstrap()
