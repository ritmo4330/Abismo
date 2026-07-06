extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowChapterDefinition = preload("res://scripts/flow/flow_chapter_definition.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEffect = preload("res://scripts/flow/flow_effect.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")
const FlowEvents = preload("res://scripts/flow/flow_events.gd")
const FlowRooms = preload("res://scripts/flow/flow_rooms.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const FlowTimelines = preload("res://scripts/flow/flow_timelines.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")


static func create_definition() -> RefCounted:
	var definition: RefCounted = FlowChapterDefinition.new(FlowChapters.CH0_PROLOGUE)
	definition.manual_unlocked_steps = []
	definition.step_bgm_configs = {
		FlowSteps.CH0_IDENTITY: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
		FlowSteps.CH0_PROLOGUE_STORY: {"track_id": "role_exit", "fade_seconds": 2.0},
		FlowSteps.CH0_SNOW_CAMP: {"track_id": "role_exit", "fade_seconds": 2.0},
		FlowSteps.CH0_SNOW_PATH: {"track_id": "role_exit", "fade_seconds": 2.0},
		FlowSteps.CH0_VILLA_GATE: {"track_id": "role_exit", "fade_seconds": 2.0},
		FlowSteps.CH0_HALL_ARRIVAL: {"track_id": "role_exit", "fade_seconds": 2.0},
	}
	definition.base_npc_locations_by_step = {
		FlowSteps.CH0_HALL_ARRIVAL: {
			"meta": {"room_id": FlowRooms.HALL, "spawn": "Meta"},
		},
	}
	definition.entry_transitions = {
		FlowEntries.CH0_PROLOGUE_START: FlowTransition.immediate([
			FlowEffect.reset_runtime_state(),
			FlowEffect.clear_pending_after_dialogue(),
			FlowEffect.set_state(FlowChapters.CH0_PROLOGUE, FlowSteps.CH0_IDENTITY),
			FlowEffect.set_pending_auto_timeline(FlowTimelines.CH0_IDENTITY),
			FlowEffect.set_character_name_state("all_unknown"),
			FlowEffect.set_dialogic_var(FlowDialogicVars.PLAYER_NAME, ""),
			FlowEffect.set_dialogic_var(FlowDialogicVars.PLAYER_GENDER, ""),
			FlowEffect.set_dialogic_var(FlowDialogicVars.CH0_STARTED, true),
		]),
	}
	definition.event_transitions = {
		FlowEvents.CH0_IDENTITY_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_PROLOGUE_STORY),
			FlowEffect.request_scene(FlowScenes.CH0_BLACK_SCREEN, "InitialSpawn", FlowTimelines.CH0_PROLOGUE),
		]),
		FlowEvents.CH0_PROLOGUE_INTRO_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_SNOW_CAMP),
			FlowEffect.request_scene(FlowScenes.CH0_SNOW_FIELD, "InitialSpawn", FlowTimelines.CH0_SNOW_CAMP_ARRIVAL),
		]),
		FlowEvents.CH0_CAMPFIRE_EXTINGUISHED: FlowTransition.immediate([
			FlowEffect.set_campfire_lit(false),
		]),
		FlowEvents.CH0_SNOW_PATH_INTERLUDE_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_SNOW_PATH),
			FlowEffect.request_scene("", "", FlowTimelines.CH0_SNOW_PATH_ARRIVAL),
		]),
		FlowEvents.CH0_VILLA_GATE_INTERLUDE_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_VILLA_GATE),
			FlowEffect.request_scene("", "", FlowTimelines.CH0_VILLA_GATE_ARRIVAL),
		]),
		FlowEvents.CH0_VILLA_DOOR_KNOCK_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_HALL_ARRIVAL),
			FlowEffect.request_scene(FlowScenes.HALL, "SpawnFromGate", FlowTimelines.CH0_HALL_ARRIVAL),
		]),
		FlowEvents.CH0_HALL_MEMORY_START: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_HALL_ARRIVAL),
			FlowEffect.request_scene(FlowScenes.CH0_BLACK_SCREEN, "InitialSpawn", FlowTimelines.CH0_HALL_MEMORY),
		]),
		FlowEvents.CH0_HALL_ARRIVAL_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.CH0_LOGO),
			FlowEffect.request_scene(FlowScenes.CH0_LOGO, "InitialSpawn"),
		]),
	}
	return definition
