extends Node2D

@export var room_id: String = "demo_logo"
@export var default_spawn_point: String = "InitialSpawn"
@export var logo_duration: float = 2.0

var _started: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	call_deferred("_start_logo_sequence")


func _start_logo_sequence() -> void:
	if _started:
		return
	_started = true
	await get_tree().create_timer(max(0.1, logo_duration)).timeout
	if FlowManager == null:
		return
	FlowManager.set_step(FlowManager.STEP_DEMO_STUDY_WAKE)
	FlowManager.request_scene_change(
		FlowManager.DEMO_STUDY_SCENE_PATH,
		"SpawnFromZouLang",
		FlowManager.TIMELINE_DEMO_STUDY_WAKE
	)
