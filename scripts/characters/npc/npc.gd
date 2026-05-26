class_name NpcDialogue
extends Interactable

const NPC_PIXEL_ROOT: String = "res://assets/characters/npcs"
const NPC_PIXEL_PREFIX: String = "pixel_"
const NPC_PIXEL_EXTENSION: String = "png"
const VISUAL_ID_ALIASES: Dictionary = {
	"zhou_chong_an": "zhou",
	"mu_zhi": "mu",
	"lin_jiu": "lin",
	"wu_ting_xiang": "wu",
	"zhong_qi": "zhong",
}

@export var npc_id: String = ""
@export var npc_name: String = ""
@export var timeline_name: String = ""
@export var visual_id: String = ""
@export var visual_target_height: float = 80.0
@export var visual_offset: Vector2 = Vector2.ZERO

@onready var visual: Sprite2D = $Visual


func _ready() -> void:
	super._ready()
	_apply_visual()


func interact(_player: Player) -> void:
	if timeline_name.is_empty():
		push_warning("NpcDialogue.timeline_name is empty for npc: %s" % _get_debug_name())
		return

	EventBus.dialogue_requested.emit(timeline_name)


func _apply_visual() -> void:
	if visual == null:
		return

	var texture_path: String = _get_visual_texture_path()
	if texture_path.is_empty():
		visual.visible = false
		return

	var texture: Texture2D = load(texture_path) as Texture2D
	if texture == null:
		push_warning("NpcDialogue: unable to load visual '%s' for npc: %s" % [texture_path, _get_debug_name()])
		visual.visible = false
		return

	visual.texture = texture
	visual.visible = true
	visual.centered = true
	visual.position = visual_offset + Vector2(0.0, -visual_target_height * 0.5)

	var texture_size: Vector2 = texture.get_size()
	if texture_size.y <= 0.0:
		visual.scale = Vector2.ONE
		return
	var scale_factor: float = visual_target_height / texture_size.y
	visual.scale = Vector2.ONE * scale_factor


func _get_visual_texture_path() -> String:
	var resolved_visual_id: String = _resolve_visual_id()
	if resolved_visual_id.is_empty():
		return ""

	var texture_path: String = "%s/%s%s.%s" % [
		NPC_PIXEL_ROOT,
		NPC_PIXEL_PREFIX,
		resolved_visual_id,
		NPC_PIXEL_EXTENSION,
	]
	if ResourceLoader.exists(texture_path):
		return texture_path

	push_warning("NpcDialogue: missing pixel visual '%s' for npc: %s" % [texture_path, _get_debug_name()])
	return ""


func _resolve_visual_id() -> String:
	var resolved_visual_id: String = visual_id
	if resolved_visual_id.is_empty():
		resolved_visual_id = npc_id
	if VISUAL_ID_ALIASES.has(resolved_visual_id):
		return String(VISUAL_ID_ALIASES[resolved_visual_id])
	return resolved_visual_id


func _get_debug_name() -> String:
	if not npc_name.is_empty():
		return npc_name
	if not npc_id.is_empty():
		return npc_id
	return name
