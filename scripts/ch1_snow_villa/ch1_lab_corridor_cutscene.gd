extends Node2D

const FlowEvents = preload("res://scripts/flow/flow_events.gd")

@export var room_id: String = "lab_corridor_cutscene"
@export var default_spawn_point: String = "InitialSpawn"
@export var travel_seconds: float = 5.5
@export var camera_bounds: Rect2 = Rect2(0, 0, 1920, 1080)

var _finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_corridor()
	EventBus.room_presented.connect(_on_room_presented)
	if not SceneManager.is_initialized():
		call_deferred("_start_walk")


func _on_room_presented(room: Node2D, _room_id: String) -> void:
	if room == self:
		_start_walk()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and (event.keycode == KEY_F or event.physical_keycode == KEY_F)):
		_finish()


func _build_corridor() -> void:
	var layer := CanvasLayer.new()
	layer.layer = -5
	add_child(layer)
	var art_path := "res://assets/art/static_scenes/lab_corridor-v1.png"
	if ResourceLoader.exists(art_path):
		var painting := TextureRect.new()
		painting.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		painting.texture = load(art_path) as Texture2D
		painting.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		painting.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		painting.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(painting)
		return
	var bg := ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("05080d")
	layer.add_child(bg)
	for i in range(7):
		var panel := ColorRect.new()
		panel.position = Vector2(95 + i * 285, 120)
		panel.size = Vector2(190, 720)
		panel.color = Color("0b1119") if i % 2 == 0 else Color("080d13")
		bg.add_child(panel)
		var light := PointLight2D.new()
		light.position = Vector2(190 + i * 285, 210)
		light.energy = 0.48
		light.texture_scale = 2.8
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(0.68, 0.79, 0.75, 0.68), Color(0.14, 0.22, 0.24, 0.0)])
		var texture := GradientTexture2D.new()
		texture.gradient = gradient
		texture.width = 160
		texture.height = 160
		texture.fill = GradientTexture2D.FILL_RADIAL
		light.texture = texture
		add_child(light)
	var floor_shadow := ColorRect.new()
	floor_shadow.position = Vector2(0, 770)
	floor_shadow.size = Vector2(1920, 310)
	floor_shadow.color = Color("020305")
	bg.add_child(floor_shadow)


func _start_walk() -> void:
	var player := SceneManager.current_player if SceneManager != null else null
	if player == null:
		_finish()
		return
	player.visible = true
	player.process_mode = Node.PROCESS_MODE_INHERIT
	player.set_process(false)
	player.set_physics_process(false)
	player.global_position = Vector2(1760, 760)
	player.scale = Vector2(1.15, 1.15)
	if player.has_method("play_animation"):
		player.play_animation("walk_left")
	elif player.has_node("AnimatedSprite2D"):
		var sprite := player.get_node("AnimatedSprite2D") as AnimatedSprite2D
		if sprite.sprite_frames.has_animation("walk_left"):
			sprite.play("walk_left")
	if AudioManager != null:
		AudioManager.play_loop_sfx("footsteps", "lab_corridor_steps")
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(player, "global_position:x", 175.0, travel_seconds).set_trans(Tween.TRANS_LINEAR)
	tween.tween_callback(_finish)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if AudioManager != null:
		AudioManager.stop_loop_sfx("lab_corridor_steps")
	EventBus.flow_signal_requested.emit(FlowEvents.LAB_CORRIDOR_FINISHED)
