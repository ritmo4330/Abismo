extends CanvasLayer

signal acknowledged
const BOOK = preload("res://scripts/UI/casebook_style.gd")
var continue_button: Button

func build(title: String, conclusion: String) -> void:
	layer = 270
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.02, 0.02, 0.025, 0.65)
	add_child(dimmer)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(700, 380)
	paper.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	BOOK.decorate(paper)
	center.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	paper.add_child(column)
	var heading := BOOK.label("推理成立", 38, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", BOOK.RED)
	column.add_child(heading)
	var question := BOOK.label(title, 28, true)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(question)
	var body := RichTextLabel.new()
	body.custom_minimum_size = Vector2(620, 180)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.text = conclusion
	column.add_child(body)
	continue_button = BOOK.button("继续", func() -> void: acknowledged.emit(), 28)
	BOOK.style_ribbon(continue_button)
	column.add_child(continue_button)
