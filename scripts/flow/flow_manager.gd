extends Node

const CHAPTER_DEMO: String = "demo"
const CHAPTER_CH1: String = "ch1_snow_villa"

const STEP_DEMO_IDENTITY: String = "demo_0_1_identity"
const STEP_DEMO_PROLOGUE_STORY: String = "demo_0_2_prologue_story"
const STEP_DEMO_SNOW_CAMP: String = "demo_0_2_snow_camp"
const STEP_DEMO_SNOW_PATH: String = "demo_0_2_snow_path"
const STEP_DEMO_VILLA_GATE: String = "demo_0_2_villa_gate"
const STEP_DEMO_HALL_ARRIVAL: String = "demo_0_2_hall_arrival"
const STEP_DEMO_LOGO: String = "demo_0_2_logo"
const STEP_DEMO_STUDY_WAKE: String = "demo_1_1_study_wake"
const STEP_DEMO_STUDY_FREE_INVESTIGATION: String = "demo_1_1_study_free_investigation"
const STEP_DEMO_PUZZLE: String = "demo_1_1_puzzle"
const STEP_DEMO_MURDER_REQUEST: String = "demo_1_1_murder_request"
const STEP_DEMO_CRIME_SCENE: String = "demo_1_2_crime_scene"
const STEP_DEMO_END: String = "demo_end"

const DEMO_MANUAL_UNLOCKED_STEPS: Array[String] = [
	STEP_DEMO_STUDY_WAKE,
	STEP_DEMO_STUDY_FREE_INVESTIGATION,
	STEP_DEMO_PUZZLE,
	STEP_DEMO_MURDER_REQUEST,
	STEP_DEMO_CRIME_SCENE,
	STEP_DEMO_END,
]

const STEP_CH1_INTRO_HALL: String = "ch1_1_intro_hall"
const STEP_CH1_FIRST_SEARCH: String = "ch1_2_first_search"
const STEP_CH1_INITIAL_REASONING: String = "ch1_3_initial_reasoning"
const STEP_CH1_PRIVATE_CHAT: String = "ch1_4_private_chat"
const STEP_CH1_SECOND_SEARCH: String = "ch1_5_second_search"

const ROOM_HALL: String = "hall"
const ROOM_FLOOR2: String = "floor2"
const ROOM_HUI_KE_TING: String = "hui_ke_ting"
const ROOM_FIRST_SEARCH: String = "room_wu_ting_xiang"
const ROOM_SECOND_SEARCH: String = "shu_fang"
const ROOM_DEMO_CRIME_SCENE: String = "demo_crime_scene_lin_room"

const HALL_SCENE_PATH: String = "res://scenes/rooms/hall.tscn"
const DEMO_BLACK_SCREEN_SCENE_PATH: String = "res://scenes/demo/demo_black_screen.tscn"
const DEMO_SNOW_FIELD_SCENE_PATH: String = "res://scenes/demo/demo_snow_field.tscn"
const DEMO_LOGO_SCENE_PATH: String = "res://scenes/demo/demo_logo.tscn"
const DEMO_STUDY_SCENE_PATH: String = "res://scenes/demo/demo_study.tscn"
const DEMO_CRIME_SCENE_PATH: String = "res://scenes/demo/demo_crime_scene_lin_room.tscn"
const DEMO_END_SCENE_PATH: String = "res://scenes/demo/demo_end.tscn"
const HUI_KE_TING_SCENE_PATH: String = "res://scenes/rooms/hui_ke_ting.tscn"
const FIRST_SEARCH_ROOM1_PATH: String = "res://scenes/rooms/floor2.tscn"
const FIRST_SEARCH_ROOM2_PATH: String = "res://scenes/rooms/room_wu_ting_xiang.tscn"
const SECOND_SEARCH_ROOM_PATH: String = "res://scenes/rooms/shu_fang.tscn"
const NPC_SCENE_PATH: String = "res://scenes/characters/npcs/npc.tscn"

const ACTION_START_INITIAL_SEARCH: String = "start_initial_search"
const ACTION_ENTER_ROOM_LIN: String = "enter_room_lin"
const ACTION_START_INITIAL_REASONING: String = "start_initial_reasoning"
const ACTION_ENTER_PRIVATE_CHAT: String = "enter_private_chat"
const ACTION_EXIT_PRIVATE_CHAT: String = "exit_private_chat"
const ACTION_START_SECOND_SEARCH: String = "start_second_search"
const ACTION_EXIT_SECOND_SEARCH: String = "exit_second_search"
const ACTION_DEMO_IDENTITY_FINISHED: String = "demo_identity_finished"
const ACTION_DEMO_PROLOGUE_INTRO_FINISHED: String = "demo_prologue_intro_finished"
const ACTION_DEMO_SNOW_PATH_INTERLUDE_FINISHED: String = "demo_snow_path_interlude_finished"
const ACTION_DEMO_VILLA_GATE_INTERLUDE_FINISHED: String = "demo_villa_gate_interlude_finished"
const ACTION_DEMO_VILLA_DOOR_KNOCK_FINISHED: String = "demo_villa_door_knock_finished"
const ACTION_DEMO_HALL_MEMORY_START: String = "demo_hall_memory_start"
const ACTION_DEMO_HALL_ARRIVAL_FINISHED: String = "demo_hall_arrival_finished"
const ACTION_DEMO_STUDY_WAKE_FINISHED: String = "demo_study_wake_finished"
const ACTION_DEMO_PUZZLE_SOLVED: String = "demo_puzzle_solved"
const ACTION_DEMO_MURDER_REQUEST_ACCEPTED: String = "demo_murder_request_accepted"
const ACTION_DEMO_CRIME_SCENE_FINISHED: String = "demo_crime_scene_finished"

const TIMELINE_DEMO_IDENTITY: String = "demo_0_1_identity"
const TIMELINE_DEMO_PROLOGUE: String = "demo_0_2_prologue"
const TIMELINE_DEMO_SNOW_CAMP_ARRIVAL: String = "demo_0_2_snow_camp_arrival"
const TIMELINE_DEMO_SNOW_PATH_ARRIVAL: String = "demo_0_2_snow_path_arrival"
const TIMELINE_DEMO_VILLA_GATE_ARRIVAL: String = "demo_0_2_villa_gate_arrival"
const TIMELINE_DEMO_HALL_ARRIVAL: String = "demo_0_2_hall_arrival"
const TIMELINE_DEMO_HALL_MEMORY: String = "demo_0_2_hall_memory"
const TIMELINE_DEMO_STUDY_WAKE: String = "demo_1_1_study_wake"
const TIMELINE_DEMO_PUZZLE_REASONING: String = "demo_1_1_puzzle_reasoning"
const TIMELINE_DEMO_MURDER_REQUEST: String = "demo_1_1_murder_request"
const TIMELINE_DEMO_CRIME_SCENE: String = "demo_1_2_crime_scene"

const STEP_BGM_CONFIGS: Dictionary = {
	STEP_DEMO_IDENTITY: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
	STEP_DEMO_PROLOGUE_STORY: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_DEMO_SNOW_CAMP: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_DEMO_SNOW_PATH: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_DEMO_VILLA_GATE: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_DEMO_HALL_ARRIVAL: {"track_id": "role_exit", "fade_seconds": 2.0},
	STEP_DEMO_STUDY_WAKE: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	STEP_DEMO_STUDY_FREE_INVESTIGATION: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	STEP_DEMO_PUZZLE: {"track_id": "thinking_introspection_2", "fade_seconds": 2.0},
	STEP_DEMO_MURDER_REQUEST: {"track_id": "truth", "fade_seconds": 2.0},
	STEP_DEMO_CRIME_SCENE: {"track_id": "truth", "fade_seconds": 2.0},
}

const FREE_INTERACTION_TIMELINES: Dictionary = {
	CHAPTER_CH1: {
		"butler": "1_1_butler",
		"zhou": "1_1_zhou",
		"mu": "1_1_mu",
		"lin": "1_1_lin",
		"wu": "1_1_wu",
		"zhong": "1_1_zhong",
	},
}

const NPC_NAMES: Dictionary = {
	"butler": "butler",
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
	STEP_DEMO_CRIME_SCENE: {
		"butler": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Butler"},
		"zhou": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Zhou"},
		"mu": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Mu"},
		"lin": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Lin"},
		"wu": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Wu"},
		"zhong": {"room_id": ROOM_DEMO_CRIME_SCENE, "spawn": "Zhong"},
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


func prepare_demo_start() -> void:
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	current_chapter_id = CHAPTER_DEMO
	current_step_id = STEP_DEMO_IDENTITY
	current_room_id = ""
	private_chat_target = ""
	_pending_action_after_dialogue = ""
	pending_auto_timeline = TIMELINE_DEMO_IDENTITY
	_reset_npc_locations_for_step(current_step_id)
	_sync_bgm_for_step(current_step_id)
	_set_demo_character_names_unknown()
	set_dialogic_var("PlayerName", "")
	set_dialogic_var("PlayerGender", "")
	set_dialogic_var("Demo.Started", true)


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
	_set_demo_character_names_revealed()


func set_step(step_id: String) -> void:
	if step_id.is_empty():
		return
	current_step_id = step_id
	_reset_npc_locations_for_step(step_id)
	_sync_bgm_for_step(step_id)


func are_manual_panels_unlocked() -> bool:
	if current_chapter_id != CHAPTER_DEMO:
		return true
	return DEMO_MANUAL_UNLOCKED_STEPS.has(current_step_id)


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
		pending_auto_timeline = auto_timeline
		pending_standalone_spawn_point = spawn_point
		var error: Error = get_tree().change_scene_to_file(target_scene_path)
		if error != OK:
			push_error("FlowManager: standalone scene change failed: %s" % target_scene_path)
			return false
		return true

	if SceneManager != null and SceneManager.is_transitioning:
		push_warning("FlowManager: scene change ignored because SceneManager is already transitioning: %s" % target_scene_path)
		return false

	pending_auto_timeline = auto_timeline
	EventBus.scene_change_requested.emit(target_scene_path, spawn_point)
	return true


func consume_pending_standalone_spawn_point(default_spawn_point: String) -> String:
	if pending_standalone_spawn_point.is_empty():
		return default_spawn_point
	var spawn_point: String = pending_standalone_spawn_point
	pending_standalone_spawn_point = ""
	return spawn_point


func on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	current_room_id = room_id
	setup_room_actors(room)


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
	Dialogic.VAR.set(path, value)


func _set_demo_character_names_unknown() -> void:
	set_dialogic_var("ButlerName", "？？")
	set_dialogic_var("MetaName", "？？")
	set_dialogic_var("ZhongQiName", "？？")


func _set_demo_character_names_revealed() -> void:
	set_dialogic_var("ButlerName", "管家")
	set_dialogic_var("MetaName", "梅塔")
	set_dialogic_var("ZhongQiName", "钟歧")


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
	var timeline_override: String = String(spawn_data.get("timeline", ""))
	if timeline_override.is_empty():
		apply_free_timeline(npc)
	else:
		npc.timeline_name = timeline_override.replace("{npc_id}", npc_id)

	dynamic_root.add_child(npc)
	npc.global_position = spawn_point.global_position


func apply_free_timeline(npc: NpcDialogue) -> void:
	if npc == null:
		return

	var chapter_routes: Dictionary = FREE_INTERACTION_TIMELINES.get(current_chapter_id, {})
	if not chapter_routes.has(npc.npc_id):
		return
	npc.timeline_name = String(chapter_routes[npc.npc_id])


func _on_flow_signal_requested(signal_name: String) -> void:
	if signal_name.is_empty():
		return

	match signal_name:
		ACTION_START_INITIAL_SEARCH:
			_pending_action_after_dialogue = ACTION_START_INITIAL_SEARCH
		ACTION_ENTER_ROOM_LIN:
			_pending_action_after_dialogue = ACTION_ENTER_ROOM_LIN
		"start_search_tutorial":
			pass
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
			EventBus.dialogue_requested.emit("1_5_exit")
		ACTION_DEMO_IDENTITY_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_IDENTITY_FINISHED
		ACTION_DEMO_PROLOGUE_INTRO_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_PROLOGUE_INTRO_FINISHED
		ACTION_DEMO_SNOW_PATH_INTERLUDE_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_SNOW_PATH_INTERLUDE_FINISHED
		ACTION_DEMO_VILLA_GATE_INTERLUDE_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_VILLA_GATE_INTERLUDE_FINISHED
		ACTION_DEMO_VILLA_DOOR_KNOCK_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_VILLA_DOOR_KNOCK_FINISHED
		ACTION_DEMO_HALL_MEMORY_START:
			_pending_action_after_dialogue = ACTION_DEMO_HALL_MEMORY_START
		ACTION_DEMO_HALL_ARRIVAL_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_HALL_ARRIVAL_FINISHED
		ACTION_DEMO_STUDY_WAKE_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_STUDY_WAKE_FINISHED
		ACTION_DEMO_PUZZLE_SOLVED:
			_pending_action_after_dialogue = ACTION_DEMO_PUZZLE_SOLVED
		ACTION_DEMO_MURDER_REQUEST_ACCEPTED:
			_pending_action_after_dialogue = ACTION_DEMO_MURDER_REQUEST_ACCEPTED
		ACTION_DEMO_CRIME_SCENE_FINISHED:
			_pending_action_after_dialogue = ACTION_DEMO_CRIME_SCENE_FINISHED
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
			request_scene_change(FIRST_SEARCH_ROOM1_PATH, "SpawnFromHallLeft", "1_2_butler_a")
		ACTION_ENTER_ROOM_LIN:
			set_step(STEP_CH1_FIRST_SEARCH)
			set_npc_location("butler", ROOM_FIRST_SEARCH, "Butler")
			request_scene_change(FIRST_SEARCH_ROOM2_PATH, "SpawnFromF2", "1_2_butler_b")
		ACTION_START_INITIAL_REASONING:
			set_step(STEP_CH1_INITIAL_REASONING)
			request_scene_change(HALL_SCENE_PATH, "InitialSpawn", "1_3_butler_lin_mu_wu_zhong_zhou")
		ACTION_ENTER_PRIVATE_CHAT:
			set_step(STEP_CH1_PRIVATE_CHAT)
			if private_chat_target.is_empty():
				private_chat_target = String(get_dialogic_var("Ch1.PrivateChat.Target", ""))
			if private_chat_target.is_empty():
				push_warning("FlowManager: private chat target is empty.")
				return
			set_npc_location(private_chat_target, ROOM_HUI_KE_TING, "Guest", "1_4_%s" % private_chat_target)
			request_scene_change(HUI_KE_TING_SCENE_PATH, "SpawnFromZouLang", "1_4_%s" % private_chat_target)
		ACTION_EXIT_PRIVATE_CHAT:
			set_step(STEP_CH1_PRIVATE_CHAT)
			private_chat_target = ""
			request_scene_change(HALL_SCENE_PATH, "InitialSpawn")
		ACTION_START_SECOND_SEARCH:
			set_step(STEP_CH1_SECOND_SEARCH)
			request_scene_change(SECOND_SEARCH_ROOM_PATH, "SpawnFromZouLang", "1_5_all")
		ACTION_EXIT_SECOND_SEARCH:
			if bool(get_dialogic_var("Ch1.SecondSearch.Zhong.Finished", false)):
				request_scene_change(HALL_SCENE_PATH, "InitialSpawn")
		ACTION_DEMO_IDENTITY_FINISHED:
			set_step(STEP_DEMO_PROLOGUE_STORY)
			request_scene_change(DEMO_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", TIMELINE_DEMO_PROLOGUE)
		ACTION_DEMO_PROLOGUE_INTRO_FINISHED:
			set_step(STEP_DEMO_SNOW_CAMP)
			request_scene_change(DEMO_SNOW_FIELD_SCENE_PATH, "InitialSpawn", TIMELINE_DEMO_SNOW_CAMP_ARRIVAL)
		ACTION_DEMO_SNOW_PATH_INTERLUDE_FINISHED:
			set_step(STEP_DEMO_SNOW_PATH)
			request_scene_change("", "", TIMELINE_DEMO_SNOW_PATH_ARRIVAL)
		ACTION_DEMO_VILLA_GATE_INTERLUDE_FINISHED:
			set_step(STEP_DEMO_VILLA_GATE)
			request_scene_change("", "", TIMELINE_DEMO_VILLA_GATE_ARRIVAL)
		ACTION_DEMO_VILLA_DOOR_KNOCK_FINISHED:
			set_step(STEP_DEMO_HALL_ARRIVAL)
			request_scene_change(HALL_SCENE_PATH, "SpawnFromGate", TIMELINE_DEMO_HALL_ARRIVAL)
		ACTION_DEMO_HALL_MEMORY_START:
			set_step(STEP_DEMO_HALL_ARRIVAL)
			request_scene_change(DEMO_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", TIMELINE_DEMO_HALL_MEMORY)
		ACTION_DEMO_HALL_ARRIVAL_FINISHED:
			set_step(STEP_DEMO_STUDY_WAKE)
			request_scene_change(DEMO_STUDY_SCENE_PATH, "SpawnFromZouLang", TIMELINE_DEMO_STUDY_WAKE)
		ACTION_DEMO_STUDY_WAKE_FINISHED:
			set_step(STEP_DEMO_STUDY_FREE_INVESTIGATION)
			if ToastManager != null:
				ToastManager.show_notice("调查书房", "task", 2.5)
		ACTION_DEMO_PUZZLE_SOLVED:
			set_step(STEP_DEMO_MURDER_REQUEST)
			request_scene_change("", "", TIMELINE_DEMO_MURDER_REQUEST)
		ACTION_DEMO_MURDER_REQUEST_ACCEPTED:
			set_step(STEP_DEMO_CRIME_SCENE)
			request_scene_change(DEMO_CRIME_SCENE_PATH, "SpawnFromStudy", TIMELINE_DEMO_CRIME_SCENE)
		ACTION_DEMO_CRIME_SCENE_FINISHED:
			set_step(STEP_DEMO_END)
			request_scene_change(DEMO_END_SCENE_PATH, "InitialSpawn")
		_:
			push_warning("FlowManager: unhandled pending action '%s'." % action)


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
