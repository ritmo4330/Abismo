extends Node2D

const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")
const FlowEntries = preload("res://scripts/flow/flow_entries.gd")
const FlowSteps = preload("res://scripts/flow/flow_steps.gd")

const CH0_PROLOGUE_FIRST_LEVEL_PATH: String = "res://scenes/ch0_prologue/ch0_black_screen.tscn"
const CH1_LEGACY_FIRST_LEVEL_PATH: String = "res://scenes/rooms/hall.tscn"
const FIRST_SPAWN_POINT: String = "InitialSpawn"

func _ready() -> void:
	GameManager.enter_gameplay()
	if OS.is_debug_build() and _has_test_private_chat_complete_arg():
		_start_private_chat_complete_test()
		DialogueManager.bootstrap()
		return
	if SaveManager != null and SaveManager.has_pending_load():
		if SaveManager.restore_pending_game(self):
			DialogueManager.bootstrap()
			return
	var boot_mode: String = GameManager.consume_next_boot_mode()
	if boot_mode == GameManager.BOOT_MODE_CH1_LEGACY:
		FlowManager.start_flow(FlowChapters.CH1, FlowEntries.CH1_LEGACY_HALL)
		SceneManager.initialize(self, CH1_LEGACY_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	else:
		FlowManager.start_flow(FlowChapters.CH0_PROLOGUE, FlowEntries.CH0_PROLOGUE_START)
		SceneManager.initialize(self, CH0_PROLOGUE_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
	DialogueManager.bootstrap()


func _has_test_private_chat_complete_arg() -> bool:
	return OS.get_cmdline_args().has("--test-private-chat-complete") \
		or OS.get_cmdline_user_args().has("--test-private-chat-complete")


func _start_private_chat_complete_test() -> void:
	FlowManager.reset_gameplay_runtime()
	FlowManager.apply_flow_state(FlowChapters.CH1, FlowSteps.CH1_PRIVATE_CHAT)
	FlowManager.apply_character_name_state("all_revealed")
	FlowManager.set_dialogic_var(FlowDialogicVars.PLAYER_NAME, "测试玩家")
	FlowManager.set_dialogic_var(FlowDialogicVars.CH1_INITIAL_SEARCH_ENABLED, true)
	FlowManager.set_dialogic_var(FlowDialogicVars.CH1_INITIAL_SEARCH_FINISHED, true)
	FlowManager.set_dialogic_var(FlowDialogicVars.CH1_PRIVATE_CHAT_ENABLED, true)
	for npc_id: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
		FlowManager.set_dialogic_var("Ch1.PrivateChat.%s.Finished" % npc_id, true)
		for selection_index: int in range(1, 4):
			FlowManager.set_dialogic_var(
				"Ch1.NPCIntro.%s.Selected%d" % [npc_id, selection_index], true
			)
	FlowManager.set_dialogic_var("Ch1.NPCIntro.ReadyForSearch", true)
	FlowManager.set_dialogic_var("Ch1.PrivateChat.Zhong.Asked.Lighthouse", true)
	SceneManager.initialize(self, CH1_LEGACY_FIRST_LEVEL_PATH, FIRST_SPAWN_POINT)
