extends Node2D

@export var chapter_label: String = "序章"
@export var title_text: String = "悬念：神秘意向的闪回"
@export var finished_event: String = ""
@export var display_seconds: float = 3.2
@export_file("*.tscn") var next_scene_path: String = ""

var room_id: String = "chapter_title"
var default_spawn_point: String = "InitialSpawn"
var _finished: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_title()
	call_deferred("_play_title")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		_finish()


func _build_title() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(background)
	var center := VBoxContainer.new()
	center.set_anchors_preset(Control.PRESET_CENTER)
	center.position = Vector2(-520, -100)
	center.size = Vector2(1040, 200)
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.name = "TitleGroup"
	background.add_child(center)
	var chapter := Label.new()
	chapter.text = chapter_label
	chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	chapter.add_theme_font_size_override("font_size", 34)
	chapter.modulate = Color(1, 1, 1, 0)
	center.add_child(chapter)
	var divider := HSeparator.new()
	divider.custom_minimum_size = Vector2(620, 18)
	divider.modulate = Color(1, 1, 1, 0)
	center.add_child(divider)
	var title := Label.new()
	title.text = title_text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 54)
	title.modulate = Color(1, 1, 1, 0)
	center.add_child(title)
	center.set_meta("chapter", chapter)
	center.set_meta("divider", divider)
	center.set_meta("title", title)


func _play_title() -> void:
	if SceneManager != null and SceneManager.current_player != null:
		SceneManager.current_player.visible = false
	var center := find_child("TitleGroup", true, false) as Control
	if center == null:
		_finish()
		return
	var chapter := center.get_meta("chapter") as CanvasItem
	var divider := center.get_meta("divider") as CanvasItem
	var title := center.get_meta("title") as CanvasItem
	center.scale = Vector2(0.96, 0.96)
	center.pivot_offset = center.size * 0.5
	var tween := create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(chapter, "modulate:a", 1.0, 0.65)
	tween.parallel().tween_property(center, "scale", Vector2.ONE, 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(divider, "modulate:a", 0.72, 0.35)
	tween.tween_property(title, "modulate:a", 1.0, 0.75)
	tween.tween_interval(maxf(0.3, display_seconds - 2.2))
	tween.tween_property(center, "modulate:a", 0.0, 0.7)
	tween.tween_callback(_finish)


func _finish() -> void:
	if _finished:
		return
	_finished = true
	if not finished_event.is_empty():
		EventBus.flow_signal_requested.emit(finished_event)
	elif not next_scene_path.is_empty():
		get_tree().change_scene_to_file(next_scene_path)
