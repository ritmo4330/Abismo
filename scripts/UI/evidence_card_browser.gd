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
var category_tabs: Array[Button] = []
var sidebar: VBoxContainer
var index_title: Label
var index_counter: Label
var book: Panel
var _book_style: StyleBox
var reading_area: Control
var _reading_labels: Array[Control] = []
var _heading_stack: VBoxContainer
var _source_label: Label
var _portrait: TextureRect
var _table_cells: Array[PanelContainer] = []
var _paragraph_columns: Array[VBoxContainer] = []
var _fit_revision := 0
var _fitted_revision := 0
var _fit_scheduled := false
var fitted_font_size := 28


func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	get_viewport().size_changed.connect(_layout)


func build() -> void:
	if _built:
		return
	_built = true
	book = Panel.new()
	book.name = "HandwrittenNotebook"
	book.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	_book_style = Style.notebook("book", 0)
	book.add_theme_stylebox_override("panel", _book_style)
	add_child(book)
	surface = MarginContainer.new()
	surface.theme = Style.theme()
	for edge: String in ["left", "right", "top", "bottom"]:
		surface.add_theme_constant_override("margin_" + edge, 46 if edge in ["left", "right"] else 30)
	add_child(surface)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 18)
	surface.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	column.add_child(header)
	var title_paper := PanelContainer.new()
	title_paper.add_theme_stylebox_override("panel", Style.notebook("heading", 4))
	header.add_child(title_paper)
	var title := Style.label("线索与疑点", 48, true)
	title_paper.add_child(title)
	var title_space := Control.new()
	title_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title_space)
	kind = OptionButton.new()
	for label: String in ["线索", "疑点", "人物"]:
		kind.add_item(label)
		var tab_index := category_tabs.size()
		var tab := Style.button(label, func() -> void: kind.select(tab_index); search.clear(); _refresh(), 28)
		tab.toggle_mode = true
		tab.add_theme_color_override("font_pressed_color", Style.INK)
		tab.custom_minimum_size = Vector2(112, 62)
		tab.add_theme_stylebox_override("normal", Style.notebook("tab", 12))
		tab.add_theme_stylebox_override("hover", Style.notebook("active_tab", 12))
		tab.add_theme_stylebox_override("pressed", Style.notebook("active_tab", 12))
		category_tabs.append(tab)
		header.add_child(tab)
	kind.item_selected.connect(func(_index: int) -> void: search.clear(); _refresh())
	kind.hide()
	add_child(kind)
	close_button = Style.button("返回调查", close, 25)
	header.add_child(close_button)
	var row := HBoxContainer.new()
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 48)
	column.add_child(row)
	sidebar = VBoxContainer.new()
	sidebar.custom_minimum_size.x = 320
	sidebar.add_theme_constant_override("separation", 14)
	row.add_child(sidebar)
	index_title = Style.label("线索索引", 34, true)
	sidebar.add_child(index_title)
	search = LineEdit.new()
	search.placeholder_text = "搜索线索…"
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
	var writing := Style.notebook("reading", 28)
	writing.content_margin_top = 10
	card.add_theme_stylebox_override("panel", writing)
	row.add_child(card)
	# A fixed page instead of a scrolling document. Its child minimum size
	# must not stretch the whole notebook while text is being measured.
	reading_area = Control.new()
	reading_area.name = "ReadingPage"
	reading_area.clip_contents = true
	reading_area.resized.connect(_queue_page_fit)
	card.add_child(reading_area)
	content = VBoxContainer.new()
	content.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	content.add_theme_constant_override("separation", 12)
	reading_area.add_child(content)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 16)
	column.add_child(footer)
	index_counter = Style.label("", 24)
	footer.add_child(index_counter)
	previous_button = Style.button("← 上一张", func() -> void: _step(-1), 25)
	footer.add_child(previous_button)
	counter = Style.label("", 23)
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	footer.add_child(counter)
	next_button = Style.button("下一张 →", func() -> void: _step(1), 25)
	footer.add_child(next_button)
	use_button = Style.button("填入当前空格", _use, 25)
	footer.add_child(use_button)
	reason_button = Style.button("进入推理", _reason, 25)
	reason_button.add_theme_stylebox_override("normal", Style.notebook("action", 14))
	reason_button.add_theme_stylebox_override("hover", Style.notebook("active_tab", 14))
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
	book.size = view
	sidebar.custom_minimum_size.x = (surface.size.x - 92) * 0.24
	index_counter.custom_minimum_size.x = sidebar.custom_minimum_size.x + 32
	# The fold follows the index width instead of crossing the reading text.
	_book_style.set("seam_ratio", (46 + sidebar.custom_minimum_size.x + 24) / surface.size.x)
	book.queue_redraw()
	_queue_page_fit()


func _refresh() -> void:
	for i: int in category_tabs.size():
		category_tabs[i].set_pressed_no_signal(i == kind.selected)
	index_title.text = ["线索索引", "疑点索引", "人物索引"][kind.selected]
	search.placeholder_text = ["搜索线索…", "搜索疑点…", "搜索人物…"][kind.selected]
	match kind.selected:
		0: cards = Catalog.clue_cards(_clue_ids)
		1: cards = Catalog.suspicion_cards()
		2: cards = Catalog.person_cards()
	if kind.selected == 0 and not cards.is_empty() and cards.all(func(card: Dictionary) -> bool: return card.get("evidence_id", "") == "1_testimony_3_all"):
		index_title.text = "见闻索引"
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
		tile.alignment = HORIZONTAL_ALIGNMENT_LEFT
		tile.add_theme_color_override("font_pressed_color", Style.INK)
		var source := str(card.get("source", ""))
		tile.text = source.trim_prefix("陈述人：") + "\n" + str(card.title) if source.begins_with("陈述人：") else str(card.title)
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.custom_minimum_size = Vector2(0, 96)
		tile.toggle_mode = true
		tile.button_pressed = card.id == selected_id
		tile.add_theme_stylebox_override("normal", Style.notebook("index", 14))
		var selection := Style.notebook("selected", 14)
		selection.set("mark_y", 32.0 if tile.text.contains("\n") else 48.0)
		var name_width := Style.reading_font().get_string_size(tile.text.get_slice("\n", 0), HORIZONTAL_ALIGNMENT_LEFT, -1, 25).x
		selection.set("mark_x", 14 + name_width * 0.5)
		selection.set("mark_radius", name_width * 0.55 + 10)
		tile.add_theme_stylebox_override("hover", selection)
		tile.add_theme_stylebox_override("pressed", selection)
		if source.begins_with("陈述人："):
			# A larger handwritten name above a quieter record title, as in the
			# approved notebook index; both labels leave input to their button.
			tile.text = ""
			var inset := MarginContainer.new()
			inset.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inset.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			inset.offset_left = 14
			inset.offset_right = -14
			inset.offset_top = 8
			inset.offset_bottom = -8
			tile.add_child(inset)
			var captions := VBoxContainer.new()
			captions.mouse_filter = Control.MOUSE_FILTER_IGNORE
			captions.alignment = BoxContainer.ALIGNMENT_CENTER
			captions.add_theme_constant_override("separation", 0)
			inset.add_child(captions)
			captions.add_child(Style.label(source.trim_prefix("陈述人："), 33))
			var caption := Style.label(str(card.title), 24)
			caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			captions.add_child(caption)
			var width := Style.reading_font().get_string_size(source.trim_prefix("陈述人："), HORIZONTAL_ALIGNMENT_LEFT, -1, 33).x
			selection.set("mark_x", 14 + width * 0.5)
			selection.set("mark_radius", width * 0.55 + 10)
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
	_reading_labels.clear()
	_table_cells.clear()
	_paragraph_columns.clear()
	_heading_stack = null
	_source_label = null
	_portrait = null
	card_title = null
	for child: Node in content.get_children():
		content.remove_child(child)
		child.queue_free()
	var card := _current()
	var index := filtered.find(card)
	counter.text = "%d / %d" % [index + 1, filtered.size()] if index >= 0 else "0 / 0"
	index_counter.text = "%s / %d" % [["见闻记录" if index_title.text == "见闻索引" else "线索记录", "疑点记录", "人物记录"][kind.selected], filtered.size()]
	previous_button.disabled = index <= 0
	next_button.disabled = index < 0 or index == filtered.size() - 1
	use_button.visible = _allow_evidence and not str(card.get("evidence_id", "")).is_empty()
	reason_button.visible = _allow_reasoning
	reason_button.disabled = card.is_empty()
	if card.is_empty():
		content.add_child(Style.label("暂无已收录的卡片", 32))
		_queue_page_fit()
		return
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 28)
	content.add_child(top)
	var headings := VBoxContainer.new()
	_heading_stack = headings
	headings.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	headings.add_theme_constant_override("separation", 20)
	top.add_child(headings)
	card_title = Style.label(card.title, 52, true)
	card_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headings.add_child(card_title)
	var source := Style.label(str(card.get("source", "")), 29)
	_source_label = source
	source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	headings.add_child(source)
	var rule := HSeparator.new()
	rule.add_theme_stylebox_override("separator", Style.notebook("ink_rule", 2))
	headings.add_child(rule)
	if not str(card.get("portrait", "")).is_empty():
		var picture := TextureRect.new()
		_portrait = picture
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
	var paragraphs: Array[String] = []
	for original: String in card.get("paragraphs", []):
		if original.contains("[table"):
			paragraphs.append(original)
		else:
			for paragraph: String in original.split("\n\n", false):
				paragraphs.append(paragraph)
	var columns := 3 if paragraphs.size() > 40 else (2 if paragraphs.size() > 20 else 1)
	var weights: Array[float] = []
	var total_weight := 0.0
	for paragraph: String in paragraphs:
		var weight := ceilf(paragraph.length() / 35.0) + 0.4
		weights.append(weight)
		total_weight += weight
	if columns > 1:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 22)
		content.add_child(row)
		for i: int in columns:
			var column := VBoxContainer.new()
			column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			column.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
			row.add_child(column)
			_paragraph_columns.append(column)
	var column_index := 0
	var column_weight := 0.0
	for i: int in paragraphs.size():
		var paragraph := paragraphs[i]
		if columns > 1 and column_index < columns - 1 and column_weight > 0 and column_weight + weights[i] > total_weight / columns:
			column_index += 1
			column_weight = 0
		var label := RichTextLabel.new()
		label.fit_content = true
		label.bbcode_enabled = bool(card.get("markup", false))
		label.scroll_active = false
		label.add_theme_font_size_override("normal_font_size", 34)
		label.text = paragraph
		label.add_theme_constant_override("line_separation", 12)
		if columns > 1:
			_paragraph_columns[column_index].add_child(label)
		else:
			content.add_child(label)
		column_weight += weights[i]
		_reading_labels.append(label)
	for fact: String in card.get("facts", []):
		var label := Style.label("• " + fact, 27)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content.add_child(label)
		_reading_labels.append(label)
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
				cell.add_theme_stylebox_override("panel", Style.surface(Color(1, 1, 1, 0.1), 18, Style.RULE))
				cell.custom_minimum_size = Vector2(150, 110)
				grid.add_child(cell)
				_table_cells.append(cell)
				var label := Style.label(value, 25)
				label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				cell.add_child(label)
				_reading_labels.append(label)
	_queue_page_fit()


func _queue_page_fit() -> void:
	if reading_area == null or not visible:
		return
	_fit_revision += 1
	if _fit_scheduled:
		return
	_fit_scheduled = true
	# Keep intermediate measurements out of view when turning a card.
	content.modulate.a = 0.0
	call_deferred("_fit_page")


func is_page_fitted() -> bool:
	return _fitted_revision == _fit_revision and not _fit_scheduled


func _fit_page() -> void:
	_fit_scheduled = false
	var revision := _fit_revision
	await get_tree().process_frame
	if revision != _fit_revision or not visible:
		return
	if reading_area.size.x <= 0 or reading_area.size.y <= 0:
		_queue_page_fit()
		return
	# Measure the actual wrapped labels, including BBCode tables and facts.
	# Choose the largest size which fits, rather than hiding overflow.
	var low := 8
	var high := 28
	var best := low
	_apply_page_font(high)
	if not await _settle_page(revision):
		return
	if content.get_combined_minimum_size().y <= reading_area.size.y - 2:
		best = high
		low = high + 1
	else:
		high -= 1
	while low <= high:
		var candidate := int((low + high) / 2)
		_apply_page_font(candidate)
		if not await _settle_page(revision):
			return
		if content.get_combined_minimum_size().y <= reading_area.size.y - 2:
			best = candidate
			low = candidate + 1
		else:
			high = candidate - 1
	_apply_page_font(best)
	if not await _settle_page(revision):
		return
	fitted_font_size = best
	_fitted_revision = revision
	content.modulate.a = 1.0


func _settle_page(revision: int) -> bool:
	# Nested text/column/container minimum sizes settle from the inside out.
	for i: int in range(4):
		await get_tree().process_frame
		if revision != _fit_revision or not visible:
			return false
	return true


func _apply_page_font(font_size: int) -> void:
	content.add_theme_constant_override("separation", maxi(3, int(font_size * 0.45)))
	for column: VBoxContainer in _paragraph_columns:
		column.add_theme_constant_override("separation", maxi(2, int(font_size * 0.25)))
	content.size = Vector2(reading_area.size.x, 0)
	if card_title != null:
		card_title.add_theme_font_size_override("font_size", clampi(font_size + 14, 24, 42))
	if _heading_stack != null:
		_heading_stack.add_theme_constant_override("separation", maxi(3, int(font_size * 0.3)))
	if _source_label != null:
		_source_label.add_theme_font_size_override("font_size", clampi(font_size, 12, 25))
	for label: Control in _reading_labels:
		if label is RichTextLabel:
			for key: String in ["normal_font_size", "bold_font_size", "italics_font_size", "bold_italics_font_size", "mono_font_size"]:
				label.add_theme_font_size_override(key, font_size)
			label.add_theme_constant_override("line_separation", maxi(1, int(font_size * 0.16)))
			label.add_theme_constant_override("paragraph_separation", maxi(2, int(font_size * 0.25)))
		else:
			label.add_theme_font_size_override("font_size", font_size)
	if _portrait != null:
		_portrait.custom_minimum_size = Vector2(font_size * 9, font_size * 6.5)
	for cell: PanelContainer in _table_cells:
		cell.custom_minimum_size = Vector2(100, font_size * 3)
		cell.add_theme_stylebox_override("panel", Style.surface(Color(1, 1, 1, 0.1), maxi(4, int(font_size / 3)), Style.RULE))
	content.queue_sort()


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
