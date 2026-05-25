@tool
extends "res://assets/UI/dialogues/VisualNovelTextbox/vn_textbox_layer.gd"

@export_group("Plain Text")
@export var box_center_offset: Vector2 = Vector2.ZERO
@export var text_content_width: float = 1000.0


func _apply_box_settings() -> void:
	var dialog_text_panel: PanelContainer = %DialogTextPanel
	if ResourceLoader.exists(box_panel):
		dialog_text_panel.add_theme_stylebox_override(&"panel", load(box_panel) as StyleBox)

	if box_color_use_global:
		dialog_text_panel.self_modulate = get_global_setting(&"bg_color", box_color_custom)
	else:
		dialog_text_panel.self_modulate = box_color_custom

	var sizer: Control = %Sizer
	sizer.size = box_size
	sizer.position = box_size * -0.5 + box_center_offset


func _apply_text_settings() -> void:
	super._apply_text_settings()

	var dialog_text: RichTextLabel = %DialogicNode_DialogText
	dialog_text.fit_content = true
	dialog_text.scroll_active = false
	dialog_text.custom_minimum_size = Vector2(_get_text_width(), 0.0)


func _get_text_width() -> float:
	var available_width: float = box_size.x
	var dialog_text_panel: PanelContainer = %DialogTextPanel
	var stylebox: StyleBox = dialog_text_panel.get_theme_stylebox(&"panel", &"PanelContainer")
	if stylebox != null:
		available_width -= stylebox.content_margin_left + stylebox.content_margin_right

	if text_content_width <= 0.0:
		return maxf(1.0, available_width)
	return maxf(1.0, minf(text_content_width, available_width))
