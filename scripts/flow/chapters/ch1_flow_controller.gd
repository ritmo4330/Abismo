extends RefCounted

const FlowCommand = preload("res://scripts/flow/flow_command.gd")
const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")


func handle_signal(signal_name: String, _state: RefCounted) -> RefCounted:
	match signal_name:
		FlowIds.ACTION_START_INITIAL_SEARCH:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_FIRST_SEARCH),
				FlowCommand.set_npc_location("butler", FlowIds.ROOM_FLOOR2, "Butler"),
				FlowCommand.request_scene(FlowIds.FIRST_SEARCH_ROOM1_PATH, "SpawnFromHallLeft", "1_4_butler_a"),
			])
		FlowIds.ACTION_ENTER_ROOM_LIN:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_FIRST_SEARCH),
				FlowCommand.set_npc_location("butler", FlowIds.ROOM_FIRST_SEARCH, "Butler"),
				FlowCommand.set_dialogic_var("Ch1.InitialSearch.ReadyForReasoning", true),
				FlowCommand.refresh_initial_search(),
				FlowCommand.request_scene(FlowIds.FIRST_SEARCH_ROOM2_PATH, "SpawnFromF2", "1_4_butler_b"),
			])
		FlowIds.ACTION_START_INITIAL_REASONING:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_INITIAL_REASONING),
				FlowCommand.request_scene(FlowIds.HALL_SCENE_PATH, "InitialSpawn", "1_5_butler_lin_mu_wu_zhong_zhou"),
			])
		"enable_private_chat":
			return FlowTransition.immediate([
				FlowCommand.set_step(FlowIds.STEP_CH1_PRIVATE_CHAT),
			])
		FlowIds.ACTION_ENTER_PRIVATE_CHAT:
			return FlowTransition.result(
				[FlowCommand.set_private_chat_target_from_dialogic("Ch1.PrivateChat.Target")],
				[
					FlowCommand.set_step(FlowIds.STEP_CH1_PRIVATE_CHAT),
					FlowCommand.enter_private_chat(),
				]
			)
		FlowIds.ACTION_EXIT_PRIVATE_CHAT:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_PRIVATE_CHAT),
				FlowCommand.set_private_chat_target(""),
				FlowCommand.request_scene(FlowIds.HALL_SCENE_PATH, "InitialSpawn"),
			])
		FlowIds.ACTION_START_SECOND_SEARCH:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_SECOND_SEARCH),
				FlowCommand.request_scene(FlowIds.SECOND_SEARCH_ROOM_PATH, "SpawnFromZouLang", "1_7_all"),
			])
		FlowIds.ACTION_EXIT_SECOND_SEARCH:
			return FlowTransition.result(
				[FlowCommand.request_dialogue("1_7_exit")],
				[FlowCommand.request_scene_if_dialogic_bool("Ch1.SecondSearch.Zhong.Finished", true, FlowIds.HALL_SCENE_PATH, "InitialSpawn")]
			)
		FlowIds.ACTION_START_LIGHTHOUSE_REASONING:
			return FlowTransition.after_dialogue([
				FlowCommand.add_suspicion_if_missing(FlowIds.SUSPICION_CH1_LIGHTHOUSE_STORY, "flow", "1_6_zhong"),
				FlowCommand.request_locked_suspicion(FlowIds.SUSPICION_CH1_LIGHTHOUSE_STORY, FlowIds.TIMELINE_CH1_LIGHTHOUSE_REASONING_AFTER),
			])
		FlowIds.ACTION_CH1_STUDY_WAKE_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION),
				FlowCommand.show_toast("调查书房", "task", 2.5),
			])
		FlowIds.ACTION_CH1_STUDY_BUTLER_ENTER:
			return FlowTransition.immediate([
				FlowCommand.set_npc_location("butler", FlowIds.ROOM_CH1_STUDY, "Butler"),
			])
		FlowIds.ACTION_CH1_STUDY_BUTLER_LEAVE:
			return FlowTransition.immediate([
				FlowCommand.clear_npc_location("butler"),
			])
		FlowIds.ACTION_CH1_PUZZLE_SOLVED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_MURDER_REQUEST),
				FlowCommand.request_scene("", "", FlowIds.TIMELINE_CH1_MURDER_REQUEST),
			])
		FlowIds.ACTION_CH1_MURDER_REQUEST_ACCEPTED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_CRIME_SCENE),
				FlowCommand.request_scene(FlowIds.CH1_CRIME_SCENE_PATH, "SpawnFromStudy", FlowIds.TIMELINE_CH1_CRIME_SCENE),
			])
		FlowIds.ACTION_CH1_CRIME_SCENE_FINISHED:
			return FlowTransition.after_dialogue([
				FlowCommand.set_step(FlowIds.STEP_CH1_BODY_CG),
				FlowCommand.request_scene(FlowIds.CH1_BODY_CG_SCENE_PATH, "InitialSpawn"),
			])
		_:
			return FlowTransition.unhandled()
