extends RefCounted

const Ch0FlowConfig = preload("res://scripts/flow/configs/ch0_flow_config.gd")
const Ch0FlowController = preload("res://scripts/flow/chapters/ch0_flow_controller.gd")
const Ch1FlowConfig = preload("res://scripts/flow/configs/ch1_flow_config.gd")
const Ch1FlowController = preload("res://scripts/flow/chapters/ch1_flow_controller.gd")
const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

var _definitions: Dictionary = {}
var _controllers: Dictionary = {}


func _init() -> void:
	var ch0_definition: RefCounted = Ch0FlowConfig.create_definition()
	var ch1_definition: RefCounted = Ch1FlowConfig.create_definition()
	_definitions = {
		FlowChapters.CH0_PROLOGUE: ch0_definition,
		FlowChapters.CH1: ch1_definition,
	}
	_controllers = {
		FlowChapters.CH0_PROLOGUE: Ch0FlowController.new(ch0_definition),
		FlowChapters.CH1: Ch1FlowController.new(ch1_definition),
	}


func get_definition(chapter_id: String) -> RefCounted:
	return _definitions.get(chapter_id, null) as RefCounted


func get_chapter_ids() -> Array:
	return _definitions.keys()


func get_entry_transition(chapter_id: String, entry_id: String) -> RefCounted:
	var definition: RefCounted = get_definition(chapter_id)
	if definition == null:
		return FlowTransition.unhandled()
	return definition.get_entry_transition(entry_id)


func handle_event(event_id: String, state: RefCounted) -> RefCounted:
	var controller: RefCounted = _controllers.get(state.chapter_id, null)
	if controller == null:
		return FlowTransition.unhandled()
	return controller.handle_event(event_id, state)
