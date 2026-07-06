extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowChapterDefinition = preload("res://scripts/flow/flow_chapter_definition.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEffect = preload("res://scripts/flow/flow_effect.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")
const FlowEvents = preload("res://scripts/flow/flow_events.gd")
const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const FlowSuspicions = preload("res://scripts/flow/flow_suspicions.gd")
const FlowTimelines = preload("res://scripts/flow/flow_timelines.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")


static func create_definition() -> RefCounted:
	var definition: RefCounted = FlowChapterDefinition.new(FlowChapters.CH1)
	definition.step_bgm_configs = _create_step_bgm_configs()
	definition.free_interaction_timelines = _create_free_interaction_timelines()
	definition.initial_search_required_clues = _create_initial_search_required_clues()
	definition.base_npc_locations_by_step = _create_base_npc_locations_by_step()
	definition.follow_npc_rules_by_step = _create_follow_npc_rules_by_step()
	definition.debug_step_by_room = _create_debug_step_by_room()
	definition.entry_transitions = _create_entry_transitions()
	definition.event_transitions = _create_event_transitions()
	return definition


static func _create_step_bgm_configs() -> Dictionary:
	return {
		FlowSteps.CH1_STUDY_WAKE: {"track_id": "plain_happiness", "fade_seconds": 2.0},
		FlowSteps.CH1_STUDY_FREE_INVESTIGATION: {"track_id": "plain_happiness", "fade_seconds": 2.0},
		FlowSteps.CH1_PUZZLE: {"track_id": "thinking_introspection_2", "fade_seconds": 2.0},
		FlowSteps.CH1_MURDER_REQUEST: {"track_id": "truth", "fade_seconds": 2.0},
		FlowSteps.CH1_CRIME_SCENE: {"track_id": "truth", "fade_seconds": 2.0},
		FlowSteps.CH1_INTRO_HALL: {"track_id": "spooky_tension", "fade_seconds": 2.0},
		FlowSteps.CH1_FIRST_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
		FlowSteps.CH1_INITIAL_REASONING: {"track_id": "what_is_truth", "fade_seconds": 2.0},
		FlowSteps.CH1_PRIVATE_CHAT: {"track_id": "what_is_truth", "fade_seconds": 2.0},
		FlowSteps.CH1_SECOND_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	}


static func _create_free_interaction_timelines() -> Dictionary:
	return {
		FlowNpcs.BUTLER: "1_3_butler",
		FlowNpcs.ZHOU: "1_3_zhou",
		FlowNpcs.MU: "1_3_mu",
		FlowNpcs.LIN: "1_3_lin",
		FlowNpcs.WU: "1_3_wu",
		FlowNpcs.ZHONG: "1_3_zhong",
	}


static func _create_initial_search_required_clues() -> Array[String]:
	return [
		"1_lin_1",
		"1_lin_2",
		"1_lin_3",
		"1_lin_5",
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


static func _create_base_npc_locations_by_step() -> Dictionary:
	return {
		FlowSteps.CH1_INTRO_HALL: _hall_guest_locations(),
		FlowSteps.CH1_FIRST_SEARCH: _hall_guest_locations({FlowNpcs.BUTLER: {"room_id": FlowRooms.FLOOR2, "spawn": "Butler"}}),
		FlowSteps.CH1_INITIAL_REASONING: _hall_guest_locations(),
		FlowSteps.CH1_PRIVATE_CHAT: _hall_guest_locations(),
		FlowSteps.CH1_SECOND_SEARCH: {},
		FlowSteps.CH1_STUDY_WAKE: {
			FlowNpcs.BUTLER: {"room_id": FlowRooms.CH1_STUDY, "spawn": "Butler"},
		},
		FlowSteps.CH1_CRIME_SCENE: {
			FlowNpcs.BUTLER: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Butler"},
			FlowNpcs.ZHOU: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Zhou"},
			FlowNpcs.MU: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Mu"},
			FlowNpcs.LIN: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Lin"},
			FlowNpcs.WU: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Wu"},
			FlowNpcs.ZHONG: {"room_id": FlowRooms.CH1_CRIME_SCENE, "spawn": "Zhong"},
		},
	}


static func _hall_guest_locations(overrides: Dictionary = {}) -> Dictionary:
	var locations: Dictionary = {
		FlowNpcs.BUTLER: {"room_id": FlowRooms.HALL, "spawn": "Butler"},
		FlowNpcs.ZHOU: {"room_id": FlowRooms.HALL, "spawn": "Zhou"},
		FlowNpcs.MU: {"room_id": FlowRooms.HALL, "spawn": "Mu"},
		FlowNpcs.LIN: {"room_id": FlowRooms.HALL, "spawn": "Lin"},
		FlowNpcs.WU: {"room_id": FlowRooms.HALL, "spawn": "Wu"},
		FlowNpcs.ZHONG: {"room_id": FlowRooms.HALL, "spawn": "Zhong"},
	}
	for npc_id: Variant in overrides.keys():
		locations[npc_id] = overrides[npc_id]
	return locations


static func _create_follow_npc_rules_by_step() -> Dictionary:
	return {
		FlowSteps.CH1_FIRST_SEARCH: [
			{
				"npc_id": FlowNpcs.BUTLER,
				"spawn": "Butler",
				"rooms": [
					FlowRooms.HALL,
					FlowRooms.FLOOR2,
					FlowRooms.ZOU_LANG,
					FlowRooms.CAN_TING,
					FlowRooms.HUI_KE_TING,
					FlowRooms.FIRST_SEARCH,
					FlowRooms.META,
					FlowRooms.MU_ZHI,
					FlowRooms.WU_TING_XIANG,
					FlowRooms.ZHONG_QI,
					FlowRooms.ZHOU_CHONG_AN,
					FlowRooms.SECOND_SEARCH,
				],
			},
		],
	}


static func _create_debug_step_by_room() -> Dictionary:
	return {
		FlowRooms.CH1_STUDY: FlowSteps.CH1_STUDY_FREE_INVESTIGATION,
		FlowRooms.CH1_CRIME_SCENE: FlowSteps.CH1_CRIME_SCENE,
		FlowRooms.HALL: FlowSteps.CH1_INTRO_HALL,
		FlowRooms.FLOOR2: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.FIRST_SEARCH: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.MU_ZHI: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.WU_TING_XIANG: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.ZHONG_QI: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.ZHOU_CHONG_AN: FlowSteps.CH1_FIRST_SEARCH,
		FlowRooms.HUI_KE_TING: FlowSteps.CH1_PRIVATE_CHAT,
		FlowRooms.SECOND_SEARCH: FlowSteps.CH1_SECOND_SEARCH,
	}


static func _create_entry_transitions() -> Dictionary:
	return {
		FlowEntries.CH1_LEGACY_HALL: FlowTransition.immediate([
			FlowEffect.reset_runtime_state(),
			FlowEffect.clear_pending_after_dialogue(),
			FlowEffect.set_state(FlowChapters.CH1, FlowSteps.CH1_INTRO_HALL),
			FlowEffect.set_pending_auto_timeline(""),
			FlowEffect.stop_bgm(),
			FlowEffect.set_character_name_state("all_revealed"),
		]),
		FlowEntries.CH1_STUDY_FROM_PROLOGUE: FlowTransition.immediate([
			FlowEffect.clear_pending_after_dialogue(),
			FlowEffect.set_state(FlowChapters.CH1, FlowSteps.CH1_STUDY_WAKE),
			FlowEffect.set_character_name_state("all_unknown"),
			FlowEffect.request_scene(FlowScenes.CH1_STUDY, "SpawnFromChair", FlowTimelines.CH1_STUDY_WAKE),
		]),
		FlowEntries.CH1_HALL_FROM_CRIME_SCENE: FlowTransition.immediate([
			FlowEffect.clear_pending_after_dialogue(),
			FlowEffect.set_state(FlowChapters.CH1, FlowSteps.CH1_INTRO_HALL),
			FlowEffect.set_character_name_state("butler_meta_known"),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", FlowTimelines.CH1_BUTLER_INTRO),
		]),
	}


static func _create_event_transitions() -> Dictionary:
	return {
		FlowEvents.START_INITIAL_SEARCH: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_FIRST_SEARCH),
			FlowEffect.set_npc_location(FlowNpcs.BUTLER, FlowRooms.FLOOR2, "Butler"),
			FlowEffect.request_scene(FlowScenes.FIRST_SEARCH_ROOM1, "SpawnFromHallLeft", "1_4_butler_a"),
		]),
		FlowEvents.ENTER_ROOM_LIN: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_FIRST_SEARCH),
			FlowEffect.set_npc_location(FlowNpcs.BUTLER, FlowRooms.FIRST_SEARCH, "Butler"),
			FlowEffect.set_dialogic_var(FlowDialogicVars.CH1_INITIAL_SEARCH_READY_FOR_REASONING, true),
			FlowEffect.refresh_initial_search(),
			FlowEffect.request_scene(FlowScenes.FIRST_SEARCH_ROOM2, "SpawnFromF2", "1_4_butler_b"),
		]),
		FlowEvents.START_INITIAL_REASONING: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_INITIAL_REASONING),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", "1_5_butler_lin_mu_wu_zhong_zhou"),
		]),
		FlowEvents.ENABLE_PRIVATE_CHAT: FlowTransition.immediate([
			FlowEffect.set_step(FlowSteps.CH1_PRIVATE_CHAT),
		]),
		FlowEvents.ENTER_PRIVATE_CHAT: FlowTransition.result(
			[FlowEffect.set_private_chat_target_from_dialogic(FlowDialogicVars.CH1_PRIVATE_CHAT_TARGET)],
			[
				FlowEffect.set_step(FlowSteps.CH1_PRIVATE_CHAT),
				FlowEffect.enter_private_chat(),
			]
		),
		FlowEvents.EXIT_PRIVATE_CHAT: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_PRIVATE_CHAT),
			FlowEffect.set_private_chat_target(""),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn"),
		]),
		FlowEvents.START_SECOND_SEARCH: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_SECOND_SEARCH),
			FlowEffect.request_scene(FlowScenes.SECOND_SEARCH_ROOM, "SpawnFromZouLang", "1_7_all"),
		]),
		FlowEvents.EXIT_SECOND_SEARCH: FlowTransition.result(
			[FlowEffect.request_dialogue("1_7_exit")],
			[FlowEffect.request_scene_if_dialogic_bool(FlowDialogicVars.CH1_SECOND_SEARCH_ZHONG_FINISHED, true, FlowScenes.HALL, "InitialSpawn")]
		),
		FlowEvents.START_LIGHTHOUSE_REASONING: FlowTransition.after_dialogue([
			FlowEffect.add_suspicion_if_missing(FlowSuspicions.CH1_LIGHTHOUSE_STORY, "flow", "1_6_zhong"),
			FlowEffect.request_locked_suspicion(FlowSuspicions.CH1_LIGHTHOUSE_STORY, FlowTimelines.CH1_LIGHTHOUSE_REASONING_AFTER),
		]),
		FlowEvents.CH1_PUZZLE_STARTED: FlowTransition.immediate([
			FlowEffect.set_step(FlowSteps.CH1_PUZZLE),
		]),
		FlowEvents.CH1_STUDY_WAKE_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_STUDY_FREE_INVESTIGATION),
			FlowEffect.show_toast("调查书房", "task", 2.5),
		]),
		FlowEvents.CH1_STUDY_BUTLER_ENTER: FlowTransition.immediate([
			FlowEffect.set_npc_location(FlowNpcs.BUTLER, FlowRooms.CH1_STUDY, "Butler"),
		]),
		FlowEvents.CH1_STUDY_BUTLER_LEAVE: FlowTransition.immediate([
			FlowEffect.clear_npc_location(FlowNpcs.BUTLER),
		]),
		FlowEvents.CH1_PUZZLE_SOLVED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_MURDER_REQUEST),
			FlowEffect.request_scene("", "", FlowTimelines.CH1_MURDER_REQUEST),
		]),
		FlowEvents.CH1_MURDER_REQUEST_ACCEPTED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_CRIME_SCENE),
			FlowEffect.request_scene(FlowScenes.CH1_CRIME_SCENE, "SpawnFromStudy", FlowTimelines.CH1_CRIME_SCENE),
		]),
		FlowEvents.CH1_CRIME_SCENE_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH1_BODY_CG),
			FlowEffect.request_scene(FlowScenes.CH1_BODY_CG, "InitialSpawn"),
		]),
	}
