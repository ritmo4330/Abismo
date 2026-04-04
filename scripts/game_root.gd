extends Node2D

const FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const FIRST_SPAWN_POINT: String = "InitialSpawn"

func _ready() -> void:
	SceneManager.initialize(self, FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)

	EventBus.dialogue_requested.connect(_on_dialogue_requested)

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_ended):
		Dialogic.timeline_ended.connect(_on_dialogue_ended)


func _on_dialogue_requested(dialogue_id: String) -> void:
	if dialogue_id.is_empty():
		return
	if Dialogic.current_timeline != null:
		return

	get_tree().paused = true
	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS

	var layout: Node = Dialogic.start(dialogue_id)
	if layout != null:
		layout.process_mode = Node.PROCESS_MODE_ALWAYS


func _on_dialogue_ended() -> void:
	# 避免在场景过渡期间提前解除暂停
	if SceneManager.is_transitioning:
		return
	get_tree().paused = false
