extends "res://scripts/scenes/room.gd"

const FIND_WARMTH_FLAG: String = "ch0/find_warmth_started"

@onready var lit_background: Sprite2D = find_child("LitBackground", true, false) as Sprite2D
@onready var extinguished_background: Sprite2D = find_child("ExtinguishedBackground", true, false) as Sprite2D
@onready var blizzard_flash: ColorRect = find_child("BlizzardFlash", true, false) as ColorRect
@onready var campfire: Node = find_child("Campfire", true, false)


func _ready() -> void:
	super._ready()
	_sync_campfire_visuals()
	if blizzard_flash != null:
		blizzard_flash.visible = false
		blizzard_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_campfire_lit(is_lit: bool) -> void:
	if campfire != null and campfire.has_method("set_lit"):
		campfire.set_lit(is_lit)
		return
	set_campfire_visual_lit(is_lit)


func set_campfire_visual_lit(is_lit: bool) -> void:
	if lit_background != null:
		lit_background.visible = is_lit
	if extinguished_background != null:
		extinguished_background.visible = not is_lit


func _sync_campfire_visuals() -> void:
	var should_start_lit: bool = true
	if campfire != null:
		var starts_lit_value: Variant = campfire.get("starts_lit")
		if starts_lit_value != null:
			should_start_lit = bool(starts_lit_value)
	if DataManager != null and DataManager.has_flag(FIND_WARMTH_FLAG):
		should_start_lit = false
	set_campfire_visual_lit(should_start_lit)


func play_blizzard_flash() -> void:
	if blizzard_flash == null:
		return

	blizzard_flash.visible = true
	blizzard_flash.modulate = Color(1, 1, 1, 0.0)
	var tween: Tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(blizzard_flash, "modulate", Color(1, 1, 1, 0.55), 0.12)
	tween.tween_property(blizzard_flash, "modulate", Color(1, 1, 1, 0.0), 0.45)
	tween.tween_callback(func() -> void:
		if blizzard_flash != null:
			blizzard_flash.visible = false
	)


func setup_camera_limits(player: Node2D) -> void:
	if camera_bounds.size.x <= 0.0 or camera_bounds.size.y <= 0.0:
		super.setup_camera_limits(player)
		return

	var camera: Camera2D = player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return
	_fit_camera_height_to_bounds(camera)

	camera.limit_left = int(round(camera_bounds.position.x))
	camera.limit_top = int(round(camera_bounds.position.y))
	camera.limit_right = int(round(camera_bounds.end.x))
	camera.limit_bottom = int(round(camera_bounds.end.y))


func _fit_camera_height_to_bounds(camera: Camera2D) -> void:
	var viewport_height: float = get_viewport_rect().size.y
	if viewport_height <= 0.0 or camera_bounds.size.y <= 0.0:
		return

	var target_zoom: float = viewport_height / camera_bounds.size.y
	camera.zoom = Vector2(target_zoom, target_zoom)
