extends RefCounted

const TEXT := Color("302e2b")
const MUTED := Color("81786c")
const ACCENT := Color("87443e")
const BOOK = preload("res://scripts/UI/casebook_style.gd")
const DIALOGUE_PANEL = preload("res://assets/UI/dialogues/VisualNovelTextbox/dialogue_box_panel.tres")
const NAME_PANEL = preload("res://assets/UI/dialogues/VisualNovelTextbox/name_label_panel.tres")
const FONT = preload("res://assets/UI/Nightgazer16.ttf")


static func apply(panel: CanvasLayer, reasoning: bool) -> void:
	_apply_structure(panel, reasoning)
	var host: Control = panel.get_node("PanelRoot") as Control
	host.theme = BOOK.theme()
	(panel.get_node("Dimmer") as ColorRect).color = Color(0.025, 0.025, 0.03, 0.58)
	var frame: PanelContainer = host.get_node("PanelFrame") as PanelContainer
	BOOK.decorate(frame, true)
	var title: Label = host.find_child("HeaderTitle", true, false) as Label
	title.text = "调查手册"
	title.add_theme_font_override("font", BOOK.display_font(750))
	title.add_theme_font_size_override("font_size", 34)
	var split: HSplitContainer = host.find_child("BodySplit", true, false) as HSplitContainer
	split.split_offset = 850 if reasoning else 700
	split.add_theme_constant_override("separation", 32 if reasoning else 48)
	var left: PanelContainer = split.get_node("LeftPane") as PanelContainer
	left.custom_minimum_size.x = 850 if reasoning else 700
	left.add_theme_stylebox_override("panel", BOOK.surface(Color.TRANSPARENT, 18))
	var right: PanelContainer = split.get_node("RightPane") as PanelContainer
	var right_style := BOOK.surface(Color.TRANSPARENT, 18)
	right_style.content_margin_left = 48 if reasoning else 84
	right_style.content_margin_right = 26
	right.add_theme_stylebox_override("panel", right_style)
	var detail: Label = host.find_child("DetailTitle", true, false) as Label
	detail.add_theme_font_override("font", BOOK.display_font(650))
	detail.add_theme_font_size_override("font_size", 31)
	if reasoning:
		var section: PanelContainer = host.find_child("ReasoningPanel", true, false) as PanelContainer
		section.add_theme_stylebox_override("panel", BOOK.surface(Color(1, 1, 1, 0.16), 16, BOOK.RULE))
		(host.find_child("ReasoningTitle", true, false) as Label).text = "关联证据"
		(host.find_child("ReasonButton", true, false) as Button).text = "确认推理"
	var tabs: Node = host.find_child("ArchiveTabs", true, false)
	(tabs.get_child(0) as Button).text = "线索"
	(tabs.get_child(1) as Button).text = preload("res://scripts/UI/casebook_cases.gd").reasoning_title()
	for control: Node in host.find_children("*", "LineEdit", true, false):
		(control as LineEdit).remove_theme_stylebox_override("normal")
		(control as LineEdit).remove_theme_stylebox_override("focus")


static func _apply_structure(panel: CanvasLayer, reasoning: bool) -> void:
	var host: Control = panel.get_node("PanelRoot") as Control
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 24
	for type_name: String in ["Label", "Button", "OptionButton", "LineEdit", "Tree", "PopupMenu"]:
		theme.set_color("font_color", type_name, TEXT)
		theme.set_color("font_hover_color", type_name, Color.WHITE)
		theme.set_color("font_focus_color", type_name, TEXT)
		theme.set_color("font_pressed_color", type_name, ACCENT)
		theme.set_color("font_disabled_color", type_name, Color("99968f"))
	theme.set_color("default_color", "RichTextLabel", TEXT)
	theme.set_font_size("normal_font_size", "RichTextLabel", 26)
	theme.set_font_size("bold_font_size", "RichTextLabel", 26)
	theme.set_constant("line_separation", "RichTextLabel", 9)
	theme.set_constant("v_separation", "Tree", 14)
	theme.set_constant("h_separation", "Tree", 12)
	theme.set_constant("inner_item_margin_left", "Tree", 12)
	theme.set_color("font_selected_color", "Tree", Color.WHITE)
	theme.set_color("guide_color", "Tree", Color(0.8, 0.77, 0.69, 0.12))
	theme.set_stylebox("panel", "Tree", _surface(Color(0.08, 0.09, 0.1, 0.12), 12))
	theme.set_stylebox("selected", "Tree", _surface(Color(0.75, 0.64, 0.44, 0.22), 8, ACCENT))
	theme.set_stylebox("selected_focus", "Tree", theme.get_stylebox("selected", "Tree"))
	theme.set_stylebox("panel", "PopupMenu", _surface(Color("313638"), 16, MUTED))
	theme.set_stylebox("hover", "PopupMenu", _surface(Color(0.75, 0.64, 0.44, 0.22), 8))
	for button_type: String in ["Button", "OptionButton"]:
		theme.set_stylebox("normal", button_type, _name_style(Color(1, 1, 1, 0.8)))
		theme.set_stylebox("hover", button_type, _surface(Color("535551"), 14, ACCENT))
		theme.set_stylebox("pressed", button_type, _surface(Color("333634"), 14, ACCENT))
		theme.set_stylebox("disabled", button_type, _surface(Color(0.12, 0.14, 0.15, 0.28), 14))
		theme.set_stylebox("focus", button_type, _surface(Color.TRANSPARENT, 0, ACCENT))
	theme.set_stylebox("normal", "LineEdit", _surface(Color(0.1, 0.12, 0.13, 0.4), 12, Color(0.8, 0.77, 0.69, 0.3)))
	theme.set_stylebox("focus", "LineEdit", _surface(Color(0.1, 0.12, 0.13, 0.6), 12, ACCENT))
	theme.set_color("font_placeholder_color", "LineEdit", MUTED)
	var line := StyleBoxLine.new()
	line.color = Color(0.82, 0.77, 0.65, 0.28)
	line.thickness = 1
	theme.set_stylebox("separator", "HSeparator", line)
	host.theme = theme
	(panel.get_node("Dimmer") as ColorRect).color = Color(0.02, 0.03, 0.04, 0.5)
	var frame: PanelContainer = host.get_node("PanelFrame") as PanelContainer
	var frame_style: StyleBoxTexture = DIALOGUE_PANEL.duplicate() as StyleBoxTexture
	frame_style.content_margin_left = 20
	frame_style.content_margin_right = 20
	frame_style.content_margin_top = 38
	frame_style.content_margin_bottom = 20
	frame_style.modulate_color = Color(0.8, 0.83, 0.83, 0.96)
	frame.add_theme_stylebox_override("panel", frame_style)
	var title: Label = host.find_child("HeaderTitle", true, false) as Label
	title.text = "推理手册"
	title.add_theme_font_size_override("font_size", 36)
	var bold := FontVariation.new()
	bold.base_font = FONT
	bold.variation_embolden = 0.6
	title.add_theme_font_override("font", bold)
	var close: Button = host.find_child("CloseButton", true, false) as Button
	close.text = "关闭"
	close.custom_minimum_size = Vector2(96, 48)
	var header: HBoxContainer = title.get_parent() as HBoxContainer
	header.add_theme_constant_override("separation", 16)
	(host.find_child("ModeLabel", true, false) as Label).hide()
	var tabs := HBoxContainer.new()
	tabs.name = "ArchiveTabs"
	tabs.add_theme_constant_override("separation", 8)
	header.add_child(tabs)
	header.move_child(tabs, 1)
	for is_reasoning: bool in [false, true]:
		var tab := Button.new()
		tab.text = "疑点" if is_reasoning else "线索"
		tab.custom_minimum_size = Vector2(112, 48)
		tab.toggle_mode = true
		tab.button_pressed = is_reasoning == reasoning
		tab.pressed.connect(_open_manual.bind(panel, is_reasoning))
		tabs.add_child(tab)
	var split: HSplitContainer = host.find_child("BodySplit", true, false) as HSplitContainer
	split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN_COLLAPSED
	split.split_offset = 390
	var left: PanelContainer = split.get_node("LeftPane") as PanelContainer
	left.custom_minimum_size.x = 390
	left.add_theme_stylebox_override("panel", _surface(Color(0.08, 0.1, 0.11, 0.32), 16))
	var right: PanelContainer = split.get_node("RightPane") as PanelContainer
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_stylebox_override("panel", _surface(Color(0.08, 0.1, 0.11, 0.18), 24))
	for node: Node in host.find_children("*", "VBoxContainer", true, false):
		(node as VBoxContainer).add_theme_constant_override("separation", 16)
	var search: LineEdit = host.find_child("SearchLineEdit", true, false) as LineEdit
	search.custom_minimum_size.y = 48
	search.placeholder_text = "搜索"
	var sort: OptionButton = host.find_child("SortOptionButton", true, false) as OptionButton
	sort.custom_minimum_size.x = 140
	sort.add_theme_font_size_override("font_size", 21)
	var detail_title: Label = host.find_child("DetailTitle", true, false) as Label
	detail_title.add_theme_font_size_override("font_size", 32)
	detail_title.add_theme_font_override("font", bold)
	detail_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if reasoning:
		var reasoning_panel: PanelContainer = host.find_child("ReasoningPanel", true, false) as PanelContainer
		reasoning_panel.add_theme_stylebox_override("panel", _surface(Color(0.09, 0.1, 0.11, 0.45), 18))
		(host.find_child("ReasoningTitle", true, false) as Label).text = "关联线索"
		var slots: HFlowContainer = host.find_child("SlotRow", true, false) as HFlowContainer
		slots.add_theme_constant_override("h_separation", 12)
		slots.add_theme_constant_override("v_separation", 12)
		for slot: Node in slots.get_children():
			style_slot(slot as Button)
		(host.find_child("ReasonButton", true, false) as Button).custom_minimum_size.y = 52
	else:
		(host.find_child("SelectClueButton", true, false) as Button).custom_minimum_size.y = 52


static func style_slot(button: Button) -> void:
	button.custom_minimum_size = Vector2(180, 80)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 23)
	BOOK.style_ribbon(button)


static func set_tabs_enabled(panel: CanvasLayer, enabled: bool) -> void:
	var tabs: Node = panel.find_child("ArchiveTabs", true, false)
	if tabs != null:
		for tab: Node in tabs.get_children():
			(tab as Button).disabled = not enabled
		(tabs.get_child(1) as Button).text = preload("res://scripts/UI/casebook_cases.gd").reasoning_title()


static func _open_manual(panel: CanvasLayer, reasoning: bool) -> void:
	var target: Node = panel.get_tree().current_scene.get_node_or_null("SuspicionPanel" if reasoning else "CluePanel")
	if target != null:
		target.call("_open_archive_panel")


static func _name_style(tint: Color) -> StyleBoxTexture:
	var style: StyleBoxTexture = NAME_PANEL.duplicate() as StyleBoxTexture
	style.modulate_color = tint
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style


static func _surface(color: Color, padding: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_content_margin_all(padding)
	return style
