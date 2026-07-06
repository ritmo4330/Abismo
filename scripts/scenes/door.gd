class_name Door
extends Interactable

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var flow_signal_name: String = ""
@export var required_flag: String = ""
@export var blocked_notice: String = ""
@export var open_sfx_id: String = "door_open"


func interact(_player: Player) -> void:
	if _should_block_room_exit():
		return

	if not required_flag.is_empty() and not DataManager.has_flag(required_flag):
		if not blocked_notice.is_empty() and ToastManager != null:
			ToastManager.show_notice(blocked_notice, "warning")
		return

	if not flow_signal_name.is_empty():
		EventBus.flow_signal_requested.emit(flow_signal_name)
		return

	if target_scene_path.is_empty():
		push_error("Door target_scene_path is empty.")
		return

	_play_open_sfx()
	if _request_standalone_scene_change():
		return
	EventBus.scene_change_requested.emit(target_scene_path, target_spawn_point)


func _play_open_sfx() -> void:
	if open_sfx_id.is_empty():
		return
	if AudioManager == null:
		return
	if not AudioManager.has_method("play_sfx"):
		return
	AudioManager.play_sfx(open_sfx_id)


func _should_block_room_exit() -> bool:
	if FlowManager == null:
		return false
	return FlowManager.is_current_room_exit_blocked()


func _request_standalone_scene_change() -> bool:
	if FlowManager == null:
		return false
	if SceneManager == null or not SceneManager.has_method("is_initialized"):
		return false
	if SceneManager.is_initialized():
		return false
	return FlowManager.request_scene(target_scene_path, target_spawn_point)
