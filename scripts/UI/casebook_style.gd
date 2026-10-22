extends RefCounted

const FONT = preload("res://assets/art/casebook/ZhuqueFangsong-Regular.ttf")
const FALLBACK_FONT = preload("res://assets/art/casebook/NotoSerifSC-Variable.ttf")
const TITLE_FONT = FONT
const MATERIAL = preload("res://scripts/UI/casebook_material.gd")
const INK := Color("302820")
const MUTED := Color("6b5947")
const RED := Color("87443e")
const PAPER := Color("eee7d9")
const RULE := Color("b8ac96")
const ART_ROOT := "res://assets/art/casebook/"
static var _reading_font: FontVariation
static var _display_fonts: Dictionary = {}

# Keep text live and searchable; use real print letterforms, not textured glyphs.
static func reading_font() -> FontVariation:
	if _reading_font == null:
		_reading_font = FontVariation.new()
		_reading_font.base_font = FONT
		_reading_font.fallbacks = [FALLBACK_FONT]
		_reading_font.variation_embolden = 0.32
	return _reading_font

static func paper_style(book: bool = false, newspaper: bool = false) -> StyleBox:
	var style := MATERIAL.new()
	style.scan = load(ART_ROOT + "paper-scan-810-cc0.jpg")
	style.kind = "book" if book else ("newspaper" if newspaper else "sheet")
	style.content_margin_left = 54 if book else 32
	style.content_margin_right = 54 if book else 32
	style.content_margin_top = 48 if book else (38 if newspaper else 24)
	style.content_margin_bottom = 64 if book else (30 if newspaper else 24)
	return style

static func cut_style(kind: String) -> StyleBox:
	var style := MATERIAL.new()
	style.scan = load(ART_ROOT + "paper-scan-810-cc0.jpg")
	style.kind = kind
	style.content_margin_left = 24
	style.content_margin_right = 32
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	return style

static func ribbon_style(highlight: bool = false) -> StyleBox:
	var style := MATERIAL.new()
	style.scan = load(ART_ROOT + "paper-scan-810-cc0.jpg")
	style.kind = "ribbon"
	style.tint = Color(1.12, 1.06, 0.94) if highlight else Color(1.14, 1.12, 1.05)
	style.set_content_margin_all(14)
	return style

static func style_ribbon(button: Button) -> void:
	button.add_theme_stylebox_override("normal", ribbon_style())
	button.add_theme_stylebox_override("hover", ribbon_style(true))
	button.add_theme_stylebox_override("pressed", ribbon_style(true))
	button.add_theme_stylebox_override("disabled", ribbon_style())

static func surface(fill: Color, padding: float = 16, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.set_content_margin_all(padding)
	return style

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font = reading_font()
	result.default_font_size = 25
	for type: String in ["Label", "Button", "OptionButton", "LineEdit", "Tree", "PopupMenu"]:
		result.set_color("font_color", type, INK)
		result.set_color("font_hover_color", type, RED)
		result.set_color("font_pressed_color", type, RED)
		result.set_color("font_focus_color", type, INK)
		result.set_color("font_disabled_color", type, Color("a59c8e"))
	result.set_color("default_color", "RichTextLabel", INK)
	result.set_font("normal_font", "RichTextLabel", reading_font())
	result.set_font("bold_font", "RichTextLabel", display_font(650))
	result.set_font("italics_font", "RichTextLabel", reading_font())
	result.set_font("bold_italics_font", "RichTextLabel", display_font(650))
	for type: String in ["Label", "Button", "OptionButton", "LineEdit", "Tree"]:
		result.set_color("font_shadow_color", type, Color.TRANSPARENT)
		result.set_color("font_outline_color", type, Color.TRANSPARENT)
		result.set_constant("outline_size", type, 0)
	result.set_font_size("normal_font_size", "RichTextLabel", 27)
	result.set_font_size("bold_font_size", "RichTextLabel", 27)
	result.set_constant("line_separation", "RichTextLabel", 10)
	for type: String in ["Button", "OptionButton"]:
		result.set_stylebox("normal", type, surface(Color.TRANSPARENT, 13))
		result.set_stylebox("hover", type, surface(Color(0.60, 0.37, 0.24, 0.08), 13))
		result.set_stylebox("pressed", type, surface(Color(0.60, 0.37, 0.24, 0.16), 13))
		result.set_stylebox("disabled", type, surface(Color.TRANSPARENT, 13))
		result.set_stylebox("focus", type, surface(Color.TRANSPARENT, 0, RED))
	result.set_stylebox("panel", "Tree", surface(Color.TRANSPARENT, 8))
	result.set_stylebox("selected", "Tree", surface(Color(0.48, 0.27, 0.2, 0.13), 8, Color(0.48, 0.27, 0.2, 0.3)))
	result.set_stylebox("selected_focus", "Tree", result.get_stylebox("selected", "Tree"))
	result.set_color("font_selected_color", "Tree", RED)
	result.set_color("guide_color", "Tree", Color(0.4, 0.35, 0.3, 0.12))
	result.set_constant("v_separation", "Tree", 18)
	result.set_constant("h_separation", "Tree", 10)
	result.set_stylebox("normal", "LineEdit", surface(Color(1, 1, 1, 0.26), 12, RULE))
	result.set_stylebox("focus", "LineEdit", surface(Color(1, 1, 1, 0.5), 12, RED))
	result.set_color("font_placeholder_color", "LineEdit", MUTED)
	result.set_stylebox("panel", "PopupMenu", surface(PAPER, 12, RULE))
	result.set_stylebox("hover", "PopupMenu", surface(Color("ded0b8"), 10))
	var rule := StyleBoxLine.new()
	rule.color = RULE
	rule.thickness = 1
	result.set_stylebox("separator", "HSeparator", rule)
	return result

static func decorate(panel: PanelContainer, book: bool = false, role: String = "sheet") -> void:
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	panel.theme = theme()
	panel.add_theme_stylebox_override("panel", paper_style(book, role == "newspaper"))
	var old_grain: Node = panel.get_node_or_null("PaperGrain")
	if old_grain != null:
		panel.remove_child(old_grain)
		old_grain.queue_free()

static func label(text: String, font_size: int = 26, title: bool = false) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", INK)
	node.add_theme_font_override("font", reading_font())
	if title:
		node.add_theme_font_override("font", display_font())
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func display_font(weight: float = 650.0) -> FontVariation:
	if _display_fonts.has(weight):
		return _display_fonts[weight]
	var font := FontVariation.new()
	font.base_font = TITLE_FONT
	font.fallbacks = [FALLBACK_FONT]
	# A restrained impression of ink, rather than the former heavy display face.
	font.variation_embolden = clampf(0.35 + (weight - 450.0) / 1800.0, 0.35, 0.58)
	_display_fonts[weight] = font
	return font

static func button(text: String, callback: Callable, font_size: int = 26) -> Button:
	var node := Button.new()
	node.text = text
	node.focus_mode = Control.FOCUS_NONE
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_size_override("font_size", font_size)
	node.pressed.connect(callback)
	return node

