class_name DemoStudyChair
extends Interactable

@export var required_clue_ids: PackedStringArray = PackedStringArray([
	"demo_study_door",
	"demo_study_bookshelf",
	"demo_study_quote",
])
@export var puzzle_clue_id: String = "demo_clue_puzzle_story"
@export var challenge_clue_id: String = "demo_clue_challenge_rules"
@export var reasoning_timeline: String = "demo_1_1_puzzle_reasoning"

const FLAG_PUZZLE_READ: String = "demo/study/puzzle_read"
const FLAG_CHALLENGE_READ: String = "demo/study/challenge_read"
const FLAG_REASONING_STARTED: String = "demo/study/reasoning_started"


func interact(_player: Player) -> void:
	if not _has_required_clues():
		_show_notice("再看看书房里的门、书架和名言。", "warning")
		return

	if not DataManager.get_world_flag(FLAG_PUZZLE_READ):
		DataManager.set_world_flag(FLAG_PUZZLE_READ, true)
		DataManager.add_clue(puzzle_clue_id, "scene", "demo_study_chair")
		_emit_single_clue_detail(puzzle_clue_id)
		return

	if not DataManager.get_world_flag(FLAG_CHALLENGE_READ):
		DataManager.set_world_flag(FLAG_CHALLENGE_READ, true)
		_emit_hierarchical_clue_detail(puzzle_clue_id, PackedStringArray([challenge_clue_id]))
		return

	if not DataManager.get_world_flag(FLAG_REASONING_STARTED):
		DataManager.set_world_flag(FLAG_REASONING_STARTED, true)
		if FlowManager != null:
			FlowManager.set_step(FlowManager.STEP_DEMO_PUZZLE)
		EventBus.dialogue_requested.emit(reasoning_timeline)
		return

	if DataManager.has_clue("demo_conclusion_parallel_worlds"):
		_show_notice("推理题已经解开了。", "info")
		return

	_show_notice("按下“V”键打开推理手册，继续解决疑点。", "info")


func _has_required_clues() -> bool:
	for clue_id: String in required_clue_ids:
		if clue_id.is_empty():
			continue
		if not DataManager.has_clue(clue_id):
			return false
	return true


func _emit_single_clue_detail(clue_id: String) -> void:
	if clue_id.is_empty():
		return
	var payload: Dictionary = {
		"mode": "interaction",
		"display_type": "single",
		"parent_clue_id": clue_id,
		"clue_ids": [clue_id],
	}
	EventBus.clue_interaction_details_requested.emit(payload)


func _emit_hierarchical_clue_detail(parent_clue_id: String, child_ids: PackedStringArray) -> void:
	if parent_clue_id.is_empty():
		return
	var child_clue_ids_array: Array[String] = []
	for child_id: String in child_ids:
		if child_id.is_empty():
			continue
		child_clue_ids_array.append(child_id)

	var clue_ids: Array[String] = [parent_clue_id]
	for child_id: String in child_clue_ids_array:
		clue_ids.append(child_id)

	var payload: Dictionary = {
		"mode": "interaction",
		"display_type": "hierarchical",
		"parent_clue_id": parent_clue_id,
		"child_clue_ids": child_clue_ids_array,
		"clue_ids": clue_ids,
	}
	EventBus.clue_interaction_details_requested.emit(payload)


func _show_notice(message: String, notice_type: String) -> void:
	if ToastManager != null:
		ToastManager.show_notice(message, notice_type)
