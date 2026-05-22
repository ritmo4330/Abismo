extends Node

const DEFAULT_DURATION: float = 3.0
const CANVAS_LAYER: int = 150
const PANEL_SIZE: Vector2 = Vector2(520.0, 72.0)

var _canvas_layer: CanvasLayer = null
var _panel: PanelContainer = null
var _label: Label = null
var _remaining_time: float = 0.0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_ui()
	if DataManager != null and not DataManager.ui_notice_requested.is_connected(_on_data_notice_requested):
		DataManager.ui_notice_requested.connect(_on_data_notice_requested)


func _process(delta: float) -> void:
	if _remaining_time <= 0.0:
		return

	_remaining_time -= delta
	if _remaining_time > 0.0:
		return

	_hide_current()


func show_notice(message: String, notice_type: String = "info", duration: float = DEFAULT_DURATION) -> void:
	if message.strip_edges().is_empty():
		return

	var payload: Dictionary = {
		"message": message,
		"notice_type": notice_type,
		"duration": duration,
	}
	_display(payload)


func _on_data_notice_requested(message: String, notice_type: String) -> void:
	show_notice(message, notice_type)


func _create_ui() -> void:
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.name = "ToastCanvas"
	_canvas_layer.layer = CANVAS_LAYER
	_canvas_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_canvas_layer)

	_panel = PanelContainer.new()
	_panel.name = "ToastPanel"
	_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.custom_minimum_size = PANEL_SIZE
	_canvas_layer.add_child(_panel)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.08, 0.88)
	style.border_color = Color(0.78, 0.84, 0.9, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	_panel.add_theme_stylebox_override("panel", style)

	var margin: MarginContainer = MarginContainer.new()
	margin.name = "Margin"
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 12)
	_panel.add_child(margin)

	_label = Label.new()
	_label.name = "Message"
	_label.process_mode = Node.PROCESS_MODE_ALWAYS
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.text = ""
	margin.add_child(_label)

	call_deferred("_position_panel")


func _position_panel() -> void:
	if _panel == null:
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	_panel.size = PANEL_SIZE
	_panel.position = Vector2(
		max(24.0, viewport_size.x - PANEL_SIZE.x - 64.0),
		max(24.0, viewport_size.y * 0.32)
	)


func _display(payload: Dictionary) -> void:
	if _panel == null or _label == null:
		return

	_position_panel()
	_label.text = String(payload.get("message", ""))
	_panel.visible = true
	_remaining_time = max(0.2, float(payload.get("duration", DEFAULT_DURATION)))


func _hide_current() -> void:
	_remaining_time = 0.0
	if _panel != null:
		_panel.visible = false
