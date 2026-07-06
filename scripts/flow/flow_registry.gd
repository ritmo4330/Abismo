extends RefCounted

const Ch0FlowController = preload("res://scripts/flow/chapters/ch0_flow_controller.gd")
const Ch1FlowController = preload("res://scripts/flow/chapters/ch1_flow_controller.gd")
const FlowIds = preload("res://scripts/flow/flow_ids.gd")
const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

var _controllers: Dictionary = {}


func _init() -> void:
	_controllers = {
		FlowIds.CHAPTER_CH0_PROLOGUE: Ch0FlowController.new(),
		FlowIds.CHAPTER_CH1: Ch1FlowController.new(),
	}


func handle_signal(signal_name: String, state: RefCounted) -> RefCounted:
	var controller: RefCounted = _controllers.get(state.chapter_id, null)
	if controller == null:
		return FlowTransition.unhandled()
	return controller.handle_signal(signal_name, state)
