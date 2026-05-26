extends "res://scripts/scenes/room.gd"

@onready var blizzard_flash: ColorRect = find_child("BlizzardFlash", true, false) as ColorRect


func _ready() -> void:
	super._ready()
	if blizzard_flash != null:
		blizzard_flash.visible = false
		blizzard_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE


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
