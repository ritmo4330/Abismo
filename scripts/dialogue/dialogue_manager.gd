extends Node

const FLOW_SIGNAL_PREFIX: String = "flow:"
const LEGACY_FLOW_SIGNALS: Array[String] = [
	"start_initial_search",
	"enter_room_lin",
	"start_search_tutorial",
	"start_initial_reasoning",
	"enable_private_chat",
	"enter_private_chat",
	"exit_private_chat",
	"start_second_search",
	"exit_second_search",
]

var _is_dialogue_active: bool = false
var _current_timeline_name: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not EventBus.dialogue_requested.is_connected(_on_dialogue_requested):
		EventBus.dialogue_requested.connect(_on_dialogue_requested)

	if not Dialogic.timeline_ended.is_connected(_on_dialogue_ended):
		Dialogic.timeline_ended.connect(_on_dialogue_ended)

	if not Dialogic.signal_event.is_connected(_on_dialogic_signal_event):
		Dialogic.signal_event.connect(_on_dialogic_signal_event)


func bootstrap() -> void:
	# 预留给 GameRoot 的显式启动入口，当前初始化由 Autoload _ready 负责。
	pass


func _on_dialogue_requested(request: Variant) -> void:
	if _is_dialogue_active:
		return
	if Dialogic.current_timeline != null:
		return
	if SceneManager != null and SceneManager.is_transitioning:
		return

	var timeline_name: String = _resolve_timeline_name(request)
	if timeline_name.is_empty():
		push_warning("DialogueManager: dialogue request cannot resolve timeline.")
		return

	_start_dialogue(timeline_name)


func _resolve_timeline_name(request: Variant) -> String:
	if request is String:
		return String(request)

	if request is Dictionary:
		var payload: Dictionary = request

		if payload.has("timeline_name"):
			return String(payload.get("timeline_name", ""))
		if payload.has("dialogue_id"):
			return String(payload.get("dialogue_id", ""))

		if payload.has("npc_id") and payload.has("entry_id"):
			var npc_id: String = String(payload.get("npc_id", ""))
			var entry_id: String = String(payload.get("entry_id", ""))
			return _resolve_timeline_by_route(npc_id, entry_id)

	return ""


func _resolve_timeline_by_route(npc_id: String, entry_id: String) -> String:
	# Task 2.3 预留路由扩展入口：当前先按 npc_id + entry_id 直接拼接时间线键名。
	# Phase 2 后续将替换为资源路由表匹配逻辑。
	if npc_id.is_empty() or entry_id.is_empty():
		return ""
	return "%s_%s" % [npc_id, entry_id]


func _start_dialogue(timeline_name: String) -> void:
	if timeline_name.is_empty():
		return

	if GameManager != null and GameManager.has_method("start_dialogue_state"):
		GameManager.start_dialogue_state()
	else:
		get_tree().paused = true

	Dialogic.process_mode = Node.PROCESS_MODE_ALWAYS
	var layout: Node = Dialogic.start(timeline_name)
	if layout != null:
		layout.process_mode = Node.PROCESS_MODE_ALWAYS

	_current_timeline_name = timeline_name
	_is_dialogue_active = true


func _on_dialogue_ended() -> void:
	if not _is_dialogue_active and Dialogic.current_timeline == null:
		return

	var ended_timeline_name: String = _current_timeline_name
	_is_dialogue_active = false
	_current_timeline_name = ""

	if SceneManager != null and SceneManager.is_transitioning:
		EventBus.dialogue_finished.emit(ended_timeline_name)
		return

	if GameManager != null and GameManager.has_method("end_dialogue_state"):
		GameManager.end_dialogue_state()
	else:
		get_tree().paused = false

	EventBus.dialogue_finished.emit(ended_timeline_name)


func _on_dialogic_signal_event(argument: String) -> void:
	if argument.begins_with("audio:"):
		if AudioManager != null and AudioManager.has_method("handle_dialogic_audio_signal"):
			AudioManager.handle_dialogic_audio_signal(argument.substr("audio:".length()))
		return

	var signal_name: String = _normalize_flow_signal(argument)
	if signal_name.is_empty():
		return
	EventBus.flow_signal_requested.emit(signal_name)


func _normalize_flow_signal(argument: String) -> String:
	if argument.is_empty():
		return ""
	if argument.begins_with(FLOW_SIGNAL_PREFIX):
		return argument.substr(FLOW_SIGNAL_PREFIX.length())
	if LEGACY_FLOW_SIGNALS.has(argument):
		return argument
	return ""
