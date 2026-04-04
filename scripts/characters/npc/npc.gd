class_name NpcDialogue
extends Interactable

@export var npc_name: String = "村民"
@export var timeline_name: String = ""


func interact(_player: Player) -> void:
	if timeline_name.is_empty():
		push_warning("NpcDialogue.timeline_name is empty for npc: %s" % npc_name)
		return

	EventBus.dialogue_requested.emit(timeline_name)
