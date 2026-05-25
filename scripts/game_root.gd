extends Node2D

const DEMO_FIRST_LEVEL_PATH: String = "res://scenes/demo/demo_black_screen.tscn"
const CH1_LEGACY_FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const FIRST_SPAWN_POINT: String = "InitialSpawn"

func _ready() -> void:
	GameManager.enter_gameplay()
	var boot_mode: String = GameManager.consume_next_boot_mode()
	if boot_mode == GameManager.BOOT_MODE_CH1_LEGACY:
		FlowManager.prepare_ch1_legacy_start()
		SceneManager.initialize(self, CH1_LEGACY_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	else:
		FlowManager.prepare_demo_start()
		SceneManager.initialize(self, DEMO_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	DialogueManager.bootstrap()
