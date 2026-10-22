extends Node

const DEFAULT_DURATION: float = 1.2
const MAX_QUEUED_NOTICES: int = 3
const TOAST_PANEL_SCENE_PATH: String = "res://scenes/UI/toast_panel.tscn"
const TOAST_WIDTH: float = 520.0
const TOAST_RIGHT_MARGIN: float = 16.0
const TOAST_MIN_HEIGHT: float = 96.0
const TOAST_MAX_HEIGHT: float = 180.0
const TOAST_VERTICAL_PADDING: float = 24.0

var _canvas_layer: CanvasLayer = null
var _panel: PanelContainer = null
var _label: Label = null
var _remaining_time: float = 0.0
var _notice_queue: Array[Dictionary] = []
var _is_showing_notice: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	if DataManager != null and not DataManager.ui_notice_requested.is_connected(_on_data_notice_requested):
		DataManager.ui_notice_requested.connect(_on_data_notice_requested)


func _process(delta: float) -> void:
	if _canvas_layer != null:
		var may_show: bool = not FlowManager.is_story_presentation_active()
		_canvas_layer.visible = may_show
		if not may_show:
			return
	if _remaining_time <= 0.0:
		return

	_remaining_time -= delta
	if _remaining_time > 0.0:
		return

	_hide_current()


func show_notice(message: String, notice_type: String = "info", duration: float = DEFAULT_DURATION) -> void:
	if message.strip_edges().is_empty():
		return
	if FlowManager.get_current_chapter_id() == "ch0_prologue":
		return

	var payload: Dictionary = {
		"message": message,
		"notice_type": notice_type,
		"duration": duration,
	}
	if _is_showing_notice:
		_enqueue(payload)
		return
	_display(payload)


func _on_data_notice_requested(message: String, notice_type: String) -> void:
	show_notice(message, notice_type)


func _create_ui() -> void:
	var toast_scene: PackedScene = load(TOAST_PANEL_SCENE_PATH) as PackedScene
	if toast_scene == null:
		push_error("ToastManager: cannot load toast panel scene: %s" % TOAST_PANEL_SCENE_PATH)
		return

	_canvas_layer = toast_scene.instantiate() as CanvasLayer
	if _canvas_layer == null:
		push_error("ToastManager: toast panel scene root must be CanvasLayer.")
		return

	add_child(_canvas_layer)

	_panel = _canvas_layer.get_node_or_null("ToastRoot/ToastPanel") as PanelContainer
	_label = _canvas_layer.get_node_or_null("ToastRoot/ToastPanel/Margin/Message") as Label
	if _panel == null or _label == null:
		push_error("ToastManager: toast panel scene is missing ToastPanel or Message node.")
		return
	var book: Script = load("res://scripts/UI/casebook_style.gd")
	book.decorate(_panel)
	_panel.add_theme_stylebox_override("panel", book.cut_style("name"))
	_panel.anchor_top = 0.035
	_panel.anchor_bottom = 0.035
	_label.add_theme_color_override("font_color", book.INK)
	var settings := LabelSettings.new()
	settings.font = book.reading_font()
	settings.font_size = 26
	settings.font_color = book.INK
	_label.label_settings = settings
	get_viewport().size_changed.connect(_on_viewport_resized)

func _on_viewport_resized() -> void:
	if _is_showing_notice: _resize_panel_to_message()


func _display(payload: Dictionary) -> void:
	if _panel == null or _label == null:
		return

	_label.text = String(payload.get("message", ""))
	_resize_panel_to_message()
	_panel.visible = true
	_remaining_time = max(0.2, float(payload.get("duration", DEFAULT_DURATION)))
	_is_showing_notice = true
	_canvas_layer.visible = not FlowManager.is_story_presentation_active()
	if _canvas_layer.visible:
		_play_toast_sfx()


func _hide_current() -> void:
	_remaining_time = 0.0
	_is_showing_notice = false
	if _panel != null:
		_panel.visible = false
	_show_next_queued()


func _enqueue(payload: Dictionary) -> void:
	while _notice_queue.size() >= MAX_QUEUED_NOTICES:
		_notice_queue.remove_at(0)
	_notice_queue.append(payload)


func _show_next_queued() -> void:
	if _notice_queue.is_empty():
		return
	var next_payload: Dictionary = _notice_queue.pop_front()
	_display(next_payload)


func _play_toast_sfx() -> void:
	if AudioManager == null:
		return
	if not AudioManager.has_method("play_sfx"):
		return
	AudioManager.play_sfx("toast")


func _resize_panel_to_message() -> void:
	if _panel == null or _label == null:
		return
	var view_width := get_viewport().get_visible_rect().size.x
	var width := clampf(view_width * 0.29, 340.0, TOAST_WIDTH)
	_panel.custom_minimum_size.x = width
	_label.custom_minimum_size.x = width - 96.0
	if _label.label_settings != null:
		_label.label_settings.font_size = 22 if view_width < 1500 else 26

	var text_height: float = _label.get_theme_font("font").get_multiline_string_size(
		_label.text,
		HORIZONTAL_ALIGNMENT_LEFT,
		_label.custom_minimum_size.x,
		_label.get_theme_font_size("font_size")
	).y
	var panel_height: float = clampf(text_height + TOAST_VERTICAL_PADDING, TOAST_MIN_HEIGHT, TOAST_MAX_HEIGHT)

	_panel.offset_left = -width - TOAST_RIGHT_MARGIN
	_panel.offset_right = -TOAST_RIGHT_MARGIN
	_panel.offset_bottom = panel_height
