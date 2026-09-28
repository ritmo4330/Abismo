extends RefCounted

const FlowTransition = preload("res://scripts/flow/flow_transition.gd")

var _definition: RefCounted = null


func _init(definition: RefCounted) -> void:
	_definition = definition


func handle_event(event_id: String, _state: RefCounted) -> RefCounted:
	if _definition == null:
		return FlowTransition.unhandled()
	return _definition.get_event_transition(event_id)
