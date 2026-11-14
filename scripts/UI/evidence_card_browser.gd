extends CanvasLayer

signal closed
signal use_evidence(clue_id: String)
signal open_reasoning(suspicion_id: String)

const Catalog = preload("res://scripts/data/evidence_card_catalog.gd")
const Style = preload("res://scripts/UI/casebook_style.gd")
var close_button: Button
var use_button: Button
var reason_button: Button
var previous_button: Button
var next_button: Button
var search: LineEdit
var kind: OptionButton
var cards: Array[Dictionary] = []
var filtered: Array[Dictionary] = []
var selected_id := ""
var content: VBoxContainer
var list: VBoxContainer
var card_title: Label
var counter: Label
var surface: MarginContainer
var _built := false
var _allow_reasoning := true
var _allow_evidence := false
var _clue_ids: PackedStringArray = []


func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	get_viewport().size_changed.connect(_layout)


func build() -> void:
	if _built:
		return
	_built = true
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("e9e6de")
	add_child(background)
	surface = MarginContainer.new()
	surface.theme = Style.theme()
	for edge: String in ["left", "right", "top", "bottom"]:
		surface.add_theme_constant_override("margin_" + edge, 28)
	add_child(surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	surface.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	column.add_child(header)
	var title := Style.label("线索与疑点", 34, true)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	kind = OptionButton.new()
	for label: String in ["线索卡片", "疑点卡片", "人物卡片"]:
		kind.add_item(label)
	kind.item_selected.connect(func(_index: int) -> void: search.clear(); _refresh())
	header.add_child(kind)
	close_button = Style.button("返回", close, 25)
	header.add_child(close_button)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	var sidebar := VBoxContainer.new()
	sidebar.custom_minimum_size.x = 310
	sidebar.add_theme_constant_override("separation", 14)
	row.add_child(sidebar)
	search = LineEdit.new()
	search.placeholder_text = "搜索卡片"
	search.text_changed.connect(func(_query: String) -> void: _filter())
	sidebar.add_child(search)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(scroll)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 12)
	scroll.add_child(list)
	var card := PanelContainer.new()
	card.name = "ReadingCard"
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.add_theme_stylebox_override("panel", Style.surface(Color.WHITE, 32, Color("c5c1b6")))
	row.add_child(card)
	var reading_scroll := ScrollContainer.new()
	reading_scroll.name = "CardScroll"
	reading_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card.add_child(reading_scroll)
	content = VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 24)
	reading_scroll.add_child(content)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	previous_button = Style.button("上一张", func() -> void: _step(-1), 25)
	footer.add_child(previous_button)
	counter = Style.label("", 23)
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(counter)
	next_button = Style.button("下一张", func() -> void: _step(1), 25)
	footer.add_child(next_button)
	use_button = Style.button("填入当前空格", _use, 25)
	footer.add_child(use_button)
	reason_button = Style.button("进入推理", _reason, 25)
	footer.add_child(reason_button)
	_layout()


func open(initial_kind := 0, initial_id := "", allow_reasoning := true, allow_evidence := false, ids: PackedStringArray = []) -> void:
	build()
	_allow_reasoning = allow_reasoning
	_allow_evidence = allow_evidence
	_clue_ids = ids
	selected_id = initial_id
	kind.select(initial_kind)
	search.clear()
	show()
	_refresh()


func _layout() -> void:
	if surface == null:
		return
	var view := get_viewport().get_visible_rect().size
	var ratio := minf(1.0, minf(view.x / 1440.0, view.y / 900.0))
	surface.scale = Vector2.ONE * ratio
	surface.size = view / ratio


func _refresh() -> void:
	match kind.selected:
		0: cards = Catalog.clue_cards(_clue_ids)
		1: cards = Catalog.suspicion_cards()
		2: cards = Catalog.person_cards()
	_filter()


func _filter() -> void:
	filtered.clear()
	var query := search.text.strip_edges().to_lower()
	for card: Dictionary in cards:
		var text := str(card.title) + str(card.get("source", "")) + str(card.get("paragraphs", [])) + str(card.get("facts", []))
		if query.is_empty() or text.to_lower().contains(query):
			filtered.append(card)
	for child: Node in list.get_children():
		list.remove_child(child)
		child.queue_free()
	var found := false
	for card: Dictionary in filtered:
		if card.id == selected_id or card.get("evidence_id", "") == selected_id:
			selected_id = card.id
			found = true
			break
	if not found:
		selected_id = str(filtered[0].id) if not filtered.is_empty() else ""
	for card: Dictionary in filtered:
		var tile := Button.new()
		tile.text = card.title + "\n" + str(card.get("source", ""))
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.custom_minimum_size = Vector2(0, 105)
		tile.toggle_mode = true
		tile.button_pressed = card.id == selected_id
		tile.add_theme_stylebox_override("normal", Style.surface(Color("f9f7f0"), 14, Color("cbc4b6")))
		tile.add_theme_stylebox_override("pressed", Style.surface(Color("dae7df"), 14, Color("567a68")))
		tile.pressed.connect(_select.bind(card.id))
		list.add_child(tile)
		if card.id == selected_id:
			call_deferred("_ensure_card_visible", tile)
	_render()


func _ensure_card_visible(tile: Control) -> void:
	if is_instance_valid(tile) and list.is_ancestor_of(tile):
		list.get_parent().ensure_control_visible(tile)


func _select(id: String) -> void:
	selected_id = id
	_filter()


func _current() -> Dictionary:
	for card: Dictionary in filtered:
		if card.id == selected_id:
			return card
	return {}


func _render() -> void:
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var card := _current()
	var index := filtered.find(card)
	counter.text = "%d / %d" % [index + 1, filtered.size()] if index >= 0 else "0 / 0"
	previous_button.disabled = index <= 0
	next_button.disabled = index < 0 or index == filtered.size() - 1
	use_button.visible = _allow_evidence and not str(card.get("evidence_id", "")).is_empty()
	reason_button.visible = _allow_reasoning
	reason_button.disabled = card.is_empty()
	if card.is_empty():
		content.add_child(Style.label("暂无已收录的卡片", 32))
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 28)
	content.add_child(top)
	var headings := VBoxContainer.new()
	headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headings.add_theme_constant_override("separation", 20)
	top.add_child(headings)
	card_title = Style.label(card.title, 42, true)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headings.add_child(card_title)
	var source := Style.label(str(card.get("source", "")), 25)
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headings.add_child(source)
	if not str(card.get("portrait", "")).is_empty():
		var picture := TextureRect.new()
		var texture: Texture2D = load(card.portrait)
		var region := texture.get_image().get_used_rect()
		region.size.y = mini(region.size.y, int(region.size.x * 0.95))
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = region
		picture.texture = atlas
		picture.custom_minimum_size = Vector2(300, 230)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		top.add_child(picture)
	for paragraph: String in card.get("paragraphs", []):
		var label := RichTextLabel.new()
		label.fit_content = true
		label.bbcode_enabled = bool(card.get("markup", false))
		label.scroll_active = false
		label.add_theme_font_size_override("normal_font_size", 27)
		label.text = ("• " if card.get("bullets", false) else "") + paragraph
		content.add_child(label)
	for fact: String in card.get("facts", []):
		var label := Style.label("• " + fact, 27)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
	if card.has("table"):
		var grid := GridContainer.new()
		grid.columns = card.table[0].size()
		grid.add_theme_constant_override("h_separation", 0)
		grid.add_theme_constant_override("v_separation", 0)
		content.add_child(grid)
		for row: Array in card.table:
			for value: String in row:
				var cell := PanelContainer.new()
				cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				cell.add_theme_stylebox_override("panel", Style.surface(Color.WHITE, 18, Color("5a5a5a")))
				cell.custom_minimum_size = Vector2(150, 110)
				grid.add_child(cell)
				var label := Style.label(value, 25)
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				cell.add_child(label)
	content.get_parent().scroll_vertical = 0


func _step(offset: int) -> void:
	var index := filtered.find(_current()) + offset
	if index >= 0 and index < filtered.size():
		_select(filtered[index].id)


func _use() -> void:
	var card := _current()
	if not card.is_empty():
		use_evidence.emit(card.get("evidence_id", ""))


func _reason() -> void:
	open_reasoning.emit(str(_current().get("suspicion_id", "")))


func close() -> void:
	hide()
	closed.emit()
