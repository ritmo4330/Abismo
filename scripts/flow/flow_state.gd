extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")

var chapter_id: String = FlowIds.CHAPTER_CH1
var step_id: String = FlowIds.STEP_CH1_INTRO_HALL
var room_id: String = ""
var private_chat_target: String = ""


func _init(
	initial_chapter_id: String = FlowIds.CHAPTER_CH1,
	initial_step_id: String = FlowIds.STEP_CH1_INTRO_HALL,
	initial_room_id: String = "",
	initial_private_chat_target: String = ""
) -> void:
	chapter_id = initial_chapter_id
	step_id = initial_step_id
	room_id = initial_room_id
	private_chat_target = initial_private_chat_target


func apply(
	next_chapter_id: String,
	next_step_id: String,
	next_room_id: String,
	next_private_chat_target: String
) -> void:
	chapter_id = next_chapter_id
	step_id = next_step_id
	room_id = next_room_id
	private_chat_target = next_private_chat_target


func apply_dictionary(state: Dictionary) -> void:
	chapter_id = String(state.get("chapter_id", chapter_id))
	step_id = String(state.get("step_id", step_id))
	room_id = String(state.get("room_id", room_id))
	private_chat_target = String(state.get("private_chat_target", private_chat_target))
