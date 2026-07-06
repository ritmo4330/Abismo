extends RefCounted

var pending_auto_timeline: String = ""
var pending_standalone_spawn_point: String = ""

var _owner: Node = null
var _is_standalone_debug_flow_active: bool = false
var _is_standalone_scene_transitioning: bool = false


func setup(owner: Node) -> void:
	_owner = owner


func is_standalone_debug_flow_active() -> bool:
	return _is_standalone_debug_flow_active


func mark_standalone_debug_flow_active() -> void:
	_is_standalone_debug_flow_active = true


func set_pending_auto_timeline(timeline_name: String) -> void:
	pending_auto_timeline = timeline_name


func set_pending_standalone_spawn_point(spawn_point: String) -> void:
	pending_standalone_spawn_point = spawn_point


func request_scene_change(target_scene_path: String, spawn_point: String, auto_timeline: String = "") -> bool:
	if target_scene_path.is_empty():
		pending_auto_timeline = auto_timeline
		play_pending_auto_timeline()
		return true

	var target_scene: PackedScene = load(target_scene_path) as PackedScene
	if target_scene == null:
		push_error("FlowManager: scene change target cannot be loaded: %s" % target_scene_path)
		return false

	if SceneManager != null and SceneManager.has_method("is_initialized") and not SceneManager.is_initialized():
		if _is_standalone_scene_transitioning:
			push_warning("FlowManager: standalone scene change ignored because a transition is already running: %s" % target_scene_path)
			return false
		_start_standalone_scene_change(target_scene_path, spawn_point, auto_timeline)
		return true

	if SceneManager != null and SceneManager.is_transitioning:
		push_warning("FlowManager: scene change ignored because SceneManager is already transitioning: %s" % target_scene_path)
		return false

	pending_auto_timeline = auto_timeline
	EventBus.scene_change_requested.emit(target_scene_path, spawn_point)
	return true


func play_pending_auto_timeline() -> void:
	if pending_auto_timeline.is_empty():
		return
	var timeline_name: String = pending_auto_timeline
	pending_auto_timeline = ""
	EventBus.dialogue_requested.emit(timeline_name)


func consume_pending_standalone_spawn_point(default_spawn_point: String) -> String:
	if pending_standalone_spawn_point.is_empty():
		return default_spawn_point
	var spawn_point: String = pending_standalone_spawn_point
	pending_standalone_spawn_point = ""
	return spawn_point


func _start_standalone_scene_change(target_scene_path: String, spawn_point: String, auto_timeline: String) -> void:
	_is_standalone_debug_flow_active = true
	_is_standalone_scene_transitioning = true
	pending_auto_timeline = auto_timeline
	pending_standalone_spawn_point = spawn_point
	call_deferred("_run_standalone_scene_change", target_scene_path)


func _run_standalone_scene_change(target_scene_path: String) -> void:
	if _owner == null:
		_is_standalone_scene_transitioning = false
		return

	if Transition != null and Transition.has_method("fade_out"):
		await Transition.fade_out()

	var error: Error = _owner.get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("FlowManager: standalone scene change failed: %s" % target_scene_path)
		_is_standalone_scene_transitioning = false
		return

	await _owner.get_tree().process_frame
	await _owner.get_tree().process_frame

	if Transition != null and Transition.has_method("fade_in"):
		await Transition.fade_in()

	_is_standalone_scene_transitioning = false
