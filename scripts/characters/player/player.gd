extends CharacterBody2D
class_name Player

# 可在编辑器调整的参数
#@export var move_speed: float = 400.0
# 去Walk节点调整
@export var visual_target_height: float = 80.0

# 玩家物理与动作向的本地状态（因为玩家节点已常驻，不再需要依赖外部单例在切换地图时来回存取）
var player_direction: Vector2 = Vector2.DOWN

@onready var visual: AnimatedSprite2D = $AnimatedSprite2D
@onready var body_collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var walk_state: Node = $StateMachine/Walk

var _room_scale: Vector2 = Vector2.ONE
var _room_speed_scale: float = 1.0
var _body_collision_base_scale: Vector2 = Vector2.ONE
var _interaction_area_base_scale: Vector2 = Vector2.ONE
var _base_walk_speed: float = 0.0
var _has_cached_base_scales: bool = false
var _has_cached_walk_speed: bool = false


func _ready() -> void:
	_cache_base_scales()
	_cache_base_walk_speed()
	_apply_part_scales()
	_apply_walk_speed()


func apply_room_scale(room_scale: Vector2) -> void:
	_room_scale = room_scale
	scale = Vector2.ONE
	_cache_base_scales()
	_apply_part_scales()


func apply_room_speed_scale(room_speed_scale: float) -> void:
	_room_speed_scale = maxf(room_speed_scale, 0.0)
	_cache_base_walk_speed()
	_apply_walk_speed()


func _cache_base_scales() -> void:
	if _has_cached_base_scales:
		return

	var collision_node: CollisionShape2D = _get_body_collision()
	if collision_node != null:
		_body_collision_base_scale = collision_node.scale

	var interaction_node: Area2D = _get_interaction_area()
	if interaction_node != null:
		_interaction_area_base_scale = interaction_node.scale

	_has_cached_base_scales = true


func _cache_base_walk_speed() -> void:
	if _has_cached_walk_speed:
		return

	var walk_node: Node = _get_walk_state()
	if walk_node == null:
		return

	var speed_value: Variant = walk_node.get("speed")
	if speed_value == null:
		return

	_base_walk_speed = float(speed_value)
	_has_cached_walk_speed = true


func _apply_part_scales() -> void:
	var visual_scale_factor: float = _get_visual_scale_factor()
	var effective_scale: Vector2 = Vector2.ONE * visual_scale_factor * _room_scale
	_apply_visual_scale(effective_scale)

	var collision_node: CollisionShape2D = _get_body_collision()
	if collision_node != null:
		collision_node.scale = _body_collision_base_scale * effective_scale

	var interaction_node: Area2D = _get_interaction_area()
	if interaction_node != null:
		interaction_node.scale = _interaction_area_base_scale * effective_scale


func _apply_visual_scale(effective_scale: Vector2) -> void:
	var visual_node: AnimatedSprite2D = _get_visual()
	if visual_node == null:
		return

	visual_node.scale = effective_scale


func _apply_walk_speed() -> void:
	if not _has_cached_walk_speed:
		return

	var walk_node: Node = _get_walk_state()
	if walk_node == null:
		return

	walk_node.set("speed", _base_walk_speed * _room_speed_scale)


func _get_visual_scale_factor() -> float:
	var visual_node: AnimatedSprite2D = _get_visual()
	if visual_node == null:
		return 1.0

	var texture: Texture2D = _get_visual_texture(visual_node)
	if texture == null:
		return 1.0

	var texture_size: Vector2 = texture.get_size()
	if texture_size.y <= 0.0:
		return 1.0

	return visual_target_height / texture_size.y


func _get_visual() -> AnimatedSprite2D:
	if visual == null:
		visual = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	return visual


func _get_body_collision() -> CollisionShape2D:
	if body_collision == null:
		body_collision = get_node_or_null("CollisionShape2D") as CollisionShape2D
	return body_collision


func _get_interaction_area() -> Area2D:
	if interaction_area == null:
		interaction_area = get_node_or_null("InteractionArea") as Area2D
	return interaction_area


func _get_walk_state() -> Node:
	if walk_state == null:
		walk_state = get_node_or_null("StateMachine/Walk")
	return walk_state


func _get_visual_texture(visual_node: AnimatedSprite2D) -> Texture2D:
	if visual_node.sprite_frames == null:
		return null

	var animation_name: StringName = visual_node.animation
	if not visual_node.sprite_frames.has_animation(animation_name):
		var animation_names: PackedStringArray = visual_node.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			return null
		animation_name = animation_names[0]

	if visual_node.sprite_frames.get_frame_count(animation_name) <= 0:
		return null
	return visual_node.sprite_frames.get_frame_texture(animation_name, 0)
