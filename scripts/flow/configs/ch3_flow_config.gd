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
	var definition: RefCounted = FlowChapterDefinition.new(FlowChapters.CH3)
	definition.step_bgm_configs = {
		FlowSteps.CH3_ROUTE: {"track_id": "truth", "fade_seconds": 2.0},
	}
	definition.event_transitions = {
		FlowEvents.CHAPTER3_TITLE_FINISHED: FlowTransition.immediate([
			FlowEffect.request_scene(FlowScenes.HALL, "InitialSpawn", FlowTimelines.CH3_ROUTE),
		]),
		FlowEvents.START_ENDING_DUST: _ending_transition("Ending.Dust"),
		FlowEvents.START_ENDING_GODSLAYER: _ending_transition("Ending.Godslayer"),
		FlowEvents.START_ENDING_CALM: _ending_transition("Ending.Calm"),
		FlowEvents.START_ENDING_CLEAR_SNOW: _ending_transition("Ending.ClearSnow"),
	}
	return definition

static func _ending_transition(flag_path: String) -> RefCounted:
	return FlowTransition.after_dialogue([
		FlowEffect.set_state(FlowChapters.FINALE, FlowSteps.FINALE_ENDING),
		FlowEffect.set_dialogic_var(flag_path, true),
		FlowEffect.request_scene(FlowScenes.FINALE_TITLE, "InitialSpawn"),
	])
