extends RefCounted

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowChapterDefinition = preload("res://scripts/flow/flow_chapter_definition.gd")
const FlowEffect = preload("res://scripts/flow/flow_effect.gd")
const FlowEvents = preload("res://scripts/flow/flow_events.gd")
const FlowScenes = preload("res://scripts/flow/flow_scenes.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const FlowTimelines = preload("res://scripts/flow/flow_timelines.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

static func create_definition() -> RefCounted:
	var definition: RefCounted = FlowChapterDefinition.new(FlowChapters.FINALE)
	definition.step_bgm_configs = {
		FlowSteps.FINALE_ENDING: {"track_id": "role_exit", "fade_seconds": 2.5},
		FlowSteps.FINALE_EPILOGUE: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
	}
	definition.event_transitions = {
		FlowEvents.FINALE_TITLE_FINISHED: FlowTransition.immediate([
			FlowEffect.request_scene_if_dialogic_bool("Ending.Dust", true, FlowScenes.HALL, "InitialSpawn", FlowTimelines.FINALE_DUST),
			FlowEffect.request_scene_if_dialogic_bool("Ending.Godslayer", true, FlowScenes.HALL, "InitialSpawn", FlowTimelines.FINALE_GODSLAYER),
			FlowEffect.request_scene_if_dialogic_bool("Ending.Calm", true, FlowScenes.HALL, "InitialSpawn", FlowTimelines.FINALE_CALM),
			FlowEffect.request_scene_if_dialogic_bool("Ending.ClearSnow", true, FlowScenes.HALL, "InitialSpawn", FlowTimelines.FINALE_CLEAR_SNOW),
		]),
		FlowEvents.ENDING_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.FINALE_EPILOGUE),
			FlowEffect.request_dialogue(FlowTimelines.FINALE_EPILOGUE),
		]),
		FlowEvents.GAME_FINISHED: FlowTransition.after_dialogue([
			FlowEffect.set_step(FlowSteps.GAME_COMPLETE),
			FlowEffect.stop_bgm(),
			FlowEffect.request_scene(FlowScenes.GAME_COMPLETE, "InitialSpawn"),
		]),
	}
	return definition
