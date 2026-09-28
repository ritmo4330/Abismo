extends Node

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEffectExecutor = preload("res://scripts/flow/flow_effect_executor.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")
const FlowEvents = preload("res://scripts/flow/flow_events.gd")
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
	if DataManager != null and not DataManager.suspicion_updated.is_connected(_on_suspicion_updated):
		DataManager.suspicion_updated.connect(_on_suspicion_updated)


func reset_gameplay_runtime() -> void:
	clear_pending_after_dialogue()
	set_pending_auto_timeline("")
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()
	if Dialogic != null and Dialogic.VAR != null:
		Dialogic.VAR.reset()
	if Dialogic != null and Dialogic.has_subsystem("History"):
		Dialogic.History.reset_visited_history()


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
	_sync_dialogic_stage_gates()
	_reset_npc_locations_for_current_step()
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_initial_search_finished()
	_refresh_second_search_finished()
	_refresh_third_search_finished()


func advance_to_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	_state.step_id = step_id
	_sync_dialogic_stage_gates()
	_reset_npc_locations_for_current_step()
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_initial_search_finished()
	_refresh_second_search_finished()
	_refresh_third_search_finished()


func get_state() -> RefCounted:
	return _state


func save_runtime_state() -> Dictionary:
	return {
		"flow_state": _state.to_dict(),
		"npc_locations": _npc_state.to_dict(),
	}


func load_runtime_state(data: Dictionary) -> void:
	clear_pending_after_dialogue()
	set_pending_auto_timeline("")
	_current_room = null

	var flow_state_value: Variant = data.get("flow_state", data)
	if flow_state_value is Dictionary:
		_state.apply_dictionary(flow_state_value as Dictionary)

	var npc_locations_value: Variant = data.get("npc_locations", null)
	if npc_locations_value is Dictionary:
		_npc_state.from_dict(npc_locations_value as Dictionary)
	else:
		_reset_npc_locations_for_current_step()
	_normalize_loaded_npc_locations()

	_sync_bgm_for_step(get_current_step_id())
	_sync_dialogic_stage_gates()
	refresh_derived_progress()


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
	_refresh_second_search_finished()
	_refresh_third_search_finished()
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
	if value.is_empty():
		_refresh_current_content_completion()
		_reset_npc_locations_for_current_step()
		_refresh_current_room_actors()


func enter_private_chat() -> void:
	if get_private_chat_target().is_empty():
		set_private_chat_target(String(get_dialogic_var(FlowDialogicVars.CH1_PRIVATE_CHAT_TARGET, "")))
	if get_private_chat_target().is_empty():
		push_warning("FlowManager: private chat target is empty.")
		return
	var timeline_prefix: String = "1_6_"
	if get_current_step_id() == FlowSteps.CH2_SECOND_PRIVATE_CHAT:
		timeline_prefix = "2_2_"
	elif get_current_step_id() == FlowSteps.CH2_THIRD_PRIVATE_CHAT:
		timeline_prefix = "2_5_"
	var timeline_name: String = "%s%s" % [timeline_prefix, get_private_chat_target()]
	set_npc_location(get_private_chat_target(), FlowRooms.HUI_KE_TING, "Guest", timeline_name)
	request_scene(FlowScenes.HUI_KE_TING, "Detective", timeline_name)


func set_current_ch0_campfire_lit(is_lit: bool) -> void:
	var room: Node = _current_room
	if room == null and SceneManager != null:
		room = SceneManager.current_room
	if room != null and room.has_method("set_campfire_lit"):
		room.set_campfire_lit(is_lit)


func refresh_initial_search_finished() -> void:
	_refresh_initial_search_finished()


func refresh_derived_progress() -> void:
	_sync_dialogic_stage_gates()
	_refresh_initial_search_finished()
	_refresh_second_search_finished()
	_refresh_third_search_finished()
	_reconcile_milestone_suspicions()
	_refresh_nightmare_resolution_flags()
	_refresh_current_content_completion()


func developer_skip_current_reasoning() -> bool:
	match get_current_step_id():
		FlowSteps.CH1_INITIAL_REASONING:
			for clue_id: String in ["1_testimony_2_butler", "1_testimony_3_all", "1_testimony_4_all", "1_testimony_5_all", "1_testimony_6_lin"]:
				DataManager.add_clue(clue_id, "developer_skip", FlowSteps.CH1_INITIAL_REASONING)
			for suspicion_id: String in [
				"1_suspicion_crime_time", "1_suspicion_motive", "1_suspicion_ability",
				"1_suspicion_locked_room", "1_suspicion_missing_weapon", "1_suspicion_meta_in_lin_room",
				"1_suspicion_butler_request",
				"1_suspicion_butler_request_mu", "1_suspicion_butler_request_zhou",
				"1_suspicion_butler_request_lin", "1_suspicion_butler_request_wu",
				"1_suspicion_butler_request_zhong",
			]:
				DataManager.add_suspicion(suspicion_id, "developer_skip", FlowSteps.CH1_INITIAL_REASONING)
			set_dialogic_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, true)
			send_flow_event(FlowEvents.ENABLE_PRIVATE_CHAT)
			return true
		FlowSteps.CH2_SECOND_REASONING:
			DataManager.add_suspicion("2_suspicion_dream_space", "developer_skip", FlowSteps.CH2_SECOND_REASONING)
			DataManager.add_suspicion("2_suspicion_parallel_worlds", "developer_skip", FlowSteps.CH2_SECOND_REASONING)
			set_dialogic_var("Ch2.SecondPrivate.Enabled", true)
			send_flow_event(FlowEvents.ENABLE_SECOND_PRIVATE_CHAT)
			return true
		FlowSteps.CH2_THIRD_REASONING:
			set_dialogic_var("Ch2.ThirdPrivate.Enabled", true)
			send_flow_event(FlowEvents.ENABLE_THIRD_PRIVATE_CHAT)
			return true
	return false


func on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	_room_actor_spawner.set_current_room(room)
	_state.room_id = room_id
	setup_room_actors(room)
	_setup_current_room_clues()
	_refresh_initial_search_finished()
	_refresh_second_search_finished()
	_refresh_third_search_finished()


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


func _on_clue_updated(clue_id: String) -> void:
	_refresh_initial_search_finished()
	_refresh_second_search_finished()
	_refresh_third_search_finished()
	if clue_id == "2_missing_body" and DataManager != null:
		DataManager.add_suspicion("1_suspicion_missing_body", "clue", clue_id)


func _on_suspicion_updated(_suspicion_id: String) -> void:
	_refresh_nightmare_resolution_flags()


func _reconcile_milestone_suspicions() -> void:
	if DataManager == null:
		return
	# Save files created before the milestone hooks were added may already contain
	# the clue/step. Restore only facts the player must have encountered to reach
	# that state; optional conversation suspicions remain choice-dependent.
	if DataManager.has_clue("2_missing_body"):
		DataManager.add_suspicion("1_suspicion_missing_body", "save_reconcile", "2_missing_body")

	if get_current_chapter_id() != FlowChapters.CH2:
		return
	if get_current_step_id() in [
		FlowSteps.CH2_SECOND_PRIVATE_CHAT,
		FlowSteps.CH2_THIRD_SEARCH,
		FlowSteps.CH2_THIRD_REASONING,
		FlowSteps.CH2_THIRD_PRIVATE_CHAT,
		FlowSteps.CH2_MEMORY_FRAGMENTS,
	]:
		DataManager.add_suspicion("2_suspicion_dream_space", "save_reconcile", FlowSteps.CH2_SECOND_REASONING)
		DataManager.add_suspicion("2_suspicion_parallel_worlds", "save_reconcile", FlowSteps.CH2_SECOND_REASONING)


func _get_current_definition() -> RefCounted:
	return _registry.get_definition(get_current_chapter_id())


func _sync_dialogic_stage_gates() -> void:
	if get_current_chapter_id() != FlowChapters.CH1:
		return
	match get_current_step_id():
		FlowSteps.CH1_INTRO_HALL:
			_dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, false)
			_dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, false)
		FlowSteps.CH1_FIRST_SEARCH, FlowSteps.CH1_INITIAL_REASONING:
			_dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, true)
			_dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, false)
		FlowSteps.CH1_PRIVATE_CHAT, FlowSteps.CH1_SECOND_SEARCH:
			_dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, true)


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
		if ToastManager != null:
			ToastManager.show_notice("二楼搜证完成：请与管家交谈", "task", 3.5)
	else:
		_progress_rules.log_initial_search_missing_clues(missing_clue_ids)


func _normalize_loaded_npc_locations() -> void:
	if get_current_chapter_id() != FlowChapters.CH1:
		return
	if get_current_step_id() != FlowSteps.CH1_FIRST_SEARCH:
		return
	_npc_state.set_location(FlowNpcs.BUTLER, FlowRooms.FLOOR2, "Butler")


func _refresh_second_search_finished() -> void:
	var definition: RefCounted = _get_current_definition()
	if definition == null:
		return
	var result: Dictionary = _progress_rules.evaluate_second_search_finished(
		get_current_step_id(),
		definition.second_search_required_clues
	)
	if not bool(result.get("applies", false)):
		return

	var is_finished: bool = bool(result.get("finished", false))
	var missing_clue_ids: Array[String] = []
	for clue_id: Variant in result.get("missing_clue_ids", []):
		missing_clue_ids.append(String(clue_id))
	if bool(_dialogic_bridge.get_var(FlowDialogicVars.CH1_SECOND_SEARCH_FINISHED, false)) == is_finished:
		if not is_finished:
			_progress_rules.log_second_search_missing_clues(missing_clue_ids)
		return

	_dialogic_bridge.set_var(FlowDialogicVars.CH1_SECOND_SEARCH_FINISHED, is_finished)
	if is_finished:
		_progress_rules.clear_second_search_missing_log()
		if ToastManager != null:
			ToastManager.show_notice("钟岳研究所调查完成", "task", 2.5)
	else:
		_progress_rules.log_second_search_missing_clues(missing_clue_ids)


func _refresh_third_search_finished() -> void:
	var definition: RefCounted = _get_current_definition()
	if definition == null:
		return
	var result: Dictionary = _progress_rules.evaluate_third_search_finished(
		get_current_step_id(), definition.third_search_required_clues
	)
	if not bool(result.get("applies", false)):
		return
	var is_finished: bool = bool(result.get("finished", false))
	var missing_clue_ids: Array[String] = []
	for clue_id: Variant in result.get("missing_clue_ids", []):
		missing_clue_ids.append(String(clue_id))
	if bool(_dialogic_bridge.get_var(FlowDialogicVars.CH2_THIRD_SEARCH_FINISHED, false)) == is_finished:
		if not is_finished:
			_progress_rules.log_third_search_missing_clues(missing_clue_ids)
		return
	_dialogic_bridge.set_var(FlowDialogicVars.CH2_THIRD_SEARCH_FINISHED, is_finished)
	if is_finished:
		_progress_rules.clear_third_search_missing_log()
		if ToastManager != null:
			ToastManager.show_notice("发现关键变化：尸体消失了", "clue", 3.5)
	else:
		_progress_rules.log_third_search_missing_clues(missing_clue_ids)


func _refresh_nightmare_resolution_flags() -> void:
	if DataManager == null:
		return
	var mappings: Dictionary = {
		"1_suspicion_butler_request_mu": "Ch1.PrivateChat.Mu.NightmareSolved",
		"1_suspicion_butler_request_zhou": "Ch1.PrivateChat.Zhou.NightmareSolved",
		"1_suspicion_butler_request_lin": "Ch1.PrivateChat.Lin.NightmareSolved",
		"1_suspicion_butler_request_wu": "Ch1.PrivateChat.Wu.NightmareSolved",
		"1_suspicion_butler_request_zhong": "Ch1.PrivateChat.Zhong.NightmareSolved",
	}
	for suspicion_id: String in mappings:
		if DataManager.is_suspicion_resolved(suspicion_id):
			_dialogic_bridge.set_var(String(mappings[suspicion_id]), true)


func _refresh_current_content_completion() -> void:
	if get_current_chapter_id() != FlowChapters.CH2:
		return
	if get_current_step_id() != FlowSteps.CH2_THIRD_PRIVATE_CHAT:
		return
	var all_finished: bool = true
	for npc_id: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
		if not bool(_dialogic_bridge.get_var("Ch2.ThirdPrivate.%s.Finished" % npc_id, false)):
			all_finished = false
			break
	_dialogic_bridge.set_var(
		FlowDialogicVars.CH2_CURRENT_CONTENT_COMPLETE_READY,
		all_finished
	)


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
