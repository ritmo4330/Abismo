extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowState = preload("res://scripts/flow/flow_state.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")


func prepare_debug_standalone_room(
	config: Dictionary,
	dialogic_bridge: RefCounted,
	npc_state: RefCounted,
	registry: RefCounted
) -> Dictionary:
	if not OS.is_debug_build():
		return {}
	if DataManager != null and DataManager.has_method("reset_runtime_state"):
		DataManager.reset_runtime_state()

	var chapter_id: String = String(config.get("chapter_id", FlowChapters.CH1))
	if chapter_id.is_empty():
		chapter_id = FlowChapters.CH1

	var definition: RefCounted = registry.get_definition(chapter_id)
	var step_id: String = String(config.get("step_id", ""))
	if step_id.is_empty():
		step_id = _resolve_debug_step_for_room(String(config.get("room_id", "")), definition)

	var private_chat_target: String = String(config.get("private_chat_target", ""))
	if definition != null:
		npc_state.reset_for_step(definition.get_base_npc_locations(step_id))
	else:
		npc_state.reset_for_step({})

	_apply_debug_step_defaults(step_id, dialogic_bridge)
	_apply_debug_character_name_state(
		String(config.get("character_name_state", "auto")),
		chapter_id,
		step_id,
		dialogic_bridge
	)
	_apply_debug_private_chat_location(step_id, private_chat_target, dialogic_bridge, npc_state)
	_apply_debug_runtime_state(config, step_id, dialogic_bridge)

	return {
		"flow_state": FlowState.new(chapter_id, step_id, "", private_chat_target),
		"pending_auto_timeline": String(config.get("auto_timeline", "")),
		"pending_standalone_spawn_point": String(config.get("spawn_point", "")),
	}


func _resolve_debug_step_for_room(debug_room_id: String, definition: RefCounted) -> String:
	if definition != null:
		return definition.resolve_debug_step(debug_room_id, FlowSteps.CH1_INTRO_HALL)
	return FlowSteps.CH1_INTRO_HALL


func _apply_debug_character_name_state(
	name_state: String,
	chapter_id: String,
	step_id: String,
	dialogic_bridge: RefCounted
) -> void:
	var resolved_name_state: String = name_state
	if resolved_name_state.is_empty() or resolved_name_state == "auto":
		resolved_name_state = _resolve_debug_character_name_state_for_step(chapter_id, step_id)
	dialogic_bridge.apply_character_name_state(resolved_name_state)


func _resolve_debug_character_name_state_for_step(chapter_id: String, step_id: String) -> String:
	if chapter_id == FlowChapters.CH0_PROLOGUE:
		return "all_unknown"

	match step_id:
		FlowSteps.CH1_STUDY_WAKE:
			return "all_unknown"
		FlowSteps.CH1_STUDY_FREE_INVESTIGATION, FlowSteps.CH1_PUZZLE, FlowSteps.CH1_MURDER_REQUEST, FlowSteps.CH1_CRIME_SCENE, FlowSteps.CH1_BODY_CG, FlowSteps.CH1_INTRO_HALL:
			return "butler_meta_known"
		_:
			return "all_revealed"


func _apply_debug_step_defaults(step_id: String, dialogic_bridge: RefCounted) -> void:
	match step_id:
		FlowSteps.CH1_STUDY_FREE_INVESTIGATION:
			dialogic_bridge.set_var("Ch1.StudyWake.Finished", true)
		FlowSteps.CH1_PUZZLE:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2"]), step_id)
			DataManager.set_flag("ch1/study/clues_finished_narration_seen", true)
		FlowSteps.CH1_MURDER_REQUEST:
			_add_debug_clues(PackedStringArray(["1_study_1", "1_study_7", "1_study_2", "1_puzzle_story", "1_conclusion_parallel_worlds"]), step_id)
			DataManager.set_flag("ch1/study/clues_finished_narration_seen", true)
			DataManager.set_flag("ch1/study/puzzle_read", true)
			DataManager.set_flag("ch1/study/challenge_read", true)
			DataManager.set_flag("ch1/study/reasoning_started", true)
		FlowSteps.CH1_INTRO_HALL:
			dialogic_bridge.set_var(FlowDialogicVars.CH1_NPC_INTRO_READY_FOR_SEARCH, true)
		FlowSteps.CH1_FIRST_SEARCH:
			dialogic_bridge.set_var(FlowDialogicVars.CH1_NPC_INTRO_READY_FOR_SEARCH, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_BODY_SEARCH_ENABLED, true)
		FlowSteps.CH1_INITIAL_REASONING:
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_BODY_SEARCH_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_READY_FOR_REASONING, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_FINISHED, true)
		FlowSteps.CH1_PRIVATE_CHAT:
			dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_INITIAL_SEARCH_FINISHED, true)
		FlowSteps.CH1_SECOND_SEARCH:
			dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, true)
			dialogic_bridge.set_var(FlowDialogicVars.CH1_SECOND_SEARCH_ENABLED, true)


func _apply_debug_private_chat_location(
	step_id: String,
	private_chat_target: String,
	dialogic_bridge: RefCounted,
	npc_state: RefCounted
) -> void:
	if step_id != FlowSteps.CH1_PRIVATE_CHAT:
		return
	if private_chat_target.is_empty():
		return
	npc_state.set_location(private_chat_target, FlowRooms.HUI_KE_TING, "Guest", "1_6_%s" % private_chat_target)
	dialogic_bridge.set_var(FlowDialogicVars.CH1_PRIVATE_CHAT_TARGET, private_chat_target)


func _apply_debug_runtime_state(config: Dictionary, step_id: String, dialogic_bridge: RefCounted) -> void:
	var player_name: String = String(config.get("player_name", ""))
	if not player_name.is_empty():
		dialogic_bridge.set_var(FlowDialogicVars.PLAYER_NAME, player_name)

	var dialogic_vars: Dictionary = config.get("dialogic_vars", {})
	for variable_path: Variant in dialogic_vars.keys():
		dialogic_bridge.set_var(String(variable_path), dialogic_vars[variable_path])

	var world_flags: Dictionary = config.get("world_flags", {})
	for flag_id: Variant in world_flags.keys():
		DataManager.set_flag(String(flag_id), bool(world_flags[flag_id]))

	var clue_ids: PackedStringArray = config.get("discovered_clues", PackedStringArray())
	_add_debug_clues(clue_ids, step_id)

	var suspicion_ids: PackedStringArray = config.get("discovered_suspicions", PackedStringArray())
	for suspicion_id: String in suspicion_ids:
		DataManager.discover_suspicion(suspicion_id, "debug", step_id)


func _add_debug_clues(clue_ids: PackedStringArray, step_id: String) -> void:
	if DataManager == null:
		return
	for clue_id: String in clue_ids:
		DataManager.discover_clue(clue_id, "debug", step_id)
