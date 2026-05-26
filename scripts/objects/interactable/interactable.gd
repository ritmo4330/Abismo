class_name Interactable
extends Area2D

const INTERACTION_HIGHLIGHT_SCENE: PackedScene = preload("res://scenes/objects/interaction_highlight.tscn")

@export var interact_id: String = ""
@export var is_one_time: bool = false
@export var prompt_offset: Vector2 = Vector2.ZERO
@export var highlight_enabled: bool = false
@export var highlight_offset: Vector2 = Vector2.ZERO
@export var highlight_scale: Vector2 = Vector2.ONE
@export var highlight_color: Color = Color(1.0, 0.86, 0.35, 1.0)

var _interaction_highlight: Node2D = null


func _ready() -> void:
	if is_one_time and not interact_id.is_empty() and DataManager.get_world_flag(interact_id):
		queue_free()


func interact(player: Player) -> void:
	push_warning("Interactable.interact() should be overridden by subclasses.")


func set_highlight_active(is_active: bool) -> void:
	if not highlight_enabled or not is_active:
		if _interaction_highlight != null:
			if _interaction_highlight.has_method("set_active"):
				_interaction_highlight.set_active(false)
		return

	_setup_interaction_highlight()
	if _interaction_highlight == null:
		return

	_interaction_highlight.position = highlight_offset
	if _interaction_highlight.has_method("set_base_scale"):
		_interaction_highlight.set_base_scale(highlight_scale)
	if _interaction_highlight.has_method("set_tint"):
		_interaction_highlight.set_tint(highlight_color)
	if _interaction_highlight.has_method("set_active"):
		_interaction_highlight.set_active(true)


func _setup_interaction_highlight() -> void:
	if _interaction_highlight != null:
		return
	_interaction_highlight = INTERACTION_HIGHLIGHT_SCENE.instantiate() as Node2D
	if _interaction_highlight == null:
		return
	add_child(_interaction_highlight)
	_interaction_highlight.position = highlight_offset
	if _interaction_highlight.has_method("set_base_scale"):
		_interaction_highlight.set_base_scale(highlight_scale)
	if _interaction_highlight.has_method("set_tint"):
		_interaction_highlight.set_tint(highlight_color)
	if _interaction_highlight.has_method("set_active"):
		_interaction_highlight.set_active(false)
