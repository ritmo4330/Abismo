class_name PlayerInteractionArea
extends Area2D

@export var player: Player
@export var prompt_sprite_frames: SpriteFrames = preload("res://assets/UI/key_F_frames.tres")
@export var prompt_vertical_padding: float = 8.0

var _interactables: Array[Interactable] = []
var _current_target: Interactable = null
var _prompt_ui: AnimatedSprite2D = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_ensure_prompt_ui()
	_set_interaction_hint_visible(false)

	if player == null:
		player = get_parent() as Player


func _physics_process(_delta: float) -> void:
	if player == null:
		_set_interaction_hint_visible(false)
		return
	_refresh_target()
	_update_prompt_transform()


func _unhandled_input(event: InputEvent) -> void:
	if not _is_interact_input(event):
		return
	if player == null:
		return
	if _current_target == null:
		return
	_current_target.interact(player)


func _on_area_entered(area: Area2D) -> void:
	var interactable: Interactable = area as Interactable
	if interactable == null:
		return
	if _interactables.has(interactable):
		return
	_interactables.append(interactable)


func _on_area_exited(area: Area2D) -> void:
	var interactable: Interactable = area as Interactable
	if interactable == null:
		return
	var index: int = _interactables.find(interactable)
	if index == -1:
		return
	_interactables.remove_at(index)


func _refresh_target() -> void:
	_prune_invalid_interactables()

	var nearest: Interactable = null
	var nearest_distance: float = INF
	for interactable in _interactables:
		var distance_to_player: float = player.global_position.distance_to(interactable.global_position)
		if distance_to_player < nearest_distance:
			nearest = interactable
			nearest_distance = distance_to_player

	_current_target = nearest
	_set_interaction_hint_visible(_current_target != null)


func _prune_invalid_interactables() -> void:
	for i in range(_interactables.size() - 1, -1, -1):
		if not is_instance_valid(_interactables[i]):
			_interactables.remove_at(i)


func _set_interaction_hint_visible(is_visible: bool) -> void:
	if _prompt_ui == null:
		return
	if _prompt_ui.visible == is_visible:
		return

	_prompt_ui.visible = is_visible
	if is_visible:
		_prompt_ui.play()
	else:
		_prompt_ui.stop()


func _ensure_prompt_ui() -> void:
	if _prompt_ui != null:
		return

	_prompt_ui = AnimatedSprite2D.new()
	_prompt_ui.name = "InteractionPrompt"
	_prompt_ui.top_level = true
	_prompt_ui.z_index = 100
	_prompt_ui.visible = false

	if prompt_sprite_frames != null:
		_prompt_ui.sprite_frames = prompt_sprite_frames
		var animation_names: PackedStringArray = prompt_sprite_frames.get_animation_names()
		if animation_names.size() > 0:
			_prompt_ui.animation = StringName(animation_names[0])

	add_child(_prompt_ui)


func _update_prompt_transform() -> void:
	if _prompt_ui == null:
		return
	if _current_target == null:
		return
	_prompt_ui.global_position = _get_prompt_global_position(_current_target)


func _get_prompt_global_position(interactable: Interactable) -> Vector2:
	var collision_shape: CollisionShape2D = _find_primary_collision_shape(interactable)
	if collision_shape == null or collision_shape.shape == null:
		return interactable.global_position + Vector2(0.0, -24.0) + interactable.prompt_offset

	var anchor_x: float = collision_shape.global_position.x
	var top_y: float = collision_shape.global_position.y

	if collision_shape.shape is RectangleShape2D:
		var rectangle_shape: RectangleShape2D = collision_shape.shape as RectangleShape2D
		top_y -= rectangle_shape.size.y * 0.5
	elif collision_shape.shape is CircleShape2D:
		var circle_shape: CircleShape2D = collision_shape.shape as CircleShape2D
		top_y -= circle_shape.radius
	elif collision_shape.shape is CapsuleShape2D:
		var capsule_shape: CapsuleShape2D = collision_shape.shape as CapsuleShape2D
		top_y -= capsule_shape.height * 0.5 + capsule_shape.radius

	return Vector2(anchor_x, top_y - prompt_vertical_padding) + interactable.prompt_offset


func _find_primary_collision_shape(interactable: Interactable) -> CollisionShape2D:
	for child: Node in interactable.get_children():
		if child is CollisionShape2D:
			return child as CollisionShape2D

	for child: Node in interactable.get_children():
		if child is PhysicsBody2D:
			for nested: Node in child.get_children():
				if nested is CollisionShape2D:
					return nested as CollisionShape2D

	return null


func _is_interact_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_Fvent: InputEventKey = event as InputEventKey
	if not key_Fvent.pressed:
		return false
	if key_Fvent.echo:
		return false
	return key_Fvent.keycode == KEY_F or key_Fvent.physical_keycode == KEY_F
