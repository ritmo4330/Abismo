extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const FlowState = preload("res://scripts/flow/flow_state.gd")


func prepare_debug_standalone_room(
	config: Dictionary,
	dialogic_bridge: RefCounted,
	npc_placement: RefCounted
) -> Dictionary:
	if not OS.is_debug_build():
		return {}
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	var chapter_id: String = String(config.get("chapter_id", FlowIds.CHAPTER_CH1))
	if chapter_id.is_empty():
		chapter_id = FlowIds.CHAPTER_CH1

	var step_id: String = String(config.get("step_id", ""))
	if step_id.is_empty():
		step_id = _resolve_debug_step_for_room(String(config.get("room_id", "")))

	var private_chat_target: String = String(config.get("private_chat_target", ""))
	npc_placement.reset_npc_locations_for_step(step_id)
	_apply_debug_step_defaults(step_id, dialogic_bridge)
	_apply_debug_character_name_state(
		String(config.get("character_name_state", "auto")),
		chapter_id,
		step_id,
		dialogic_bridge
	)
	_apply_debug_private_chat_location(step_id, private_chat_target, dialogic_bridge, npc_placement)
	_apply_debug_runtime_state(config, step_id, dialogic_bridge)

	return {
		"flow_state": FlowState.new(chapter_id, step_id, "", private_chat_target),
		"pending_auto_timeline": String(config.get("auto_timeline", "")),
		"pending_standalone_spawn_point": String(config.get("spawn_point", "")),
	}


func _resolve_debug_step_for_room(debug_room_id: String) -> String:
	match debug_room_id:
		FlowIds.ROOM_CH1_STUDY:
			return FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION
		FlowIds.ROOM_CH1_CRIME_SCENE:
			return FlowIds.STEP_CH1_CRIME_SCENE
		FlowIds.ROOM_HALL:
			return FlowIds.STEP_CH1_INTRO_HALL
		FlowIds.ROOM_FLOOR2, FlowIds.ROOM_FIRST_SEARCH, "room_lin_jiu", "room_mu_zhi", "room_zhong_qi", "room_zhou_chong_an":
			return FlowIds.STEP_CH1_FIRST_SEARCH
		FlowIds.ROOM_HUI_KE_TING:
			return FlowIds.STEP_CH1_PRIVATE_CHAT
		FlowIds.ROOM_SECOND_SEARCH:
			return FlowIds.STEP_CH1_SECOND_SEARCH
		_:
			return FlowIds.STEP_CH1_INTRO_HALL


func _apply_debug_character_name_state(
	name_state: String,
	chapter_id: String,
	step_id: String,
	dialogic_bridge: RefCounted
) -> void:
	var resolved_name_state: String = name_state
	if resolved_name_state.is_empty() or resolved_name_state == "auto":
		resolved_name_state = _resolve_debug_character_name_state_for_step(chapter_id, step_id)

	match resolved_name_state:
		"all_unknown":
			dialogic_bridge.set_ch0_character_names_unknown()
		"butler_meta_known":
			dialogic_bridge.set_ch1_known_character_names_after_crime_scene()
		"all_revealed":
			dialogic_bridge.set_ch0_character_names_revealed()
		_:
			dialogic_bridge.set_ch0_character_names_revealed()


func _resolve_debug_character_name_state_for_step(chapter_id: String, step_id: String) -> String:
	if chapter_id == FlowIds.CHAPTER_CH0_PROLOGUE:
		return "all_unknown"

	match step_id:
		FlowIds.STEP_CH1_STUDY_WAKE:
			return "all_unknown"
		FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION, FlowIds.STEP_CH1_PUZZLE, FlowIds.STEP_CH1_MURDER_REQUEST, FlowIds.STEP_CH1_CRIME_SCENE, FlowIds.STEP_CH1_BODY_CG, FlowIds.STEP_CH1_INTRO_HALL:
			return "butler_meta_known"
		_:
			return "all_revealed"


func _apply_debug_step_defaults(step_id: String, dialogic_bridge: RefCounted) -> void:
	match step_id:
		FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION:
			dialogic_bridge.set_var("Ch1.StudyWake.Finished", true)
		FlowIds.STEP_CH1_PUZZLE:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2"]), step_id)
			DataManager.set_world_flag("ch1/study/clues_finished_narration_seen", true)
		FlowIds.STEP_CH1_MURDER_REQUEST:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2", "1_puzzle_story", "1_conclusion_parallel_worlds"]), step_id)
			DataManager.set_world_flag("ch1/study/clues_finished_narration_seen", true)
			DataManager.set_world_flag("ch1/study/puzzle_read", true)
			DataManager.set_world_flag("ch1/study/challenge_read", true)
			DataManager.set_world_flag("ch1/study/reasoning_started", true)
		FlowIds.STEP_CH1_INTRO_HALL:
			dialogic_bridge.set_var("Ch1.NPCIntro.ReadyForSearch", true)
		FlowIds.STEP_CH1_FIRST_SEARCH:
			dialogic_bridge.set_var("Ch1.NPCIntro.ReadyForSearch", true)
			dialogic_bridge.set_var("Ch1.InitialSearch.Enabled", true)
			dialogic_bridge.set_var("Ch1.BodySearch.Enabled", true)
		FlowIds.STEP_CH1_INITIAL_REASONING:
			dialogic_bridge.set_var("Ch1.InitialSearch.Enabled", true)
			dialogic_bridge.set_var("Ch1.BodySearch.Enabled", true)
			dialogic_bridge.set_var("Ch1.InitialSearch.ReadyForReasoning", true)
			dialogic_bridge.set_var("Ch1.InitialSearch.Finished", true)
		FlowIds.STEP_CH1_PRIVATE_CHAT:
			dialogic_bridge.set_var("Ch1.PrivateChat.Enabled", true)
			dialogic_bridge.set_var("Ch1.InitialSearch.Enabled", true)
			dialogic_bridge.set_var("Ch1.InitialSearch.Finished", true)
		FlowIds.STEP_CH1_SECOND_SEARCH:
			dialogic_bridge.set_var("Ch1.PrivateChat.Enabled", true)
			dialogic_bridge.set_var("Ch1.SecondSearch.Enabled", true)


func _apply_debug_private_chat_location(
	step_id: String,
	private_chat_target: String,
	dialogic_bridge: RefCounted,
	npc_placement: RefCounted
) -> void:
	if step_id != FlowIds.STEP_CH1_PRIVATE_CHAT:
		return
	if private_chat_target.is_empty():
		return
	npc_placement.set_npc_location(private_chat_target, FlowIds.ROOM_HUI_KE_TING, "Guest", "1_6_%s" % private_chat_target, "", "", FlowIds.CHAPTER_CH1, step_id, private_chat_target)
	dialogic_bridge.set_var("Ch1.PrivateChat.Target", private_chat_target)


func _apply_debug_runtime_state(config: Dictionary, step_id: String, dialogic_bridge: RefCounted) -> void:
	var player_name: String = String(config.get("player_name", ""))
	if not player_name.is_empty():
		dialogic_bridge.set_var("PlayerName", player_name)

	var dialogic_vars: Dictionary = config.get("dialogic_vars", {})
	for variable_path: Variant in dialogic_vars.keys():
		dialogic_bridge.set_var(String(variable_path), dialogic_vars[variable_path])

	var world_flags: Dictionary = config.get("world_flags", {})
	for flag_id: Variant in world_flags.keys():
		DataManager.set_world_flag(String(flag_id), bool(world_flags[flag_id]))

	var clue_ids: PackedStringArray = config.get("discovered_clues", PackedStringArray())
	_add_debug_clues(clue_ids, step_id)

	var suspicion_ids: PackedStringArray = config.get("discovered_suspicions", PackedStringArray())
	for suspicion_id: String in suspicion_ids:
		DataManager.add_suspicion(suspicion_id, "debug", step_id)


func _add_debug_clues(clue_ids: PackedStringArray, step_id: String) -> void:
	for clue_id: String in clue_ids:
		DataManager.add_clue(clue_id, "debug", step_id)
