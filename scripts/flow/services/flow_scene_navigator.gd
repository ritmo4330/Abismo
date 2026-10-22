extends RefCounted

var pending_auto_timeline: String = ""
var pending_standalone_spawn_point: String = ""

var _owner: Node = null
var _is_standalone_debug_flow_active: bool = false
var _is_standalone_scene_transitioning: bool = false
var _queued_scene_changes: Array[Dictionary] = []
var _flushing_scene_changes: bool = false


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

	if not ResourceLoader.exists(target_scene_path, "PackedScene"):
		push_error("FlowManager: scene change target cannot be loaded: %s" % target_scene_path)
		return false

	if SceneManager != null and SceneManager.has_method("is_initialized") and not SceneManager.is_initialized():
		if _is_standalone_scene_transitioning:
			push_warning("FlowManager: standalone scene change ignored because a transition is already running: %s" % target_scene_path)
			return false
		_start_standalone_scene_change(target_scene_path, spawn_point, auto_timeline)
		return true

	if SceneManager != null and SceneManager.is_transitioning:
		var request := {"path": target_scene_path, "spawn": spawn_point, "timeline": auto_timeline}
		if not _queued_scene_changes.has(request):
			_queued_scene_changes.append(request)
		if not _flushing_scene_changes:
			call_deferred("_flush_scene_changes")
		return true

	pending_auto_timeline = auto_timeline
	EventBus.scene_change_requested.emit(target_scene_path, spawn_point)
	return true


func clear_queued_scene_changes() -> void:
	_queued_scene_changes.clear()


func _flush_scene_changes() -> void:
	if _flushing_scene_changes or _owner == null:
		return
	_flushing_scene_changes = true
	while not _queued_scene_changes.is_empty() and is_instance_valid(_owner):
		await _owner.get_tree().process_frame
		if SceneManager.is_transitioning:
			continue
		if not SceneManager.is_initialized():
			_queued_scene_changes.clear()
			break
		var request: Dictionary = _queued_scene_changes.pop_front()
		request_scene_change(String(request.path), String(request.spawn), String(request.timeline))
	_flushing_scene_changes = false


func play_pending_auto_timeline() -> void:
	if pending_auto_timeline.is_empty():
		return
	# A deferred callback from the previous room may run during the next fade.
	# Keep the request until the new room is presented; DialogueManager rejects
	# requests during transitions, so consuming it here would strand the story.
	if SceneManager.is_transitioning or Dialogic.current_timeline != null:
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
