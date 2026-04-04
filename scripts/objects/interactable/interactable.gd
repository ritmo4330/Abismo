class_name Interactable
extends Area2D

@export var interact_id: String = ""
@export var is_one_time: bool = false


func _ready() -> void:
	if interact_id.is_empty():
		return
	if DataManager.get_world_flag(interact_id):
		queue_free()


func interact(player: Player) -> void:
	push_warning("Interactable.interact() should be overridden by subclasses.")
