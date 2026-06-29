extends Node

const CHAPTER_CH0_PROLOGUE: String = "ch0_prologue"
const CHAPTER_CH1: String = "ch1_snow_villa"

const STEP_CH0_IDENTITY: String = "ch0_0_1_identity"
const STEP_CH0_PROLOGUE_STORY: String = "ch0_0_2_prologue_story"
const STEP_CH0_SNOW_CAMP: String = "ch0_0_2_snow_camp"
const STEP_CH0_SNOW_PATH: String = "ch0_0_2_snow_path"
const STEP_CH0_VILLA_GATE: String = "ch0_0_2_villa_gate"
const STEP_CH0_HALL_ARRIVAL: String = "ch0_0_2_hall_arrival"
const STEP_CH0_LOGO: String = "ch0_0_2_logo"

const CH0_MANUAL_UNLOCKED_STEPS: Array[String] = []

const STEP_CH1_STUDY_WAKE: String = "ch1_1_study_wake"
const STEP_CH1_STUDY_FREE_INVESTIGATION: String = "ch1_1_study_free_investigation"
const STEP_CH1_PUZZLE: String = "ch1_1_puzzle"
const STEP_CH1_MURDER_REQUEST: String = "ch1_1_murder_request"
const STEP_CH1_CRIME_SCENE: String = "ch1_2_crime_scene"
const STEP_CH1_BODY_CG: String = "ch1_2_body_cg"
const STEP_CH1_INTRO_HALL: String = "ch1_3_intro_hall"
const STEP_CH1_FIRST_SEARCH: String = "ch1_4_first_search"
const STEP_CH1_INITIAL_REASONING: String = "ch1_5_initial_reasoning"
const STEP_CH1_PRIVATE_CHAT: String = "ch1_6_private_chat"
const STEP_CH1_SECOND_SEARCH: String = "ch1_7_second_search"

const ROOM_HALL: String = "hall"
const ROOM_FLOOR2: String = "floor2"
const ROOM_HUI_KE_TING: String = "hui_ke_ting"
const ROOM_FIRST_SEARCH: String = "room_lin_jiu"
const ROOM_SECOND_SEARCH: String = "shu_fang"
const ROOM_CH1_STUDY: String = "ch1_study"
const ROOM_CH1_CRIME_SCENE: String = "ch1_crime_scene_lin_room"

const HALL_SCENE_PATH: String = "res://scenes/rooms/hall.tscn"
const CH0_BLACK_SCREEN_SCENE_PATH: String = "res://scenes/ch0_prologue/ch0_black_screen.tscn"
const CH0_SNOW_FIELD_SCENE_PATH: String = "res://scenes/ch0_prologue/ch0_snow_field.tscn"
const CH0_LOGO_SCENE_PATH: String = "res://scenes/ch0_prologue/ch0_logo.tscn"
const CH1_STUDY_SCENE_PATH: String = "res://scenes/ch1_snow_villa/ch1_study.tscn"
const CH1_CRIME_SCENE_PATH: String = "res://scenes/ch1_snow_villa/ch1_crime_scene_lin_room.tscn"
const CH1_BODY_CG_SCENE_PATH: String = "res://scenes/ch1_snow_villa/ch1_body_cg.tscn"
const HUI_KE_TING_SCENE_PATH: String = "res://scenes/rooms/hui_ke_ting.tscn"
const FIRST_SEARCH_ROOM1_PATH: String = "res://scenes/rooms/floor2.tscn"
const FIRST_SEARCH_ROOM2_PATH: String = "res://scenes/rooms/room_lin_jiu.tscn"
const SECOND_SEARCH_ROOM_PATH: String = "res://scenes/rooms/shu_fang.tscn"
const NPC_SCENE_PATH: String = "res://scenes/characters/npcs/npc.tscn"

const ACTION_START_INITIAL_SEARCH: String = "start_initial_search"
const ACTION_ENTER_ROOM_LIN: String = "enter_room_lin"
const ACTION_START_INITIAL_REASONING: String = "start_initial_reasoning"
const ACTION_ENTER_PRIVATE_CHAT: String = "enter_private_chat"
const ACTION_EXIT_PRIVATE_CHAT: String = "exit_private_chat"
const ACTION_START_SECOND_SEARCH: String = "start_second_search"
const ACTION_EXIT_SECOND_SEARCH: String = "exit_second_search"
const ACTION_START_LIGHTHOUSE_REASONING: String = "start_lighthouse_reasoning"
const ACTION_CH0_IDENTITY_FINISHED: String = "ch0_identity_finished"
const ACTION_CH0_PROLOGUE_INTRO_FINISHED: String = "ch0_prologue_intro_finished"
const ACTION_CH0_CAMPFIRE_EXTINGUISHED: String = "ch0_campfire_extinguished"
const ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED: String = "ch0_snow_path_interlude_finished"
const ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED: String = "ch0_villa_gate_interlude_finished"
const ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED: String = "ch0_villa_door_knock_finished"
const ACTION_CH0_HALL_MEMORY_START: String = "ch0_hall_memory_start"
const ACTION_CH0_HALL_ARRIVAL_FINISHED: String = "ch0_hall_arrival_finished"
const ACTION_CH1_STUDY_WAKE_FINISHED: String = "ch1_study_wake_finished"
const ACTION_CH1_STUDY_BUTLER_ENTER: String = "ch1_study_butler_enter"
const ACTION_CH1_STUDY_BUTLER_LEAVE: String = "ch1_study_butler_leave"
const ACTION_CH1_PUZZLE_SOLVED: String = "ch1_puzzle_solved"
const ACTION_CH1_MURDER_REQUEST_ACCEPTED: String = "ch1_murder_request_accepted"
const ACTION_CH1_CRIME_SCENE_FINISHED: String = "ch1_crime_scene_finished"

const TIMELINE_CH0_IDENTITY: String = "0_1_identity"
const TIMELINE_CH0_PROLOGUE: String = "0_2_prologue"
const TIMELINE_CH0_SNOW_CAMP_ARRIVAL: String = "0_2_snow_camp_arrival"
const TIMELINE_CH0_SNOW_PATH_ARRIVAL: String = "0_2_snow_path_arrival"
const TIMELINE_CH0_VILLA_GATE_ARRIVAL: String = "0_2_villa_gate_arrival"
const TIMELINE_CH0_HALL_ARRIVAL: String = "0_2_hall_arrival"
const TIMELINE_CH0_HALL_MEMORY: String = "0_2_hall_memory"
const TIMELINE_CH1_STUDY_WAKE: String = "1_1_study_wake"
const TIMELINE_CH1_PUZZLE_REASONING: String = "1_1_puzzle_reasoning"
const TIMELINE_CH1_MURDER_REQUEST: String = "1_1_murder_request"
const TIMELINE_CH1_CRIME_SCENE: String = "1_2_crime_scene"
const TIMELINE_CH1_LIGHTHOUSE_REASONING_AFTER: String = "1_6_zhong_lighthouse_resolved"

const SUSPICION_CH1_LIGHTHOUSE_STORY: String = "1_suspicion_lighthouse_story"

const STEP_BGM_CONFIGS: Dictionary = {
	STEP_CH0_IDENTITY: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
	STEP_CH0_PROLOGUE_STORY: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_CH0_SNOW_CAMP: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_CH0_SNOW_PATH: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_CH0_VILLA_GATE: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_CH0_HALL_ARRIVAL: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_CH1_STUDY_WAKE: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	STEP_CH1_STUDY_FREE_INVESTIGATION: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	STEP_CH1_PUZZLE: {"track_id": "thinking_introspection_2", "fade_seconds": 2.0},
	STEP_CH1_MURDER_REQUEST: {"track_id": "truth", "fade_seconds": 2.0},
	STEP_CH1_CRIME_SCENE: {"track_id": "truth", "fade_seconds": 2.0},
	STEP_CH1_INTRO_HALL: {"track_id": "spooky_tension", "fade_seconds": 2.0},
	STEP_CH1_FIRST_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	STEP_CH1_INITIAL_REASONING: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	STEP_CH1_PRIVATE_CHAT: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	STEP_CH1_SECOND_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
}

const FREE_INTERACTION_TIMELINES: Dictionary = {
	CHAPTER_CH1: {
		"butler": "1_3_butler",
		"zhou": "1_3_zhou",
		"mu": "1_3_mu",
		"lin": "1_3_lin",
		"wu": "1_3_wu",
		"zhong": "1_3_zhong",
	},
}

const CH1_INITIAL_SEARCH_REQUIRED_CLUES: Array[String] = [
	"1_lin_1",
	"1_lin_2",
	"1_lin_3",
	# "1_lin_4",
	"1_lin_5",
	# "1_lin_6",
	"1_lin_7",
	"1_mei_1",
	"1_mei_2",
	"1_mu_1",
	"1_wu_1",
	"1_zhong_1",
	"1_zhou_1",
	"1_zhou_2",
	"1_dining_1",
	"1_dining_2",
	"1_hall_1",
	"1_study_3",
	"1_study_4",
	"1_study_5",
	"1_study_6",
]

const NPC_NAMES: Dictionary = {
	"butler": "butler",
	"meta": "meta",
	"zhou": "zhou",
	"mu": "mu",
	"lin": "lin",
	"wu": "wu",
	"zhong": "zhong",
}

const BASE_NPC_LOCATIONS_BY_STEP: Dictionary = {
	STEP_CH1_INTRO_HALL: {
		"butler": {"room_id": ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_HALL, "spawn": "Zhong"},
	},
	STEP_CH1_FIRST_SEARCH: {
		"butler": {"room_id": ROOM_FLOOR2, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_HALL, "spawn": "Zhong"},
	},
	STEP_CH1_INITIAL_REASONING: {
		"butler": {"room_id": ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_HALL, "spawn": "Zhong"},
	},
	STEP_CH1_PRIVATE_CHAT: {
		"butler": {"room_id": ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_HALL, "spawn": "Zhong"},
	},
	STEP_CH1_SECOND_SEARCH: {
	},
	STEP_CH0_HALL_ARRIVAL: {
		"meta": {"room_id": ROOM_HALL, "spawn": "Meta"},
	},
	STEP_CH1_STUDY_WAKE: {
		"butler": {"room_id": ROOM_CH1_STUDY, "spawn": "Butler"},
	},
	STEP_CH1_CRIME_SCENE: {
		"butler": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Mu"},
		"lin": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Lin"},
		"wu": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_CH1_CRIME_SCENE, "spawn": "Zhong"},
	},
}

var current_chapter_id: String = CHAPTER_CH1
var current_step_id: String = STEP_CH1_INTRO_HALL
var current_room_id: String = ""
var pending_auto_timeline: String = ""
var pending_standalone_spawn_point: String = ""
var private_chat_target: String = ""

var _pending_action_after_dialogue: String = ""
var _current_room: Node2D = null
var _npc_locations: Dictionary = {}
var _is_standalone_debug_flow_active: bool = false
var _is_standalone_scene_transitioning: bool = false
var _last_initial_search_missing_signature: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_reset_npc_locations_for_step(current_step_id)

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


func prepare_ch0_prologue_start() -> void:
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	current_chapter_id = CHAPTER_CH0_PROLOGUE
	current_step_id = STEP_CH0_IDENTITY
	current_room_id = ""
	private_chat_target = ""
	_pending_action_after_dialogue = ""
	pending_auto_timeline = TIMELINE_CH0_IDENTITY
	_reset_npc_locations_for_step(current_step_id)
	_sync_bgm_for_step(current_step_id)
	_set_ch0_character_names_unknown()
	set_dialogic_var("PlayerName", "")
	set_dialogic_var("PlayerGender", "")
	set_dialogic_var("Ch0.Started", true)


func prepare_ch1_legacy_start() -> void:
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	current_chapter_id = CHAPTER_CH1
	current_step_id = STEP_CH1_INTRO_HALL
	current_room_id = ""
	private_chat_target = ""
	_pending_action_after_dialogue = ""
	pending_auto_timeline = ""
	_reset_npc_locations_for_step(current_step_id)
	_stop_bgm()
	_set_ch0_character_names_revealed()


func start_ch1_study_from_prologue() -> void:
	current_chapter_id = CHAPTER_CH1
	current_step_id = STEP_CH1_STUDY_WAKE
	current_room_id = ""
	private_chat_target = ""
	_pending_action_after_dialogue = ""
	pending_auto_timeline = TIMELINE_CH1_STUDY_WAKE
	_reset_npc_locations_for_step(current_step_id)
	_sync_bgm_for_step(current_step_id)
	_set_ch0_character_names_unknown()
	request_scene_change(CH1_STUDY_SCENE_PATH, "SpawnFromChair", TIMELINE_CH1_STUDY_WAKE)


func start_ch1_hall_intro_from_crime_scene() -> void:
	current_chapter_id = CHAPTER_CH1
	current_step_id = STEP_CH1_INTRO_HALL
	current_room_id = ""
	private_chat_target = ""
	_pending_action_after_dialogue = ""
	pending_auto_timeline = ""
	_reset_npc_locations_for_step(current_step_id)
	_sync_bgm_for_step(current_step_id)
	_set_ch1_known_character_names_after_crime_scene()
	request_scene_change(HALL_SCENE_PATH, "InitialSpawn")


func set_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	current_step_id = step_id
	_reset_npc_locations_for_step(step_id)
	_sync_bgm_for_step(step_id)
	_refresh_current_room_actors()
	_refresh_ch1_initial_search_finished()


func is_standalone_debug_flow_active() -> bool:
	return _is_standalone_debug_flow_active


func prepare_debug_standalone_room(config: Dictionary) -> void:
	if not OS.is_debug_build():
		return
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	current_chapter_id = String(config.get("chapter_id", CHAPTER_CH1))
	if current_chapter_id.is_empty():
		current_chapter_id = CHAPTER_CH1

	current_step_id = String(config.get("step_id", ""))
	if current_step_id.is_empty():
		current_step_id = _resolve_debug_step_for_room(String(config.get("room_id", "")))

	current_room_id = ""
	private_chat_target = String(config.get("private_chat_target", ""))
	_pending_action_after_dialogue = ""
	pending_auto_timeline = String(config.get("auto_timeline", ""))
	pending_standalone_spawn_point = String(config.get("spawn_point", ""))
	_is_standalone_debug_flow_active = true

	_reset_npc_locations_for_step(current_step_id)
	_apply_debug_step_defaults(current_step_id)
	_apply_debug_character_name_state(String(config.get("character_name_state", "auto")))
	_apply_debug_private_chat_location()
	_apply_debug_runtime_state(config)
	_refresh_ch1_initial_search_finished()
	_sync_bgm_for_step(current_step_id)


func are_manual_panels_unlocked() -> bool:
	if OS.is_debug_build() and _is_standalone_debug_flow_active:
		return true
	if current_chapter_id != CHAPTER_CH0_PROLOGUE:
		return true
	return CH0_MANUAL_UNLOCKED_STEPS.has(current_step_id)


func set_npc_location(
	npc_id: String,
	room_id: String,
	spawn_name: String,
	timeline_name: String = "",
	scene_path: String = ""
) -> void:
	if npc_id.is_empty():
		return
	if room_id.is_empty() or spawn_name.is_empty():
		_npc_locations.erase(npc_id)
		_remove_spawned_npc(_resolve_npc_id(npc_id))
		return

	var location: Dictionary = {
		"room_id": room_id,
		"spawn": spawn_name,
	}
	if not timeline_name.is_empty():
		location["timeline"] = timeline_name
	if not scene_path.is_empty():
		location["scene"] = scene_path
	_npc_locations[npc_id] = location
	_refresh_spawned_npc(npc_id, location)


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


func _start_standalone_scene_change(target_scene_path: String, spawn_point: String, auto_timeline: String) -> void:
	_is_standalone_debug_flow_active = true
	_is_standalone_scene_transitioning = true
	pending_auto_timeline = auto_timeline
	pending_standalone_spawn_point = spawn_point
	call_deferred("_run_standalone_scene_change", target_scene_path)


func _run_standalone_scene_change(target_scene_path: String) -> void:
	if Transition != null and Transition.has_method("fade_out"):
		await Transition.fade_out()

	var error: Error = get_tree().change_scene_to_file(target_scene_path)
	if error != OK:
		push_error("FlowManager: standalone scene change failed: %s" % target_scene_path)
		_is_standalone_scene_transitioning = false
		return

	await get_tree().process_frame
	await get_tree().process_frame

	if Transition != null and Transition.has_method("fade_in"):
		await Transition.fade_in()

	_is_standalone_scene_transitioning = false


func consume_pending_standalone_spawn_point(default_spawn_point: String) -> String:
	if pending_standalone_spawn_point.is_empty():
		return default_spawn_point
	var spawn_point: String = pending_standalone_spawn_point
	pending_standalone_spawn_point = ""
	return spawn_point


func _on_clue_updated(_clue_id: String) -> void:
	_refresh_ch1_initial_search_finished()


func on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	current_room_id = room_id
	setup_room_actors(room)
	_setup_current_room_clues()
	_refresh_ch1_initial_search_finished()


func on_room_presented(_room: Node2D, room_id: String) -> void:
	if room_id != current_room_id:
		return
	call_deferred("play_pending_auto_timeline")


func play_pending_auto_timeline() -> void:
	if pending_auto_timeline.is_empty():
		return
	var timeline_name: String = pending_auto_timeline
	pending_auto_timeline = ""
	EventBus.dialogue_requested.emit(timeline_name)


func handle_flow_signal(signal_name: String) -> void:
	_on_flow_signal_requested(signal_name)


func handle_dialogue_ended() -> void:
	_on_dialogue_finished("")


func get_dialogic_var(path: String, default_value: Variant = null) -> Variant:
	if path.is_empty() or Dialogic == null:
		return default_value

	if Dialogic.VAR != null and Dialogic.VAR.has_method("get_variable"):
		return Dialogic.VAR.get_variable(path, default_value, true)

	var direct_value: Variant = Dialogic.VAR.get(path)
	if direct_value != null:
		return direct_value

	var current: Variant = Dialogic.VAR
	for part: String in path.split("."):
		if current == null:
			return default_value
		if current is Dictionary:
			current = (current as Dictionary).get(part, null)
		elif current is Object:
			current = (current as Object).get(part)
		else:
			return default_value

	if current == null:
		return default_value
	return current


func set_dialogic_var(path: String, value: Variant) -> void:
	if path.is_empty() or Dialogic == null:
		return
	if Dialogic.VAR != null and Dialogic.VAR.has_method("set_variable"):
		if Dialogic.VAR.set_variable(path, value):
			return
	Dialogic.VAR.set(path, value)


func _set_ch0_character_names_unknown() -> void:
	set_dialogic_var("ButlerName", "？？")
	set_dialogic_var("MetaName", "？？")
	set_dialogic_var("ZhongQiName", "？？")


func _set_ch0_character_names_revealed() -> void:
	set_dialogic_var("ButlerName", "管家")
	set_dialogic_var("MetaName", "梅塔")
	set_dialogic_var("ZhongQiName", "钟歧")


func _set_ch1_known_character_names_after_crime_scene() -> void:
	set_dialogic_var("ButlerName", "管家")
	set_dialogic_var("MetaName", "梅塔")
	set_dialogic_var("ZhongQiName", "？？")


func _resolve_debug_step_for_room(debug_room_id: String) -> String:
	match debug_room_id:
		ROOM_CH1_STUDY:
			return STEP_CH1_STUDY_FREE_INVESTIGATION
		ROOM_CH1_CRIME_SCENE:
			return STEP_CH1_CRIME_SCENE
		ROOM_HALL:
			return STEP_CH1_INTRO_HALL
		ROOM_FLOOR2, ROOM_FIRST_SEARCH, "room_lin_jiu", "room_mu_zhi", "room_zhong_qi", "room_zhou_chong_an":
			return STEP_CH1_FIRST_SEARCH
		ROOM_HUI_KE_TING:
			return STEP_CH1_PRIVATE_CHAT
		ROOM_SECOND_SEARCH:
			return STEP_CH1_SECOND_SEARCH
		_:
			return STEP_CH1_INTRO_HALL


func _apply_debug_character_name_state(name_state: String) -> void:
	var resolved_name_state: String = name_state
	if resolved_name_state.is_empty() or resolved_name_state == "auto":
		resolved_name_state = _resolve_debug_character_name_state_for_step(current_step_id)

	match resolved_name_state:
		"all_unknown":
			_set_ch0_character_names_unknown()
		"butler_meta_known":
			_set_ch1_known_character_names_after_crime_scene()
		"all_revealed":
			_set_ch0_character_names_revealed()
		_:
			_set_ch0_character_names_revealed()


func _resolve_debug_character_name_state_for_step(step_id: String) -> String:
	if current_chapter_id == CHAPTER_CH0_PROLOGUE:
		return "all_unknown"

	match step_id:
		STEP_CH1_STUDY_WAKE:
			return "all_unknown"
		STEP_CH1_STUDY_FREE_INVESTIGATION, STEP_CH1_PUZZLE, STEP_CH1_MURDER_REQUEST, STEP_CH1_CRIME_SCENE, STEP_CH1_BODY_CG, STEP_CH1_INTRO_HALL:
			return "butler_meta_known"
		_:
			return "all_revealed"


func _apply_debug_step_defaults(step_id: String) -> void:
	match step_id:
		STEP_CH1_STUDY_FREE_INVESTIGATION:
			set_dialogic_var("Ch1.StudyWake.Finished", true)
		STEP_CH1_PUZZLE:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2"]))
			DataManager.set_world_flag("ch1/study/clues_finished_narration_seen", true)
		STEP_CH1_MURDER_REQUEST:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2", "1_puzzle_story", "1_conclusion_parallel_worlds"]))
			DataManager.set_world_flag("ch1/study/clues_finished_narration_seen", true)
			DataManager.set_world_flag("ch1/study/puzzle_read", true)
			DataManager.set_world_flag("ch1/study/challenge_read", true)
			DataManager.set_world_flag("ch1/study/reasoning_started", true)
		STEP_CH1_INTRO_HALL:
			set_dialogic_var("Ch1.NPCIntro.ReadyForSearch", true)
		STEP_CH1_FIRST_SEARCH:
			set_dialogic_var("Ch1.NPCIntro.ReadyForSearch", true)
			set_dialogic_var("Ch1.InitialSearch.Enabled", true)
			set_dialogic_var("Ch1.BodySearch.Enabled", true)
		STEP_CH1_INITIAL_REASONING:
			set_dialogic_var("Ch1.InitialSearch.Enabled", true)
			set_dialogic_var("Ch1.BodySearch.Enabled", true)
			set_dialogic_var("Ch1.InitialSearch.ReadyForReasoning", true)
			set_dialogic_var("Ch1.InitialSearch.Finished", true)
		STEP_CH1_PRIVATE_CHAT:
			set_dialogic_var("Ch1.PrivateChat.Enabled", true)
			set_dialogic_var("Ch1.InitialSearch.Enabled", true)
			set_dialogic_var("Ch1.InitialSearch.Finished", true)
		STEP_CH1_SECOND_SEARCH:
			set_dialogic_var("Ch1.PrivateChat.Enabled", true)
			set_dialogic_var("Ch1.SecondSearch.Enabled", true)


func _apply_debug_private_chat_location() -> void:
	if current_step_id != STEP_CH1_PRIVATE_CHAT:
		return
	if private_chat_target.is_empty():
		return
	set_npc_location(private_chat_target, ROOM_HUI_KE_TING, "Guest", "1_6_%s" % private_chat_target)
	set_dialogic_var("Ch1.PrivateChat.Target", private_chat_target)


func _apply_debug_runtime_state(config: Dictionary) -> void:
	var player_name: String = String(config.get("player_name", ""))
	if not player_name.is_empty():
		set_dialogic_var("PlayerName", player_name)

	var dialogic_vars: Dictionary = config.get("dialogic_vars", {})
	for variable_path: Variant in dialogic_vars.keys():
		set_dialogic_var(String(variable_path), dialogic_vars[variable_path])

	var world_flags: Dictionary = config.get("world_flags", {})
	for flag_id: Variant in world_flags.keys():
		DataManager.set_world_flag(String(flag_id), bool(world_flags[flag_id]))

	var clue_ids: PackedStringArray = config.get("discovered_clues", PackedStringArray())
	_add_debug_clues(clue_ids)

	var suspicion_ids: PackedStringArray = config.get("discovered_suspicions", PackedStringArray())
	for suspicion_id: String in suspicion_ids:
		DataManager.add_suspicion(suspicion_id, "debug", current_step_id)


func _add_debug_clues(clue_ids: PackedStringArray) -> void:
	for clue_id: String in clue_ids:
		DataManager.add_clue(clue_id, "debug", current_step_id)


func _reset_npc_locations_for_step(step_id: String) -> void:
	_npc_locations.clear()

	var base_locations: Dictionary = BASE_NPC_LOCATIONS_BY_STEP.get(step_id, {})
	for npc_id in base_locations.keys():
		var location_value: Variant = base_locations[npc_id]
		if not (location_value is Dictionary):
			continue
		_npc_locations[String(npc_id)] = (location_value as Dictionary).duplicate(true)


func _sync_bgm_for_step(step_id: String) -> void:
	if not STEP_BGM_CONFIGS.has(step_id):
		return
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		var bgm_config: Dictionary = STEP_BGM_CONFIGS[step_id]
		AudioManager.play_bgm(
			String(bgm_config.get("track_id", "")),
			float(bgm_config.get("fade_seconds", 1.5))
		)


func _stop_bgm() -> void:
	if AudioManager != null and AudioManager.has_method("stop_bgm"):
		AudioManager.stop_bgm()


func _get_spawn_entries_for_room(room_id: String) -> Array:
	var spawn_entries: Array = []
	for npc_id in _npc_locations.keys():
		var location_value: Variant = _npc_locations[npc_id]
		if not (location_value is Dictionary):
			continue

		var location: Dictionary = location_value as Dictionary
		if String(location.get("room_id", "")) != room_id:
			continue

		var spawn_data: Dictionary = location.duplicate(true)
		spawn_data["npc_id"] = String(npc_id)
		spawn_entries.append(spawn_data)
	return spawn_entries


func setup_room_actors(room: Node2D) -> void:
	if room == null:
		return

	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	_clear_dynamic_actors(dynamic_root)

	var spawn_entries: Array = _get_spawn_entries_for_room(current_room_id)
	for spawn_data: Dictionary in spawn_entries:
		spawn_npc(spawn_data, room)


func _refresh_current_room_actors() -> void:
	if _current_room == null or current_room_id.is_empty():
		return
	setup_room_actors(_current_room)
	_setup_current_room_clues()


func _setup_current_room_clues() -> void:
	if _current_room == null or current_room_id.is_empty():
		return
	if CluePlacementManager == null or not CluePlacementManager.has_method("setup_room_clues"):
		return
	CluePlacementManager.setup_room_clues(_current_room, current_room_id)


func _refresh_spawned_npc(npc_id: String, location: Dictionary) -> void:
	if _current_room == null or current_room_id.is_empty():
		return

	var resolved_npc_id: String = _resolve_npc_id(npc_id)
	if resolved_npc_id.is_empty():
		return

	_remove_spawned_npc(resolved_npc_id)
	if String(location.get("room_id", "")) != current_room_id:
		return

	var spawn_data: Dictionary = location.duplicate(true)
	spawn_data["npc_id"] = resolved_npc_id
	spawn_npc(spawn_data, _current_room)


func _remove_spawned_npc(npc_id: String) -> void:
	if _current_room == null or npc_id.is_empty():
		return

	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(_current_room)
	if dynamic_root == null:
		return

	var node_name: String = "NPC_%s" % npc_id
	var npc_node: Node = dynamic_root.get_node_or_null(node_name)
	if npc_node == null:
		return

	dynamic_root.remove_child(npc_node)
	npc_node.queue_free()


func spawn_npc(spawn_data: Dictionary, room: Node2D) -> void:
	var npc_id: String = _resolve_npc_id(String(spawn_data.get("npc_id", "")))
	if npc_id.is_empty():
		return

	var spawn_name: String = String(spawn_data.get("spawn", ""))
	var spawn_point: Marker2D = _get_npc_spawn_point(room, spawn_name)
	var dynamic_root: Node2D = _get_or_create_dynamic_actors_root(room)
	if spawn_point == null or dynamic_root == null:
		push_warning("FlowManager: missing NPC spawn '%s' in room '%s'." % [spawn_name, current_room_id])
		return

	var existing_npc: Node = dynamic_root.get_node_or_null("NPC_%s" % npc_id)
	if existing_npc != null:
		dynamic_root.remove_child(existing_npc)
		existing_npc.queue_free()

	var npc_scene_path: String = String(spawn_data.get("scene", NPC_SCENE_PATH))
	var scene: PackedScene = load(npc_scene_path) as PackedScene
	if scene == null:
		push_warning("FlowManager: unable to load NPC scene '%s'." % npc_scene_path)
		return

	var npc: NpcDialogue = scene.instantiate() as NpcDialogue
	if npc == null:
		push_warning("FlowManager: NPC scene root is not NpcDialogue: %s" % npc_scene_path)
		return

	npc.name = "NPC_%s" % npc_id
	npc.npc_id = npc_id
	npc.npc_name = String(NPC_NAMES.get(npc_id, npc_id))
	_apply_room_npc_settings(npc, room)
	var timeline_override: String = String(spawn_data.get("timeline", ""))
	if timeline_override.is_empty():
		apply_free_timeline(npc)
	else:
		npc.timeline_name = timeline_override.replace("{npc_id}", npc_id)

	dynamic_root.add_child(npc)
	npc.global_position = spawn_point.global_position


func _apply_room_npc_settings(npc: NpcDialogue, room: Node2D) -> void:
	if npc == null or room == null:
		return
	var room_npc_scale: Variant = room.get("npc_spawn_scale")
	if room_npc_scale is Vector2 and not (room_npc_scale as Vector2).is_zero_approx():
		npc.scale = room_npc_scale


func apply_free_timeline(npc: NpcDialogue) -> void:
	if npc == null:
		return

	var chapter_routes: Dictionary = FREE_INTERACTION_TIMELINES.get(current_chapter_id, {})
	if not chapter_routes.has(npc.npc_id):
		return
	npc.timeline_name = String(chapter_routes[npc.npc_id])


func set_current_ch0_campfire_lit(is_lit: bool) -> void:
	var room: Node = _current_room
	if room == null and SceneManager != null:
		room = SceneManager.current_room
	if room != null and room.has_method("set_campfire_lit"):
		room.set_campfire_lit(is_lit)


func _refresh_ch1_initial_search_finished() -> void:
	if current_step_id != STEP_CH1_FIRST_SEARCH:
		return

	var missing_clue_ids: Array[String] = _get_missing_required_clues(CH1_INITIAL_SEARCH_REQUIRED_CLUES)
	var is_finished: bool = missing_clue_ids.is_empty()
	if bool(get_dialogic_var("Ch1.InitialSearch.Finished", false)) == is_finished:
		if not is_finished:
			_log_initial_search_missing_clues(missing_clue_ids)
		return

	set_dialogic_var("Ch1.InitialSearch.Finished", is_finished)
	if is_finished:
		_last_initial_search_missing_signature = ""
	else:
		_log_initial_search_missing_clues(missing_clue_ids)


func _get_missing_required_clues(required_clue_ids: Array[String]) -> Array[String]:
	var missing_clue_ids: Array[String] = []
	if DataManager == null:
		return required_clue_ids.duplicate()
	for clue_id: String in required_clue_ids:
		if clue_id.is_empty():
			continue
		if not DataManager.has_clue(clue_id):
			missing_clue_ids.append(clue_id)
	return missing_clue_ids


func _log_initial_search_missing_clues(missing_clue_ids: Array[String]) -> void:
	var signature: String = ",".join(missing_clue_ids)
	if signature == _last_initial_search_missing_signature:
		return
	_last_initial_search_missing_signature = signature
	push_warning("Ch1 initial search is not finished. Missing clues: %s" % signature)


func _on_flow_signal_requested(signal_name: String) -> void:
	if signal_name.is_empty():
		return

	match signal_name:
		ACTION_START_INITIAL_SEARCH:
			_pending_action_after_dialogue = ACTION_START_INITIAL_SEARCH
		ACTION_ENTER_ROOM_LIN:
			_pending_action_after_dialogue = ACTION_ENTER_ROOM_LIN
		ACTION_START_INITIAL_REASONING:
			_pending_action_after_dialogue = ACTION_START_INITIAL_REASONING
		"enable_private_chat":
			set_step(STEP_CH1_PRIVATE_CHAT)
		ACTION_ENTER_PRIVATE_CHAT:
			private_chat_target = String(get_dialogic_var("Ch1.PrivateChat.Target", ""))
			_pending_action_after_dialogue = ACTION_ENTER_PRIVATE_CHAT
		ACTION_EXIT_PRIVATE_CHAT:
			_pending_action_after_dialogue = ACTION_EXIT_PRIVATE_CHAT
		ACTION_START_SECOND_SEARCH:
			_pending_action_after_dialogue = ACTION_START_SECOND_SEARCH
		ACTION_EXIT_SECOND_SEARCH:
			_pending_action_after_dialogue = ACTION_EXIT_SECOND_SEARCH
			EventBus.dialogue_requested.emit("1_7_exit")
		ACTION_START_LIGHTHOUSE_REASONING:
			_pending_action_after_dialogue = ACTION_START_LIGHTHOUSE_REASONING
		ACTION_CH0_IDENTITY_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_IDENTITY_FINISHED
		ACTION_CH0_PROLOGUE_INTRO_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_PROLOGUE_INTRO_FINISHED
		ACTION_CH0_CAMPFIRE_EXTINGUISHED:
			set_current_ch0_campfire_lit(false)
		ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED
		ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED
		ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED
		ACTION_CH0_HALL_MEMORY_START:
			_pending_action_after_dialogue = ACTION_CH0_HALL_MEMORY_START
		ACTION_CH0_HALL_ARRIVAL_FINISHED:
			_pending_action_after_dialogue = ACTION_CH0_HALL_ARRIVAL_FINISHED
		ACTION_CH1_STUDY_WAKE_FINISHED:
			_pending_action_after_dialogue = ACTION_CH1_STUDY_WAKE_FINISHED
		ACTION_CH1_STUDY_BUTLER_ENTER:
			set_npc_location("butler", ROOM_CH1_STUDY, "Butler")
		ACTION_CH1_STUDY_BUTLER_LEAVE:
			set_npc_location("butler", "", "")
		ACTION_CH1_PUZZLE_SOLVED:
			_pending_action_after_dialogue = ACTION_CH1_PUZZLE_SOLVED
		ACTION_CH1_MURDER_REQUEST_ACCEPTED:
			_pending_action_after_dialogue = ACTION_CH1_MURDER_REQUEST_ACCEPTED
		ACTION_CH1_CRIME_SCENE_FINISHED:
			_pending_action_after_dialogue = ACTION_CH1_CRIME_SCENE_FINISHED
		_:
			push_warning("FlowManager: unhandled flow signal '%s'." % signal_name)


func _on_room_loaded(room: Node2D, room_id: String) -> void:
	on_room_loaded(room, room_id)


func _on_room_presented(room: Node2D, room_id: String) -> void:
	on_room_presented(room, room_id)


func _on_dialogue_finished(_timeline_name: String) -> void:
	if _pending_action_after_dialogue.is_empty():
		return

	var action: String = _pending_action_after_dialogue
	_pending_action_after_dialogue = ""

	match action:
		ACTION_START_INITIAL_SEARCH:
			set_step(STEP_CH1_FIRST_SEARCH)
			set_npc_location("butler", ROOM_FLOOR2, "Butler")
			request_scene_change(FIRST_SEARCH_ROOM1_PATH, "SpawnFromHallLeft", "1_4_butler_a")
		ACTION_ENTER_ROOM_LIN:
			set_step(STEP_CH1_FIRST_SEARCH)
			set_npc_location("butler", ROOM_FIRST_SEARCH, "Butler")
			set_dialogic_var("Ch1.InitialSearch.ReadyForReasoning", true)
			_refresh_ch1_initial_search_finished()
			request_scene_change(FIRST_SEARCH_ROOM2_PATH, "SpawnFromF2", "1_4_butler_b")
		ACTION_START_INITIAL_REASONING:
			set_step(STEP_CH1_INITIAL_REASONING)
			request_scene_change(HALL_SCENE_PATH, "InitialSpawn", "1_5_butler_lin_mu_wu_zhong_zhou")
		ACTION_ENTER_PRIVATE_CHAT:
			set_step(STEP_CH1_PRIVATE_CHAT)
			if private_chat_target.is_empty():
				private_chat_target = String(get_dialogic_var("Ch1.PrivateChat.Target", ""))
			if private_chat_target.is_empty():
				push_warning("FlowManager: private chat target is empty.")
				return
			set_npc_location(private_chat_target, ROOM_HUI_KE_TING, "Guest", "1_6_%s" % private_chat_target)
			request_scene_change(HUI_KE_TING_SCENE_PATH, "Detective", "1_6_%s" % private_chat_target)
		ACTION_EXIT_PRIVATE_CHAT:
			set_step(STEP_CH1_PRIVATE_CHAT)
			private_chat_target = ""
			request_scene_change(HALL_SCENE_PATH, "InitialSpawn")
		ACTION_START_SECOND_SEARCH:
			set_step(STEP_CH1_SECOND_SEARCH)
			request_scene_change(SECOND_SEARCH_ROOM_PATH, "SpawnFromZouLang", "1_7_all")
		ACTION_EXIT_SECOND_SEARCH:
			if bool(get_dialogic_var("Ch1.SecondSearch.Zhong.Finished", false)):
				request_scene_change(HALL_SCENE_PATH, "InitialSpawn")
		ACTION_START_LIGHTHOUSE_REASONING:
			_start_ch1_lighthouse_reasoning()
		ACTION_CH0_IDENTITY_FINISHED:
			set_step(STEP_CH0_PROLOGUE_STORY)
			request_scene_change(CH0_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", TIMELINE_CH0_PROLOGUE)
		ACTION_CH0_PROLOGUE_INTRO_FINISHED:
			set_step(STEP_CH0_SNOW_CAMP)
			request_scene_change(CH0_SNOW_FIELD_SCENE_PATH, "InitialSpawn", TIMELINE_CH0_SNOW_CAMP_ARRIVAL)
		ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED:
			set_step(STEP_CH0_SNOW_PATH)
			request_scene_change("", "", TIMELINE_CH0_SNOW_PATH_ARRIVAL)
		ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED:
			set_step(STEP_CH0_VILLA_GATE)
			request_scene_change("", "", TIMELINE_CH0_VILLA_GATE_ARRIVAL)
		ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED:
			set_step(STEP_CH0_HALL_ARRIVAL)
			request_scene_change(HALL_SCENE_PATH, "SpawnFromGate", TIMELINE_CH0_HALL_ARRIVAL)
		ACTION_CH0_HALL_MEMORY_START:
			set_step(STEP_CH0_HALL_ARRIVAL)
			request_scene_change(CH0_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", TIMELINE_CH0_HALL_MEMORY)
		ACTION_CH0_HALL_ARRIVAL_FINISHED:
			set_step(STEP_CH0_LOGO)
			request_scene_change(CH0_LOGO_SCENE_PATH, "InitialSpawn")
		ACTION_CH1_STUDY_WAKE_FINISHED:
			set_step(STEP_CH1_STUDY_FREE_INVESTIGATION)
			if ToastManager != null:
				ToastManager.show_notice("调查书房", "task", 2.5)
		ACTION_CH1_PUZZLE_SOLVED:
			set_step(STEP_CH1_MURDER_REQUEST)
			request_scene_change("", "", TIMELINE_CH1_MURDER_REQUEST)
		ACTION_CH1_MURDER_REQUEST_ACCEPTED:
			set_step(STEP_CH1_CRIME_SCENE)
			request_scene_change(CH1_CRIME_SCENE_PATH, "SpawnFromStudy", TIMELINE_CH1_CRIME_SCENE)
		ACTION_CH1_CRIME_SCENE_FINISHED:
			set_step(STEP_CH1_BODY_CG)
			request_scene_change(CH1_BODY_CG_SCENE_PATH, "InitialSpawn")
		_:
			push_warning("FlowManager: unhandled pending action '%s'." % action)


func _start_ch1_lighthouse_reasoning() -> void:
	if DataManager != null and not DataManager.has_suspicion(SUSPICION_CH1_LIGHTHOUSE_STORY):
		DataManager.add_suspicion(SUSPICION_CH1_LIGHTHOUSE_STORY, "flow", "1_6_zhong")
	EventBus.locked_suspicion_requested.emit(
		SUSPICION_CH1_LIGHTHOUSE_STORY,
		TIMELINE_CH1_LIGHTHOUSE_REASONING_AFTER
	)


func _resolve_npc_id(raw_npc_id: String) -> String:
	if raw_npc_id == "{private_chat_target}":
		return private_chat_target
	return raw_npc_id


func _get_or_create_dynamic_actors_root(room: Node2D) -> Node2D:
	var dynamic_root: Node2D = null
	if room.has_method("get_dynamic_actors_root"):
		dynamic_root = room.get_dynamic_actors_root()
	else:
		dynamic_root = room.find_child("DynamicActors", true, false) as Node2D

	if dynamic_root != null:
		return dynamic_root

	dynamic_root = Node2D.new()
	dynamic_root.name = "DynamicActors"
	dynamic_root.y_sort_enabled = true
	room.add_child(dynamic_root)
	return dynamic_root


func _clear_dynamic_actors(dynamic_root: Node2D) -> void:
	if dynamic_root == null:
		return
	for child: Node in dynamic_root.get_children():
		dynamic_root.remove_child(child)
		child.queue_free()


func _get_npc_spawn_point(room: Node2D, spawn_name: String) -> Marker2D:
	if room == null or spawn_name.is_empty():
		return null
	if room.has_method("get_npc_spawn_point"):
		return room.get_npc_spawn_point(spawn_name)
	return room.find_child(spawn_name, true, false) as Marker2D
