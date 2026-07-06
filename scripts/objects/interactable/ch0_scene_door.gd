class_name Ch0SceneDoor
extends Interactable

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = "InitialSpawn"
@export var auto_timeline: String = ""
@export var next_step_id: String = ""
@export var interact_timeline: String = ""
@export var required_flag: String = ""
@export var blocked_notice: String = ""
@export var open_sfx_id: String = "door_open"

var _is_transitioning: bool = false


func interact(_player: Player) -> void:
	if _is_transitioning:
		return
	if not required_flag.is_empty() and not DataManager.get_world_flag(required_flag):
		if not blocked_notice.is_empty() and ToastManager != null:
			ToastManager.show_notice(blocked_notice, "warning")
		return
	if not interact_timeline.is_empty():
		_is_transitioning = true
		EventBus.dialogue_requested.emit(interact_timeline)
		return
	if target_scene_path.is_empty():
		push_error("Ch0SceneDoor target_scene_path is empty.")
		return

	var accepted: bool = FlowManager.request_scene(target_scene_path, target_spawn_point, auto_timeline)
	if not accepted:
		return

	_play_open_sfx()
	_is_transitioning = true
	if ToastManager != null:
		ToastManager.show_notice("大门打开了。", "info", 1.5)
	if not next_step_id.is_empty():
		FlowManager.advance_to_step(next_step_id)


func _play_open_sfx() -> void:
	if open_sfx_id.is_empty():
		return
	if AudioManager == null:
		return
	if not AudioManager.has_method("play_sfx"):
		return
	AudioManager.play_sfx(open_sfx_id)
