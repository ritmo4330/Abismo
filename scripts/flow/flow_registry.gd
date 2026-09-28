extends RefCounted

const Ch0FlowConfig = preload("res://scripts/flow/configs/ch0_flow_config.gd")
const Ch0FlowController = preload("res://scripts/flow/chapters/ch0_flow_controller.gd")
const Ch1FlowConfig = preload("res://scripts/flow/configs/ch1_flow_config.gd")
const Ch1FlowController = preload("res://scripts/flow/chapters/ch1_flow_controller.gd")
const Ch2FlowConfig = preload("res://scripts/flow/configs/ch2_flow_config.gd")
const Ch2FlowController = preload("res://scripts/flow/chapters/ch2_flow_controller.gd")
const Ch3FlowConfig = preload("res://scripts/flow/configs/ch3_flow_config.gd")
const Ch3FlowController = preload("res://scripts/flow/chapters/ch3_flow_controller.gd")
const FinaleFlowConfig = preload("res://scripts/flow/configs/finale_flow_config.gd")
const FinaleFlowController = preload("res://scripts/flow/chapters/finale_flow_controller.gd")
const FlowChapters = preload("res://scripts/flow/flow_chapters.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

var _definitions: Dictionary = {}
var _controllers: Dictionary = {}


func _init() -> void:
	var ch0_definition: RefCounted = Ch0FlowConfig.create_definition()
	var ch1_definition: RefCounted = Ch1FlowConfig.create_definition()
	var ch2_definition: RefCounted = Ch2FlowConfig.create_definition()
	var ch3_definition: RefCounted = Ch3FlowConfig.create_definition()
	var finale_definition: RefCounted = FinaleFlowConfig.create_definition()
	_definitions = {
		FlowChapters.CH0_PROLOGUE: ch0_definition,
		FlowChapters.CH1: ch1_definition,
		FlowChapters.CH2: ch2_definition,
		FlowChapters.CH3: ch3_definition,
		FlowChapters.FINALE: finale_definition,
	}
	_controllers = {
		FlowChapters.CH0_PROLOGUE: Ch0FlowController.new(ch0_definition),
		FlowChapters.CH1: Ch1FlowController.new(ch1_definition),
		FlowChapters.CH2: Ch2FlowController.new(ch2_definition),
		FlowChapters.CH3: Ch3FlowController.new(ch3_definition),
		FlowChapters.FINALE: FinaleFlowController.new(finale_definition),
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
