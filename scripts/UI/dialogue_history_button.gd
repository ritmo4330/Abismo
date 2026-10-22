extends Button


func _ready() -> void:
	flat = false
	focus_mode = Control.FOCUS_NONE
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var style: StyleBoxTexture = load("res://assets/UI/dialogues/VisualNovelTextbox/name_label_panel.tres").duplicate() as StyleBoxTexture
	style.content_margin_left = 3
	style.content_margin_right = 3
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	add_theme_stylebox_override("normal", style)
	var hover: StyleBoxTexture = style.duplicate() as StyleBoxTexture
	hover.modulate_color = Color(1.15, 1.12, 1.04, 1)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", style)
	var name_panel: Control = get_parent().get_node("NameLabelPanel") as Control
	name_panel.item_rect_changed.connect(sync_geometry)
	get_parent().resized.connect(sync_geometry)
	call_deferred("sync_geometry")


func sync_geometry() -> void:
	var holder: Control = get_parent() as Control
	var name_panel: Control = holder.get_node("NameLabelPanel") as Control
	var dialogue_panel: PanelContainer = holder.get_parent() as PanelContainer
	var side: float = maxf(name_panel.size.y, 42.0)
	var margin_right: float = dialogue_panel.get_theme_stylebox("panel").get_content_margin(SIDE_RIGHT)
	add_theme_constant_override("icon_max_width", roundi(side * 0.55))
	size = Vector2(side, side)
	position = Vector2(holder.size.x + margin_right - side, name_panel.position.y)
