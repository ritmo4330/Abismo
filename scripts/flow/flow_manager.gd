extends Node

const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const Ch0FlowConfig = preload("res://scripts/flow/configs/ch0_flow_config.gd")
const Ch1FlowConfig = preload("res://scripts/flow/configs/ch1_flow_config.gd")
const FlowDebugBootstrap = preload("res://scripts/flow/services/flow_debug_bootstrap.gd")
const FlowDialogicBridge = preload("res://scripts/flow/services/flow_dialogic_bridge.gd")
const FlowNpcPlacement = preload("res://scripts/flow/services/flow_npc_placement.gd")
const FlowProgressRules = preload("res://scripts/flow/services/flow_progress_rules.gd")
const FlowSceneNavigator = preload("res://scripts/flow/services/flow_scene_navigator.gd")
const FlowCommandExecutor = preload("res://scripts/flow/flow_command_executor.gd")
const FlowRegistry = preload("res://scripts/flow/flow_registry.gd")
const FlowState = preload("res://scripts/flow/flow_state.gd")

const CHAPTER_CH0_PROLOGUE: String = FlowIds.CHAPTER_CH0_PROLOGUE
const CHAPTER_CH1: String = FlowIds.CHAPTER_CH1

const STEP_CH0_IDENTITY: String = FlowIds.STEP_CH0_IDENTITY
const STEP_CH0_PROLOGUE_STORY: String = FlowIds.STEP_CH0_PROLOGUE_STORY
const STEP_CH0_SNOW_CAMP: String = FlowIds.STEP_CH0_SNOW_CAMP
const STEP_CH0_SNOW_PATH: String = FlowIds.STEP_CH0_SNOW_PATH
const STEP_CH0_VILLA_GATE: String = FlowIds.STEP_CH0_VILLA_GATE
const STEP_CH0_HALL_ARRIVAL: String = FlowIds.STEP_CH0_HALL_ARRIVAL
const STEP_CH0_LOGO: String = FlowIds.STEP_CH0_LOGO

const STEP_CH1_STUDY_WAKE: String = FlowIds.STEP_CH1_STUDY_WAKE
const STEP_CH1_STUDY_FREE_INVESTIGATION: String = FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION
const STEP_CH1_PUZZLE: String = FlowIds.STEP_CH1_PUZZLE
const STEP_CH1_MURDER_REQUEST: String = FlowIds.STEP_CH1_MURDER_REQUEST
const STEP_CH1_CRIME_SCENE: String = FlowIds.STEP_CH1_CRIME_SCENE
const STEP_CH1_BODY_CG: String = FlowIds.STEP_CH1_BODY_CG
const STEP_CH1_INTRO_HALL: String = FlowIds.STEP_CH1_INTRO_HALL
const STEP_CH1_FIRST_SEARCH: String = FlowIds.STEP_CH1_FIRST_SEARCH
const STEP_CH1_INITIAL_REASONING: String = FlowIds.STEP_CH1_INITIAL_REASONING
const STEP_CH1_PRIVATE_CHAT: String = FlowIds.STEP_CH1_PRIVATE_CHAT
const STEP_CH1_SECOND_SEARCH: String = FlowIds.STEP_CH1_SECOND_SEARCH

const ROOM_HALL: String = FlowIds.ROOM_HALL
const ROOM_FLOOR2: String = FlowIds.ROOM_FLOOR2
const ROOM_ZOU_LANG: String = FlowIds.ROOM_ZOU_LANG
const ROOM_CAN_TING: String = FlowIds.ROOM_CAN_TING
const ROOM_HUI_KE_TING: String = FlowIds.ROOM_HUI_KE_TING
const ROOM_FIRST_SEARCH: String = FlowIds.ROOM_FIRST_SEARCH
const ROOM_META: String = FlowIds.ROOM_META
const ROOM_MU_ZHI: String = FlowIds.ROOM_MU_ZHI
const ROOM_WU_TING_XIANG: String = FlowIds.ROOM_WU_TING_XIANG
const ROOM_ZHONG_QI: String = FlowIds.ROOM_ZHONG_QI
const ROOM_ZHOU_CHONG_AN: String = FlowIds.ROOM_ZHOU_CHONG_AN
const ROOM_SECOND_SEARCH: String = FlowIds.ROOM_SECOND_SEARCH
const ROOM_CH1_STUDY: String = FlowIds.ROOM_CH1_STUDY
const ROOM_CH1_CRIME_SCENE: String = FlowIds.ROOM_CH1_CRIME_SCENE

const HALL_SCENE_PATH: String = FlowIds.HALL_SCENE_PATH
const CH0_BLACK_SCREEN_SCENE_PATH: String = FlowIds.CH0_BLACK_SCREEN_SCENE_PATH
const CH0_SNOW_FIELD_SCENE_PATH: String = FlowIds.CH0_SNOW_FIELD_SCENE_PATH
const CH0_LOGO_SCENE_PATH: String = FlowIds.CH0_LOGO_SCENE_PATH
const CH1_STUDY_SCENE_PATH: String = FlowIds.CH1_STUDY_SCENE_PATH
const CH1_CRIME_SCENE_PATH: String = FlowIds.CH1_CRIME_SCENE_PATH
const CH1_BODY_CG_SCENE_PATH: String = FlowIds.CH1_BODY_CG_SCENE_PATH
const HUI_KE_TING_SCENE_PATH: String = FlowIds.HUI_KE_TING_SCENE_PATH
const FIRST_SEARCH_ROOM1_PATH: String = FlowIds.FIRST_SEARCH_ROOM1_PATH
const FIRST_SEARCH_ROOM2_PATH: String = FlowIds.FIRST_SEARCH_ROOM2_PATH
const SECOND_SEARCH_ROOM_PATH: String = FlowIds.SECOND_SEARCH_ROOM_PATH
const NPC_SCENE_PATH: String = FlowIds.NPC_SCENE_PATH

const ACTION_START_INITIAL_SEARCH: String = FlowIds.ACTION_START_INITIAL_SEARCH
const ACTION_ENTER_ROOM_LIN: String = FlowIds.ACTION_ENTER_ROOM_LIN
const ACTION_START_INITIAL_REASONING: String = FlowIds.ACTION_START_INITIAL_REASONING
const ACTION_ENTER_PRIVATE_CHAT: String = FlowIds.ACTION_ENTER_PRIVATE_CHAT
const ACTION_EXIT_PRIVATE_CHAT: String = FlowIds.ACTION_EXIT_PRIVATE_CHAT
const ACTION_START_SECOND_SEARCH: String = FlowIds.ACTION_START_SECOND_SEARCH
const ACTION_EXIT_SECOND_SEARCH: String = FlowIds.ACTION_EXIT_SECOND_SEARCH
const ACTION_START_LIGHTHOUSE_REASONING: String = FlowIds.ACTION_START_LIGHTHOUSE_REASONING
const ACTION_CH0_IDENTITY_FINISHED: String = FlowIds.ACTION_CH0_IDENTITY_FINISHED
const ACTION_CH0_PROLOGUE_INTRO_FINISHED: String = FlowIds.ACTION_CH0_PROLOGUE_INTRO_FINISHED
const ACTION_CH0_CAMPFIRE_EXTINGUISHED: String = FlowIds.ACTION_CH0_CAMPFIRE_EXTINGUISHED
const ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED: String = FlowIds.ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED
const ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED: String = FlowIds.ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED
const ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED: String = FlowIds.ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED
const ACTION_CH0_HALL_MEMORY_START: String = FlowIds.ACTION_CH0_HALL_MEMORY_START
const ACTION_CH0_HALL_ARRIVAL_FINISHED: String = FlowIds.ACTION_CH0_HALL_ARRIVAL_FINISHED
const ACTION_CH1_STUDY_WAKE_FINISHED: String = FlowIds.ACTION_CH1_STUDY_WAKE_FINISHED
const ACTION_CH1_STUDY_BUTLER_ENTER: String = FlowIds.ACTION_CH1_STUDY_BUTLER_ENTER
const ACTION_CH1_STUDY_BUTLER_LEAVE: String = FlowIds.ACTION_CH1_STUDY_BUTLER_LEAVE
const ACTION_CH1_PUZZLE_SOLVED: String = FlowIds.ACTION_CH1_PUZZLE_SOLVED
const ACTION_CH1_MURDER_REQUEST_ACCEPTED: String = FlowIds.ACTION_CH1_MURDER_REQUEST_ACCEPTED
const ACTION_CH1_CRIME_SCENE_FINISHED: String = FlowIds.ACTION_CH1_CRIME_SCENE_FINISHED

const TIMELINE_CH0_IDENTITY: String = FlowIds.TIMELINE_CH0_IDENTITY
const TIMELINE_CH0_PROLOGUE: String = FlowIds.TIMELINE_CH0_PROLOGUE
const TIMELINE_CH0_SNOW_CAMP_ARRIVAL: String = FlowIds.TIMELINE_CH0_SNOW_CAMP_ARRIVAL
const TIMELINE_CH0_SNOW_PATH_ARRIVAL: String = FlowIds.TIMELINE_CH0_SNOW_PATH_ARRIVAL
const TIMELINE_CH0_VILLA_GATE_ARRIVAL: String = FlowIds.TIMELINE_CH0_VILLA_GATE_ARRIVAL
const TIMELINE_CH0_HALL_ARRIVAL: String = FlowIds.TIMELINE_CH0_HALL_ARRIVAL
const TIMELINE_CH0_HALL_MEMORY: String = FlowIds.TIMELINE_CH0_HALL_MEMORY
const TIMELINE_CH1_STUDY_WAKE: String = FlowIds.TIMELINE_CH1_STUDY_WAKE
const TIMELINE_CH1_PUZZLE_REASONING: String = FlowIds.TIMELINE_CH1_PUZZLE_REASONING
const TIMELINE_CH1_MURDER_REQUEST: String = FlowIds.TIMELINE_CH1_MURDER_REQUEST
const TIMELINE_CH1_CRIME_SCENE: String = FlowIds.TIMELINE_CH1_CRIME_SCENE
const TIMELINE_CH1_BUTLER_BLOCK_LEAVE: String = FlowIds.TIMELINE_CH1_BUTLER_BLOCK_LEAVE
const TIMELINE_CH1_BUTLER_INTRO: String = FlowIds.TIMELINE_CH1_BUTLER_INTRO
const TIMELINE_CH1_LIGHTHOUSE_REASONING_AFTER: String = FlowIds.TIMELINE_CH1_LIGHTHOUSE_REASONING_AFTER

const SUSPICION_CH1_LIGHTHOUSE_STORY: String = FlowIds.SUSPICION_CH1_LIGHTHOUSE_STORY

var _pending_after_dialogue_commands: Array = []
var _current_room: Node2D = null

var _state: RefCounted = FlowState.new(CHAPTER_CH1, STEP_CH1_INTRO_HALL)
var _command_executor: RefCounted = FlowCommandExecutor.new()
var _debug_bootstrap: RefCounted = FlowDebugBootstrap.new()
var _dialogic_bridge: RefCounted = FlowDialogicBridge.new()
var _npc_placement: RefCounted = FlowNpcPlacement.new()
var _progress_rules: RefCounted = FlowProgressRules.new()
var _registry: RefCounted = FlowRegistry.new()
var _scene_navigator: RefCounted = FlowSceneNavigator.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_command_executor.setup(self)
	_scene_navigator.setup(self)
	_npc_placement.reset_npc_locations_for_step(get_current_step_id())

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


func _set_flow_state(
	chapter_id: String,
	step_id: String,
	room_id: String = "",
	next_private_chat_target: String = ""
) -> void:
	_state.apply(chapter_id, step_id, room_id, next_private_chat_target)


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


func prepare_ch0_prologue_start() -> void:
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	_set_flow_state(CHAPTER_CH0_PROLOGUE, STEP_CH0_IDENTITY)
	_pending_after_dialogue_commands.clear()
	_scene_navigator.set_pending_auto_timeline(TIMELINE_CH0_IDENTITY)
	_npc_placement.reset_npc_locations_for_step(get_current_step_id())
	_sync_bgm_for_step(get_current_step_id())
	_dialogic_bridge.set_ch0_character_names_unknown()
	set_dialogic_var("PlayerName", "")
	set_dialogic_var("PlayerGender", "")
	set_dialogic_var("Ch0.Started", true)


func prepare_ch1_legacy_start() -> void:
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	_set_flow_state(CHAPTER_CH1, STEP_CH1_INTRO_HALL)
	_pending_after_dialogue_commands.clear()
	_scene_navigator.set_pending_auto_timeline("")
	_npc_placement.reset_npc_locations_for_step(get_current_step_id())
	_stop_bgm()
	_dialogic_bridge.set_ch0_character_names_revealed()


func start_ch1_study_from_prologue() -> void:
	_set_flow_state(CHAPTER_CH1, STEP_CH1_STUDY_WAKE)
	_pending_after_dialogue_commands.clear()
	_scene_navigator.set_pending_auto_timeline(TIMELINE_CH1_STUDY_WAKE)
	_npc_placement.reset_npc_locations_for_step(get_current_step_id())
	_sync_bgm_for_step(get_current_step_id())
	_dialogic_bridge.set_ch0_character_names_unknown()
	request_scene_change(CH1_STUDY_SCENE_PATH, "SpawnFromChair", TIMELINE_CH1_STUDY_WAKE)


func start_ch1_hall_intro_from_crime_scene() -> void:
	_set_flow_state(CHAPTER_CH1, STEP_CH1_INTRO_HALL)
	_pending_after_dialogue_commands.clear()
	_scene_navigator.set_pending_auto_timeline("")
	_npc_placement.reset_npc_locations_for_step(get_current_step_id())
	_sync_bgm_for_step(get_current_step_id())
	_dialogic_bridge.set_ch1_known_character_names_after_crime_scene()
	request_scene_change(HALL_SCENE_PATH, "InitialSpawn", TIMELINE_CH1_BUTLER_INTRO)


func set_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	_state.step_id = step_id
	_npc_placement.reset_npc_locations_for_step(step_id)
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_ch1_initial_search_finished()


func is_standalone_debug_flow_active() -> bool:
	return _scene_navigator.is_standalone_debug_flow_active()


func prepare_debug_standalone_room(config: Dictionary) -> void:
	var state: Dictionary = _debug_bootstrap.prepare_debug_standalone_room(config, _dialogic_bridge, _npc_placement)
	if state.is_empty():
		return

	var next_state: Variant = state.get("flow_state", null)
	if next_state is RefCounted:
		_state = next_state as RefCounted
	else:
		_state.apply_dictionary(state)
	_pending_after_dialogue_commands.clear()
	_scene_navigator.set_pending_auto_timeline(String(state.get("pending_auto_timeline", "")))
	_scene_navigator.set_pending_standalone_spawn_point(String(state.get("pending_standalone_spawn_point", "")))
	_scene_navigator.mark_standalone_debug_flow_active()
	_refresh_ch1_initial_search_finished()
	_sync_bgm_for_step(get_current_step_id())


func are_manual_panels_unlocked() -> bool:
	return _progress_rules.are_manual_panels_unlocked(
		get_current_chapter_id(),
		get_current_step_id(),
		_scene_navigator.is_standalone_debug_flow_active()
	)


func set_npc_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String = "",
	scene_path: String = ""
) -> void:
	_npc_placement.set_npc_location(
		npc_id,
		room_id,
		spawn_name,
		timeline_name,
		scene_path,
		get_current_room_id(),
		get_current_chapter_id(),
		get_current_step_id(),
		get_private_chat_target()
	)


func request_scene_change(target_scene_path: String, spawn_point: String, auto_timeline: String = "") -> bool:
	return _scene_navigator.request_scene_change(target_scene_path, spawn_point, auto_timeline)


func should_block_current_room_exit() -> bool:
	return _progress_rules.should_block_current_room_exit(get_current_chapter_id(), get_current_step_id(), get_current_room_id())


func consume_pending_standalone_spawn_point(default_spawn_point: String) -> String:
	return _scene_navigator.consume_pending_standalone_spawn_point(default_spawn_point)


func _on_clue_updated(_clue_id: String) -> void:
	_refresh_ch1_initial_search_finished()


func on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	_npc_placement.set_current_room(room)
	_state.room_id = room_id
	setup_room_actors(room)
	_setup_current_room_clues()
	_refresh_ch1_initial_search_finished()


func on_room_presented(_room: Node2D, room_id: String) -> void:
	if room_id != get_current_room_id():
		return
	call_deferred("play_pending_auto_timeline")


func play_pending_auto_timeline() -> void:
	_scene_navigator.play_pending_auto_timeline()


func handle_flow_signal(signal_name: String) -> void:
	_on_flow_signal_requested(signal_name)


func handle_dialogue_ended() -> void:
	_on_dialogue_finished("")


func get_dialogic_var(path: String, default_value: Variant = null) -> Variant:
	return _dialogic_bridge.get_var(path, default_value)


func set_dialogic_var(path: String, value: Variant) -> void:
	_dialogic_bridge.set_var(path, value)


func _get_bgm_config_for_step(step_id: String) -> Dictionary:
	var config_tables: Array = [
		Ch0FlowConfig.STEP_BGM_CONFIGS,
		Ch1FlowConfig.STEP_BGM_CONFIGS,
	]
	for config_table: Dictionary in config_tables:
		var bgm_config: Variant = config_table.get(step_id, null)
		if bgm_config is Dictionary:
			return bgm_config
	return {}


func _sync_bgm_for_step(step_id: String) -> void:
	var bgm_config: Dictionary = _get_bgm_config_for_step(step_id)
	if bgm_config.is_empty():
		return
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm(
			String(bgm_config.get("track_id", "")),
			float(bgm_config.get("fade_seconds", 1.5))
		)


func _stop_bgm() -> void:
	if AudioManager != null and AudioManager.has_method("stop_bgm"):
		AudioManager.stop_bgm()


func setup_room_actors(room: Node2D) -> void:
	_npc_placement.setup_room_actors(
		room,
		get_current_room_id(),
		get_current_chapter_id(),
		get_current_step_id(),
		get_private_chat_target()
	)


func _refresh_current_room_actors() -> void:
	if _current_room == null or get_current_room_id().is_empty():
		return
	_npc_placement.refresh_current_room_actors(
		get_current_room_id(),
		get_current_chapter_id(),
		get_current_step_id(),
		get_private_chat_target()
	)
	_setup_current_room_clues()


func _setup_current_room_clues() -> void:
	if _current_room == null or get_current_room_id().is_empty():
		return
	if CluePlacementManager == null or not CluePlacementManager.has_method("setup_room_clues"):
		return
	CluePlacementManager.setup_room_clues(_current_room, get_current_room_id())


func set_current_ch0_campfire_lit(is_lit: bool) -> void:
	var room: Node = _current_room
	if room == null and SceneManager != null:
		room = SceneManager.current_room
	if room != null and room.has_method("set_campfire_lit"):
		room.set_campfire_lit(is_lit)


func _refresh_ch1_initial_search_finished() -> void:
	_progress_rules.refresh_ch1_initial_search_finished(get_current_step_id(), _dialogic_bridge)


func refresh_initial_search_finished() -> void:
	_refresh_ch1_initial_search_finished()


func _handle_flow_transition(signal_name: String, transition: RefCounted) -> void:
	if transition == null or not transition.handled:
		push_warning("FlowManager: unhandled flow signal '%s'." % signal_name)
		return

	_command_executor.execute_many(transition.immediate_commands)
	_pending_after_dialogue_commands.append_array(transition.after_dialogue_commands)


func set_private_chat_target(value: String) -> void:
	_state.private_chat_target = value


func enter_private_chat() -> void:
	if get_private_chat_target().is_empty():
		set_private_chat_target(String(get_dialogic_var("Ch1.PrivateChat.Target", "")))
	if get_private_chat_target().is_empty():
		push_warning("FlowManager: private chat target is empty.")
		return
	set_npc_location(get_private_chat_target(), ROOM_HUI_KE_TING, "Guest", "1_6_%s" % get_private_chat_target())
	request_scene_change(HUI_KE_TING_SCENE_PATH, "Detective", "1_6_%s" % get_private_chat_target())


func _on_flow_signal_requested(signal_name: String) -> void:
	if signal_name.is_empty():
		return

	var transition: RefCounted = _registry.handle_signal(signal_name, _state)
	_handle_flow_transition(signal_name, transition)


func _on_room_loaded(room: Node2D, room_id: String) -> void:
	on_room_loaded(room, room_id)


func _on_room_presented(room: Node2D, room_id: String) -> void:
	on_room_presented(room, room_id)


func _on_dialogue_finished(_timeline_name: String) -> void:
	if _pending_after_dialogue_commands.is_empty():
		return

	var commands: Array = _pending_after_dialogue_commands.duplicate(true)
	_pending_after_dialogue_commands.clear()
	_command_executor.execute_many(commands)
