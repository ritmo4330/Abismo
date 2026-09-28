extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowChapterDefinition = preload("res://scripts/flow/flow_chapter_definition.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEffect = preload("res://scripts/flow/flow_effect.gd")
const FlowEvents = preload("res://scripts/flow/flow_events.gd")
const FlowNpcs = preload("res://scripts/flow/flow_npcs.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const FlowTimelines = preload("res://scripts/flow/flow_timelines.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")


static func create_definition() -> RefCounted:
	var definition: RefCounted = FlowChapterDefinition.new(FlowChapters.CH2)
	definition.step_bgm_configs = {
		FlowSteps.CH1_SECOND_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
		FlowSteps.CH2_SECOND_REASONING: {"track_id": "fog_in_brain", "fade_seconds": 2.5},
		FlowSteps.CH2_SECOND_PRIVATE_CHAT: {"track_id": "fog_in_brain", "fade_seconds": 2.0},
		FlowSteps.CH2_THIRD_SEARCH: {"track_id": "fog_in_brain", "fade_seconds": 2.0},
		FlowSteps.CH2_THIRD_REASONING: {"track_id": "thinking_introspection_2", "fade_seconds": 2.0},
		FlowSteps.CH2_THIRD_PRIVATE_CHAT: {"track_id": "fog_in_brain", "fade_seconds": 2.0},
		FlowSteps.CH2_MEMORY_FRAGMENTS: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
	}
	definition.free_interaction_timelines = {
		FlowNpcs.BUTLER: "2_2_butler_hall",
		FlowNpcs.ZHOU: "2_2_zhou_hall",
		FlowNpcs.MU: "2_2_mu_hall",
		FlowNpcs.LIN: "2_2_lin_hall",
		FlowNpcs.WU: "2_2_wu_hall",
		FlowNpcs.ZHONG: "2_2_zhong_hall",
	}
	definition.second_search_required_clues = [
		"1_zhongyue_1", "1_zhongyue_2", "1_zhongyue_3",
	]
	definition.third_search_required_clues = [
		"2_missing_body", "1_lin_7", "2_mu_burnt_church", "2_wu_dream_notebook",
		"2_zhong_anchor_records", "2_zhou_sleep_roster", "2_meta_research_plan",
	]
	definition.base_npc_locations_by_step = {
		FlowSteps.CH1_SECOND_SEARCH: {},
		FlowSteps.CH2_SECOND_REASONING: _hall_guest_locations(),
		FlowSteps.CH2_SECOND_PRIVATE_CHAT: _hall_guest_locations(),
		FlowSteps.CH2_THIRD_SEARCH: _hall_guest_locations({FlowNpcs.BUTLER: {"room_id": FlowRooms.FLOOR2, "spawn": "Butler"}}),
		FlowSteps.CH2_THIRD_REASONING: _hall_guest_locations(),
		FlowSteps.CH2_THIRD_PRIVATE_CHAT: _hall_guest_locations(),
		FlowSteps.CH2_MEMORY_FRAGMENTS: _hall_guest_locations(),
	}
	definition.follow_npc_rules_by_step = _create_follow_npc_rules_by_step()
	definition.debug_step_by_room = {
		FlowRooms.HALL: FlowSteps.CH2_SECOND_PRIVATE_CHAT,
		FlowRooms.FLOOR2: FlowSteps.CH2_THIRD_SEARCH,
		FlowRooms.FIRST_SEARCH: FlowSteps.CH2_THIRD_SEARCH,
		FlowRooms.HUI_KE_TING: FlowSteps.CH2_SECOND_PRIVATE_CHAT,
	}
	definition.event_transitions = {
		FlowEvents.CHAPTER2_TITLE_FINISHED: FlowTransition.immediate([
			FlowEffect.request_scene(FlowScenes.SECOND_SEARCH_ROOM, "InitialSpawn", "1_7_lab_arrival"),
		]),
		FlowEvents.EXIT_SECOND_SEARCH: FlowTransition.immediate([
			FlowEffect.request_dialogue("1_7_exit"),
		]),
		FlowEvents.CONTINUE_SECOND_SEARCH_EXIT: FlowTransition.after_dialogue([
			FlowEffect.request_dialogue("1_7_zhong"),
		]),
		FlowEvents.CH1_SECOND_SEARCH_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Enabled", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Mu.Scene", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Mu.Hidden", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Mu.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhou.Rules", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhou.Fear", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhou.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Lin.Lab", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Lin.Memory", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Lin.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Wu.Door", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Wu.Notebook", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Wu.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhong.Research", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhong.Meta", false),
			FlowEffect.set_dialogic_var("Ch2.SecondPrivate.Zhong.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdSearch.Enabled", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdSearch.Order", 0),
			FlowEffect.set_dialogic_var("Ch2.ThirdSearch.BodyKnownBeforeTurn", false),
			FlowEffect.set_dialogic_var(FlowDialogicVars.CH2_THIRD_SEARCH_FINISHED, false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Enabled", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Mu.Church", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Mu.Choice", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Mu.Zhong", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Mu.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhou.Experiment", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhou.Meta", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhou.Meaning", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhou.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Lin.Body", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Lin.Memory", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Lin.Records", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Lin.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Wu.Notebook", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Wu.Scenes", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Wu.Lock", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Wu.Help", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Wu.Finished", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhong.Anchor", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhong.Grandfather", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhong.Villa", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhong.Meta", false),
			FlowEffect.set_dialogic_var("Ch2.ThirdPrivate.Zhong.Finished", false),
			FlowEffect.set_dialogic_var(FlowDialogicVars.CH2_CURRENT_CONTENT_COMPLETE_READY, false),
			FlowEffect.set_step(FlowSteps.CH2_SECOND_REASONING),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", FlowTimelines.CH2_SECOND_REASONING),
		]),
		FlowEvents.ENABLE_SECOND_PRIVATE_CHAT: FlowTransition.immediate([
			FlowEffect.set_step(FlowSteps.CH2_SECOND_PRIVATE_CHAT),
		]),
		FlowEvents.ENTER_PRIVATE_CHAT: FlowTransition.result(
			[FlowEffect.set_private_chat_target_from_dialogic(FlowDialogicVars.CH1_PRIVATE_CHAT_TARGET)],
			[FlowEffect.enter_private_chat()]
		),
		FlowEvents.EXIT_PRIVATE_CHAT: FlowTransition.after_dialogue([
			FlowEffect.set_private_chat_target(""),
			FlowEffect.request_scene_if_dialogic_bool(
				FlowDialogicVars.CH2_CURRENT_CONTENT_COMPLETE_READY,
				true,
				FlowScenes.HALL,
				"InitialSpawn",
				FlowTimelines.CH2_MEMORY_FRAGMENTS
			),
			FlowEffect.request_scene_if_dialogic_bool(
				FlowDialogicVars.CH2_CURRENT_CONTENT_COMPLETE_READY,
				false,
				FlowScenes.HALL,
				"InitialSpawn"
			),
		]),
		FlowEvents.START_THIRD_SEARCH: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH2_THIRD_SEARCH),
			FlowEffect.set_dialogic_var(FlowDialogicVars.CH2_THIRD_SEARCH_FINISHED, false),
			FlowEffect.set_dialogic_var("Ch2.ThirdSearch.Order", 0),
			FlowEffect.set_dialogic_var("Ch2.ThirdSearch.BodyKnownBeforeTurn", false),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", FlowTimelines.CH2_THIRD_SEARCH_INTRO),
		]),
		FlowEvents.BEGIN_THIRD_SEARCH_TURN: FlowTransition.after_dialogue([
			FlowEffect.set_npc_location(FlowNpcs.BUTLER, FlowRooms.FLOOR2, "Butler"),
			FlowEffect.request_scene(FlowScenes.FIRST_SEARCH_ROOM1, "SpawnFromHallLeft", FlowTimelines.CH2_THIRD_SEARCH_TURN),
		]),
		FlowEvents.START_THIRD_REASONING: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH2_THIRD_REASONING),
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", FlowTimelines.CH2_THIRD_REASONING),
		]),
		FlowEvents.ENABLE_THIRD_PRIVATE_CHAT: FlowTransition.immediate([
			FlowEffect.set_step(FlowSteps.CH2_THIRD_PRIVATE_CHAT),
		]),
		FlowEvents.CH2_MEMORY_INCOMPLETE: FlowTransition.after_dialogue([
			FlowEffect.set_state(FlowChapters.FINALE, FlowSteps.FINALE_ENDING),
			FlowEffect.set_dialogic_var("Ending.Dust", true),
			FlowEffect.request_scene(FlowScenes.FINALE_TITLE, "InitialSpawn"),
		]),
		FlowEvents.CH2_MEMORY_COMPLETE: FlowTransition.after_dialogue([
			FlowEffect.set_state(FlowChapters.CH3, FlowSteps.CH3_ROUTE),
			FlowEffect.request_scene(FlowScenes.CHAPTER3_TITLE, "InitialSpawn"),
		]),
	}
	return definition


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
		FlowSteps.CH2_THIRD_SEARCH: [{
			"npc_id": FlowNpcs.BUTLER,
			"spawn": "Butler",
			"rooms": [
				FlowRooms.HALL,
				FlowRooms.FLOOR2,
				FlowRooms.FIRST_SEARCH,
				FlowRooms.META,
				FlowRooms.MU_ZHI,
				FlowRooms.WU_TING_XIANG,
				FlowRooms.ZHONG_QI,
				FlowRooms.ZHOU_CHONG_AN,
			],
		}],
	}
