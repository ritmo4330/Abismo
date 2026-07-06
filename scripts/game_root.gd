extends Node2D

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")

const CH0_PROLOGUE_FIRST_LEVEL_PATH: String = "res://scenes/ch0_prologue/ch0_black_screen.tscn"
const CH1_LEGACY_FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const FIRST_SPAWN_POINT: String = "InitialSpawn"

func _ready() -> void:
	GameManager.enter_gameplay()
	var boot_mode: String = GameManager.consume_next_boot_mode()
	if boot_mode == GameManager.BOOT_MODE_CH1_LEGACY:
		FlowManager.start_flow(FlowChapters.CH1, FlowEntries.CH1_LEGACY_HALL)
		SceneManager.initialize(self, CH1_LEGACY_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	else:
		FlowManager.start_flow(FlowChapters.CH0_PROLOGUE, FlowEntries.CH0_PROLOGUE_START)
		SceneManager.initialize(self, CH0_PROLOGUE_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	DialogueManager.bootstrap()
