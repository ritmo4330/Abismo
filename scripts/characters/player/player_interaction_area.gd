class_name PlayerInteractionArea
extends Area2D

@export var player: Player
@export var interaction_hint: CanvasItem

var _interactables: Array[Interactable] = []
var _current_target: Interactable = null


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)
	_set_interaction_hint_visible(false)

	if player == null:
		player = get_parent() as Player


func _physics_process(_delta: float) -> void:
	if player == null:
		_set_interaction_hint_visible(false)
		return
	_refresh_target()


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
	if interaction_hint != null:
		interaction_hint.visible = is_visible


func _is_interact_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	return key_event.keycode == KEY_F or key_event.physical_keycode == KEY_F
