class_name DemoStudyChair
extends Interactable

const DEFAULT_REQUIRED_CLUE_IDS: Array[String] = [
	"demo_study_door",
	"demo_study_bookshelf",
	"demo_study_quote",
]

@export var required_clue_ids: PackedStringArray = PackedStringArray([
	"demo_study_door",
	"demo_study_bookshelf",
	"demo_study_quote",
])
@export var puzzle_clue_id: String = "demo_clue_puzzle_story"
@export var challenge_clue_id: String = "demo_clue_challenge_rules"
@export var puzzle_timeline: String = "demo_1_1_puzzle_story"
@export var challenge_timeline: String = "demo_1_1_challenge_rules"
@export var reasoning_timeline: String = "demo_1_1_puzzle_reasoning"
@export var clues_finished_timeline: String = "demo_1_1_study_clues_finished"

const FLAG_CLUES_FINISHED_NARRATION_SEEN: String = "demo/study/clues_finished_narration_seen"
const FLAG_PUZZLE_READ: String = "demo/study/puzzle_read"
const FLAG_CHALLENGE_READ: String = "demo/study/challenge_read"
const FLAG_REASONING_STARTED: String = "demo/study/reasoning_started"


func _ready() -> void:
	super._ready()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func interact(_player: Player) -> void:
	if not _has_required_clues():
		_show_notice("再看看书房里的门、书架和名言。", "warning")
		return

	if DataManager.has_clue("demo_conclusion_parallel_worlds"):
		_show_notice("推理题已经解开了。", "info")
		return

	if _try_request_clues_finished_narration():
		return

	if FlowManager != null:
		FlowManager.set_step(FlowManager.STEP_DEMO_PUZZLE)

	if not DataManager.get_world_flag(FLAG_PUZZLE_READ):
		DataManager.set_world_flag(FLAG_PUZZLE_READ, true)
		DataManager.add_clue(puzzle_clue_id, "scene", "demo_study_chair")
		_request_timeline(puzzle_timeline)
		return

	if not DataManager.get_world_flag(FLAG_CHALLENGE_READ):
		DataManager.set_world_flag(FLAG_CHALLENGE_READ, true)
		DataManager.mark_deep_unlocked(puzzle_clue_id)
		_request_timeline(challenge_timeline)
		return

	if not DataManager.get_world_flag(FLAG_REASONING_STARTED):
		DataManager.set_world_flag(FLAG_REASONING_STARTED, true)
		EventBus.dialogue_requested.emit(reasoning_timeline)
		return

	_show_notice("按下“V”键打开推理手册，继续解决疑点。", "info")


func _on_body_entered(body: Node2D) -> void:
	if not (body is Player):
		return
	_try_request_clues_finished_narration()


func _try_request_clues_finished_narration() -> bool:
	if DataManager.get_world_flag(FLAG_CLUES_FINISHED_NARRATION_SEEN):
		return false
	if not _has_required_clues():
		return false

	DataManager.set_world_flag(FLAG_CLUES_FINISHED_NARRATION_SEEN, true)
	_request_timeline(clues_finished_timeline)
	return true


func _has_required_clues() -> bool:
	if required_clue_ids.is_empty():
		return _has_all_required_clues(DEFAULT_REQUIRED_CLUE_IDS)

	var configured_required_clue_ids: Array[String] = []
	for clue_id: String in required_clue_ids:
		configured_required_clue_ids.append(clue_id)
	return _has_all_required_clues(configured_required_clue_ids)


func _has_all_required_clues(clue_ids: Array[String]) -> bool:
	for clue_id: String in clue_ids:
		if clue_id.is_empty():
			continue
		if not DataManager.has_clue(clue_id):
			return false
	return true


func _show_notice(message: String, notice_type: String) -> void:
	if ToastManager != null:
		ToastManager.show_notice(message, notice_type)


func _request_timeline(timeline_name: String) -> void:
	if timeline_name.is_empty():
		return
	EventBus.dialogue_requested.emit(timeline_name)
