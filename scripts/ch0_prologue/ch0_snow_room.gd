extends "res://scripts/scenes/room.gd"

const FIND_WARMTH_FLAG: String = "ch0/find_warmth_started"
const TRAVEL_PAUSE_TOKEN: String = "prologue_travel"

var _presentation_camera: Camera2D = null
var _presentation_x: float = 0.0
var _travel_tween: Tween = null
var _cinematic_running: bool = false

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
	EventBus.dialogue_finished.connect(_on_presentation_dialogue_finished)
	EventBus.room_presented.connect(_on_presentation_room_presented)


func configure_presentation_camera(camera: Camera2D) -> void:
	_presentation_camera = camera
	_fit_camera_height_to_bounds(camera)
	var half_width: float = get_viewport_rect().size.x / camera.zoom.x * 0.5
	if _presentation_x <= 0.0:
		_presentation_x = half_width
		if DataManager.has_flag("ch0/villa_gate_story_seen"):
			_presentation_x = camera_bounds.end.x - half_width
		elif DataManager.has_flag("ch0/villa_gate_interlude_seen"):
			_presentation_x = 2700.0
		elif DataManager.has_flag("ch0/snow_path_interlude_seen"):
			_presentation_x = 1400.0
	camera.position = Vector2(clampf(_presentation_x, half_width, camera_bounds.end.x - half_width), camera_bounds.get_center().y)
	# Keep the original movement triggers inert during the scripted pan.
	for area: Node in find_children("*", "Area2D", true, false):
		if area is Interactable:
			(area as Area2D).input_pickable = false


func _exit_tree() -> void:
	if _travel_tween != null:
		_travel_tween.kill()
	GameManager.release_pause(TRAVEL_PAUSE_TOKEN)
	AudioManager.stop_loop_sfx("prologue_travel_steps")


func _on_presentation_room_presented(room: Node2D, _room_id: String) -> void:
	if room != self or _cinematic_running or Dialogic.current_timeline != null:
		return
	# Resume older saves that were left waiting for a movement trigger.
	if DataManager.has_flag("ch0/villa_gate_story_seen"):
		call_deferred("_continue_presentation", "0_2_villa_gate_story")
	elif DataManager.has_flag("ch0/villa_gate_interlude_seen"):
		call_deferred("_continue_presentation", "0_2_villa_gate_arrival")
	elif DataManager.has_flag("ch0/snow_path_interlude_seen"):
		call_deferred("_continue_presentation", "0_2_snow_path_arrival")
	elif DataManager.has_flag(FIND_WARMTH_FLAG):
		call_deferred("_continue_presentation", "0_2_snow_camp_arrival")


func _on_presentation_dialogue_finished(timeline_name: String) -> void:
	if timeline_name in ["0_2_snow_camp_arrival", "0_2_snow_path_arrival", "0_2_villa_gate_arrival", "0_2_villa_gate_story"]:
		call_deferred("_continue_presentation", timeline_name)


func _continue_presentation(timeline_name: String) -> void:
	if _cinematic_running or _presentation_camera == null or Dialogic.current_timeline != null:
		return
	_cinematic_running = true
	GameManager.request_pause(TRAVEL_PAUSE_TOKEN)
	var next_timeline: String = ""
	match timeline_name:
		"0_2_snow_camp_arrival":
			if not DataManager.has_flag(FIND_WARMTH_FLAG):
				if campfire != null and campfire.has_method("_relight_and_extinguish"):
					await campfire._relight_and_extinguish()
			await _pan_to(1400.0, 4.5)
			DataManager.set_flag("ch0/snow_path_interlude_seen", true)
			next_timeline = "0_2_snow_path_interlude"
		"0_2_snow_path_arrival":
			await _pan_to(2700.0, 6.0)
			DataManager.set_flag("ch0/villa_gate_interlude_seen", true)
			next_timeline = "0_2_villa_gate_interlude"
		"0_2_villa_gate_arrival":
			await _pan_to(camera_bounds.end.x, 3.0)
			DataManager.set_flag("ch0/villa_gate_story_seen", true)
			next_timeline = "0_2_villa_gate_story"
		"0_2_villa_gate_story":
			await get_tree().create_timer(0.4).timeout
			next_timeline = "0_2_villa_door_knock"
	GameManager.release_pause(TRAVEL_PAUSE_TOKEN)
	_cinematic_running = false
	if not next_timeline.is_empty():
		EventBus.dialogue_requested.emit(next_timeline)


func _pan_to(target_x: float, seconds: float) -> void:
	var half_width: float = get_viewport_rect().size.x / _presentation_camera.zoom.x * 0.5
	target_x = clampf(target_x, half_width, camera_bounds.end.x - half_width)
	AudioManager.play_loop_sfx("footsteps", "prologue_travel_steps")
	play_blizzard_flash()
	_travel_tween = create_tween()
	_travel_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_travel_tween.tween_method(_set_presentation_x, _presentation_camera.position.x, target_x, seconds).set_trans(Tween.TRANS_LINEAR)
	await _travel_tween.finished
	_travel_tween = null
	AudioManager.stop_loop_sfx("prologue_travel_steps")
	play_blizzard_flash()


func _set_presentation_x(value: float) -> void:
	_presentation_x = value
	_presentation_camera.position.x = value


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
