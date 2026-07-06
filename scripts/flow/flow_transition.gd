extends RefCounted

var handled: bool = false
var immediate_commands: Array[RefCounted] = []
var after_dialogue_commands: Array[RefCounted] = []


func _init(
	is_handled: bool = false,
	immediate: Array[RefCounted] = [],
	after_dialogue: Array[RefCounted] = []
) -> void:
	handled = is_handled
	immediate_commands = immediate
	after_dialogue_commands = after_dialogue


static func unhandled() -> RefCounted:
	return new(false)


static func result(immediate: Array[RefCounted], after_dialogue: Array[RefCounted] = []) -> RefCounted:
	return new(true, immediate, after_dialogue)


static func immediate(commands: Array[RefCounted]) -> RefCounted:
	return result(commands)


static func after_dialogue(commands: Array[RefCounted]) -> RefCounted:
	return result([], commands)
