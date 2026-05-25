class_name Door
extends Interactable

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var flow_signal_name: String = ""
@export var open_sfx_id: String = "door_open"


func interact(_player: Player) -> void:
	if not flow_signal_name.is_empty():
		EventBus.flow_signal_requested.emit(flow_signal_name)
		return

	if target_scene_path.is_empty():
		push_error("Door target_scene_path is empty.")
		return

	_play_open_sfx()
	EventBus.scene_change_requested.emit(target_scene_path, target_spawn_point)


func _play_open_sfx() -> void:
	if open_sfx_id.is_empty():
		return
	if AudioManager == null:
		return
	if not AudioManager.has_method("play_sfx"):
		return
	AudioManager.play_sfx(open_sfx_id)
