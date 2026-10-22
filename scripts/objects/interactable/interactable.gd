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
	if is_one_time and not interact_id.is_empty() and DataManager.has_flag(interact_id):
		queue_free()
		return
	input_pickable = true
	if not mouse_entered.is_connected(_on_mouse_entered):
		mouse_entered.connect(_on_mouse_entered)
	if not mouse_exited.is_connected(_on_mouse_exited):
		mouse_exited.connect(_on_mouse_exited)


func interact(player: Player) -> void:
	push_warning("Interactable.interact() should be overridden by subclasses.")


func _input_event(viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if not _is_point_click(event):
		return
	if not _point_click_enabled():
		return
	var source_viewport: Viewport = viewport as Viewport
	if source_viewport != null:
		source_viewport.set_input_as_handled()
	if InteractionFeedback != null:
		InteractionFeedback.show_world_interaction(self)
	var player: Player = null
	if SceneManager != null:
		player = SceneManager.current_player as Player
	interact(player)


func _on_mouse_entered() -> void:
	if not _point_click_enabled():
		return
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)
	set_highlight_active(true)


func _on_mouse_exited() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
	if has_method("_refresh_highlight"):
		call("_refresh_highlight")
	else:
		set_highlight_active(false)


func _point_click_enabled() -> bool:
	if FlowManager != null and not FlowManager.is_free_investigation_active():
		return false
	if SceneManager == null or not SceneManager.has_method("is_static_presentation_mode"):
		return false
	if not SceneManager.is_static_presentation_mode():
		return false
	if SceneManager.is_transitioning:
		return false
	if SceneManager.current_room != null and SceneManager.current_room.has_method("configure_presentation_camera"):
		return false
	if GameManager != null and GameManager.current_state != GameManager.GameState.IN_GAME:
		return false
	return true


func _is_point_click(event: InputEvent) -> bool:
	if not (event is InputEventMouseButton):
		return false
	var mouse_event: InputEventMouseButton = event as InputEventMouseButton
	return mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT


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
