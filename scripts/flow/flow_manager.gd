extends Node

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEffectExecutor = preload("res://scripts/flow/flow_effect_executor.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")
const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")
const FlowState = preload("res://scripts/flow/flow_state.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")

const FlowDebugBootstrap = preload("res://scripts/flow/services/flow_debug_bootstrap.gd")
const FlowDialogicBridge = preload("res://scripts/flow/services/flow_dialogic_bridge.gd")
const FlowNpcPlacementState = preload("res://scripts/flow/services/flow_npc_placement_state.gd")
const FlowProgressRules = preload("res://scripts/flow/services/flow_progress_rules.gd")
const FlowRegistry = preload("res://scripts/flow/flow_registry.gd")
const FlowRoomActorSpawner = preload("res://scripts/flow/services/flow_room_actor_spawner.gd")
const FlowSceneNavigator = preload("res://scripts/flow/services/flow_scene_navigator.gd")

var _pending_after_dialogue_effects: Array[RefCounted] = []
var _current_room: Node2D = null

var _state: RefCounted = FlowState.new()
var _debug_bootstrap: RefCounted = FlowDebugBootstrap.new()
var _dialogic_bridge: RefCounted = FlowDialogicBridge.new()
var _effect_executor: RefCounted = FlowEffectExecutor.new()
var _npc_state: RefCounted = FlowNpcPlacementState.new()
var _progress_rules: RefCounted = FlowProgressRules.new()
var _registry: RefCounted = FlowRegistry.new()
var _room_actor_spawner: RefCounted = FlowRoomActorSpawner.new()
var _scene_navigator: RefCounted = FlowSceneNavigator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_effect_executor.setup(self)
	_scene_navigator.setup(self)
	_reset_npc_locations_for_current_step()

	if not EventBus.flow_signal_requested.is_connected(_on_flow_signal_requested):
		EventBus.flow_signal_requested.connect(_on_flow_signal_requested)
	if not EventBus.room_loaded.is_connected(_on_room_loaded):
		EventBus.room_loaded.connect(_on_room_loaded)
	if not EventBus.room_presented.is_connected(_on_room_presented):
		EventBus.room_presented.connect(_on_room_presented)
	if not EventBus.dialogue_finished.is_connected(_on_dialogue_finished):
		EventBus.dialogue_finished.connect(_on_dialogue_finished)
	if DataManager != null and not DataManager.clue_updated.is_connected(_on_clue_updated):
		DataManager.clue_updated.connect(_on_clue_updated)


func start_flow(chapter_id: String, entry_id: String) -> void:
	if chapter_id.is_empty() or entry_id.is_empty():
		return
	_handle_flow_transition("entry:%s/%s" % [chapter_id, entry_id], _registry.get_entry_transition(chapter_id, entry_id))


func send_flow_event(event_id: String) -> void:
	if event_id.is_empty():
		return
	_handle_flow_transition(event_id, _registry.handle_event(event_id, _state))


func apply_flow_state(
	chapter_id: String,
	step_id: String,
	room_id: String = "",
	private_chat_target: String = ""
) -> void:
	if chapter_id.is_empty() or step_id.is_empty():
		return
	_state.apply(chapter_id, step_id, room_id, private_chat_target)
	_reset_npc_locations_for_current_step()
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_initial_search_finished()


func advance_to_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	_state.step_id = step_id
	_reset_npc_locations_for_current_step()
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_initial_search_finished()


func get_state() -> RefCounted:
	return _state


func get_current_chapter_id() -> String:
	return _state.chapter_id


func get_current_step_id() -> String:
	return _state.step_id


func get_current_room_id() -> String:
	return _state.room_id


func get_private_chat_target() -> String:
	return _state.private_chat_target


func is_debug_flow_active() -> bool:
	return _scene_navigator.is_standalone_debug_flow_active()


func start_debug_standalone_room(config: Dictionary) -> void:
	var state: Dictionary = _debug_bootstrap.prepare_debug_standalone_room(config, _dialogic_bridge, _npc_state, _registry)
	if state.is_empty():
		return

	var next_state: Variant = state.get("flow_state", null)
	if next_state is RefCounted:
		_state = next_state as RefCounted
	else:
		_state.apply_dictionary(state)
	clear_pending_after_dialogue()
	set_pending_auto_timeline(String(state.get("pending_auto_timeline", "")))
	_scene_navigator.set_pending_standalone_spawn_point(String(state.get("pending_standalone_spawn_point", "")))
	_scene_navigator.mark_standalone_debug_flow_active()
	_refresh_initial_search_finished()
	_sync_bgm_for_step(get_current_step_id())


func can_open_manual_panels() -> bool:
	return _progress_rules.are_manual_panels_unlocked(
		get_current_chapter_id(),
		get_current_step_id(),
		_scene_navigator.is_standalone_debug_flow_active(),
		_get_current_definition()
	)


func set_npc_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String = "",
	scene_path: String = ""
) -> void:
	_npc_state.set_location(npc_id, room_id, spawn_name, timeline_name, scene_path)
	_refresh_current_room_actors()


func request_scene(target_scene_path: String, spawn_point: String, auto_timeline: String = "") -> bool:
	return _scene_navigator.request_scene_change(target_scene_path, spawn_point, auto_timeline)


func is_current_room_exit_blocked() -> bool:
	var result: RefCounted = _progress_rules.evaluate_room_exit(
		get_current_chapter_id(),
		get_current_step_id(),
		get_current_room_id()
	)
	if result.blocked and not result.dialogue_timeline.is_empty():
		EventBus.dialogue_requested.emit(result.dialogue_timeline)
	return result.blocked


func consume_debug_spawn_point(default_spawn_point: String) -> String:
	return _scene_navigator.consume_pending_standalone_spawn_point(default_spawn_point)


func clear_pending_after_dialogue() -> void:
	_pending_after_dialogue_effects.clear()


func set_pending_auto_timeline(timeline_name: String) -> void:
	_scene_navigator.set_pending_auto_timeline(timeline_name)


func stop_bgm() -> void:
	if AudioManager != null and AudioManager.has_method("stop_bgm"):
		AudioManager.stop_bgm()


func apply_character_name_state(name_state: String) -> void:
	_dialogic_bridge.apply_character_name_state(name_state)


func get_dialogic_var(path: String, default_value: Variant = null) -> Variant:
	return _dialogic_bridge.get_var(path, default_value)


func set_dialogic_var(path: String, value: Variant) -> void:
	_dialogic_bridge.set_var(path, value)


func set_private_chat_target(value: String) -> void:
	_state.private_chat_target = value


func enter_private_chat() -> void:
	if get_private_chat_target().is_empty():
		set_private_chat_target(String(get_dialogic_var(FlowDialogicVars.CH1_PRIVATE_CHAT_TARGET, "")))
	if get_private_chat_target().is_empty():
		push_warning("FlowManager: private chat target is empty.")
		return
	set_npc_location(get_private_chat_target(), FlowRooms.HUI_KE_TING, "Guest", "1_6_%s" % get_private_chat_target())
	request_scene(FlowScenes.HUI_KE_TING, "Detective", "1_6_%s" % get_private_chat_target())


func set_current_ch0_campfire_lit(is_lit: bool) -> void:
	var room: Node = _current_room
	if room == null and SceneManager != null:
		room = SceneManager.current_room
	if room != null and room.has_method("set_campfire_lit"):
		room.set_campfire_lit(is_lit)


func refresh_initial_search_finished() -> void:
	_refresh_initial_search_finished()


func on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	_room_actor_spawner.set_current_room(room)
	_state.room_id = room_id
	setup_room_actors(room)
	_setup_current_room_clues()
	_refresh_initial_search_finished()


func on_room_presented(_room: Node2D, room_id: String) -> void:
	if room_id != get_current_room_id():
		return
	call_deferred("play_pending_auto_timeline")


func play_pending_auto_timeline() -> void:
	_scene_navigator.play_pending_auto_timeline()


func setup_room_actors(room: Node2D) -> void:
	if room == null:
		return

	var definition: RefCounted = _get_current_definition()
	var spawn_entries: Array = _npc_state.get_spawn_entries_for_room(
		get_current_room_id(),
		definition,
		get_current_step_id(),
		get_private_chat_target()
	)
	var free_interaction_timelines: Dictionary = {}
	if definition != null:
		free_interaction_timelines = definition.free_interaction_timelines

	_room_actor_spawner.setup_room_actors(
		room,
		get_current_room_id(),
		spawn_entries,
		free_interaction_timelines
	)


func _on_clue_updated(_clue_id: String) -> void:
	_refresh_initial_search_finished()


func _get_current_definition() -> RefCounted:
	return _registry.get_definition(get_current_chapter_id())


func _reset_npc_locations_for_current_step() -> void:
	var definition: RefCounted = _get_current_definition()
	if definition == null:
		_npc_state.reset_for_step({})
		return
	_npc_state.reset_for_step(definition.get_base_npc_locations(get_current_step_id()))


func _sync_bgm_for_step(step_id: String) -> void:
	var definition: RefCounted = _get_current_definition()
	if definition == null:
		return
	var bgm_config: Dictionary = definition.get_bgm_config(step_id)
	if bgm_config.is_empty():
		return
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(
			String(bgm_config.get("track_id", "")),
			float(bgm_config.get("fade_seconds", 1.5))
		)


func _refresh_current_room_actors() -> void:
	if _current_room == null or get_current_room_id().is_empty():
		return
	setup_room_actors(_current_room)
	_setup_current_room_clues()


func _setup_current_room_clues() -> void:
	if _current_room == null or get_current_room_id().is_empty():
		return
	if CluePlacementManager == null or not CluePlacementManager.has_method("setup_room_clues"):
		return
	CluePlacementManager.setup_room_clues(_current_room, get_current_room_id())


func _refresh_initial_search_finished() -> void:
	var definition: RefCounted = _get_current_definition()
	if definition == null:
		return
	var result: Dictionary = _progress_rules.evaluate_initial_search_finished(
		get_current_step_id(),
		definition.initial_search_required_clues
	)
	if not bool(result.get("applies", false)):
		return

	var is_finished: bool = bool(result.get("finished", false))
	var missing_clue_ids: Array[String] = []
	for clue_id: Variant in result.get("missing_clue_ids", []):
		missing_clue_ids.append(String(clue_id))
	if bool(_dialogic_bridge.get_var(FlowDialogicVars.CH1_INITIAL_SEARCH_FINISHED, false)) == is_finished:
		if not is_finished:
			_progress_rules.log_initial_search_missing_clues(missing_clue_ids)
		return

	_dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_FINISHED, is_finished)
	if is_finished:
		_progress_rules.clear_initial_search_missing_log()
	else:
		_progress_rules.log_initial_search_missing_clues(missing_clue_ids)


func _handle_flow_transition(source_id: String, transition: RefCounted) -> void:
	if transition == null or not transition.handled:
		push_warning("FlowManager: unhandled flow transition '%s'." % source_id)
		return

	_effect_executor.execute_many(transition.immediate_effects)
	_pending_after_dialogue_effects.append_array(transition.after_dialogue_effects)


func _on_flow_signal_requested(event_id: String) -> void:
	send_flow_event(event_id)


func _on_room_loaded(room: Node2D, room_id: String) -> void:
	on_room_loaded(room, room_id)


func _on_room_presented(room: Node2D, room_id: String) -> void:
	on_room_presented(room, room_id)


func _on_dialogue_finished(_timeline_name: String) -> void:
	if _pending_after_dialogue_effects.is_empty():
		return

	var effects: Array = _pending_after_dialogue_effects.duplicate(true)
	_pending_after_dialogue_effects.clear()
	_effect_executor.execute_many(effects)
