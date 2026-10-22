extends RefCounted

# Hide previous investigation questions without deleting clues, solutions or
# the saved answers. Mandatory private-chat reasoning can still open its lock.
static func visible_now(id: String) -> bool:
	var definition: Resource = DataManager.get_suspicion_def(id)
	if definition == null: return false
	var step: String = FlowManager.get_current_step_id()
	var novel: bool = definition.tags.has("puzzle")
	if step in ["ch1_1_study_wake", "ch1_1_study_free_investigation", "ch1_1_puzzle"]:
		return novel
	if novel: return false
	if step in ["ch1_7_second_search", "ch2_1_second_reasoning", "ch2_2_second_private_chat"]:
		return id.begins_with("2_suspicion_")
	if step in ["ch2_3_third_search", "ch2_4_third_reasoning", "ch2_5_third_private_chat", "ch2_6_memory_fragments"]:
		return id in ["1_suspicion_missing_body", "1_suspicion_lin_custom", "2_suspicion_failed_ritual", "3_suspicion_memory_flower", "3_suspicion_memory_cube"]
	if FlowManager.get_current_chapter_id() in ["ch3_transcend", "ch4_finale"]:
		return id.begins_with("3_suspicion_")
	return id.begins_with("1_suspicion_") and id != "1_suspicion_missing_body"

static func reasoning_title() -> String:
	return "小说谜题" if FlowManager.get_current_step_id() == "ch1_1_puzzle" else "本轮推理"
