class_name NpcDialogue
extends Interactable

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var timeline_name: String = ""


func interact(_player: Player) -> void:
	if timeline_name.is_empty():
		push_warning("NpcDialogue.timeline_name is empty for npc: %s" % _get_debug_name())
		return

	EventBus.dialogue_requested.emit(timeline_name)


func _get_debug_name() -> String:
	if not npc_name.is_empty():
		return npc_name
	if not npc_id.is_empty():
		return npc_id
	return name
