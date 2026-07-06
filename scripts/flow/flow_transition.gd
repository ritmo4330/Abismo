extends RefCounted

var handled: bool = false
var immediate_effects: Array[RefCounted] = []
var after_dialogue_effects: Array[RefCounted] = []


func _init(
	is_handled: bool = false,
	immediate: Array[RefCounted] = [],
	after_dialogue: Array[RefCounted] = []
) -> void:
	handled = is_handled
	immediate_effects = immediate
	after_dialogue_effects = after_dialogue


static func unhandled() -> RefCounted:
	return new(false)


static func result(immediate: Array[RefCounted], after_dialogue: Array[RefCounted] = []) -> RefCounted:
	return new(true, immediate, after_dialogue)


static func immediate(effects: Array[RefCounted]) -> RefCounted:
	return result(effects)


static func after_dialogue(effects: Array[RefCounted]) -> RefCounted:
	return result([], effects)
