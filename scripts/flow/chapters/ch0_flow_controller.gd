extends RefCounted

const FlowCommand = preload("res://scripts/flow/flow_command.gd")
const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")


func handle_signal(signal_name: String, _state: RefCounted) -> RefCounted:
	match signal_name:
		FlowIds.ACTION_CH0_IDENTITY_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_PROLOGUE_STORY),
				FlowCommand.request_scene(FlowIds.CH0_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", FlowIds.TIMELINE_CH0_PROLOGUE),
			])
		FlowIds.ACTION_CH0_PROLOGUE_INTRO_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_SNOW_CAMP),
				FlowCommand.request_scene(FlowIds.CH0_SNOW_FIELD_SCENE_PATH, "InitialSpawn", FlowIds.TIMELINE_CH0_SNOW_CAMP_ARRIVAL),
			])
		FlowIds.ACTION_CH0_CAMPFIRE_EXTINGUISHED:
			return FlowTransition.immediate([
				FlowCommand.set_campfire_lit(false),
			])
		FlowIds.ACTION_CH0_SNOW_PATH_INTERLUDE_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_SNOW_PATH),
				FlowCommand.request_scene("", "", FlowIds.TIMELINE_CH0_SNOW_PATH_ARRIVAL),
			])
		FlowIds.ACTION_CH0_VILLA_GATE_INTERLUDE_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_VILLA_GATE),
				FlowCommand.request_scene("", "", FlowIds.TIMELINE_CH0_VILLA_GATE_ARRIVAL),
			])
		FlowIds.ACTION_CH0_VILLA_DOOR_KNOCK_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_HALL_ARRIVAL),
				FlowCommand.request_scene(FlowIds.HALL_SCENE_PATH, "SpawnFromGate", FlowIds.TIMELINE_CH0_HALL_ARRIVAL),
			])
		FlowIds.ACTION_CH0_HALL_MEMORY_START:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_HALL_ARRIVAL),
				FlowCommand.request_scene(FlowIds.CH0_BLACK_SCREEN_SCENE_PATH, "InitialSpawn", FlowIds.TIMELINE_CH0_HALL_MEMORY),
			])
		FlowIds.ACTION_CH0_HALL_ARRIVAL_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH0_LOGO),
				FlowCommand.request_scene(FlowIds.CH0_LOGO_SCENE_PATH, "InitialSpawn"),
			])
		_:
			return FlowTransition.unhandled()
