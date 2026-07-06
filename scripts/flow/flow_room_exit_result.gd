extends RefCounted

var blocked: bool = false
var dialogue_timeline: String = ""


func _init(is_blocked: bool = false, timeline_name: String = "") -> void:
	blocked = is_blocked
	dialogue_timeline = timeline_name


static func allow() -> RefCounted:
	return new(false)


static func block_with_dialogue(timeline_name: String) -> RefCounted:
	return new(true, timeline_name)
