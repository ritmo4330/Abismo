extends CanvasLayer

signal opened
const RULES = preload("res://scripts/clues/dining_backdoor_rules.gd")
const STYLE = preload("res://scripts/UI/casebook_style.gd")
const PAUSE_TOKEN := "dining_backdoor"
var handprints: Array[String] = []
var buttons: Array[Button] = []
var confirm_button: Button
var panel: PanelContainer
var _closed := false

func _ready() -> void:
	layer = 160
	process_mode = Node.PROCESS_MODE_ALWAYS
	var overlay := ColorRect.new()
	overlay.color = Color(0.015, 0.02, 0.025, 0.78)
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(overlay)
	panel = PanelContainer.new()
	STYLE.decorate(panel)
	add_child(panel)
	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 14)
	panel.add_child(content)
	content.add_child(STYLE.label("餐厅后门 · 四个手印", 30, true))
	var description := STYLE.label(DataManager.get_clue_def("1_dining_2").description, 24)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	var known: Array[String] = []
	for entry: Dictionary in RULES.RESEARCH:
		if RULES.research_known(entry): known.append(entry.name)
	# A progress summary, not four aligned labels that imply an unauthored
	# symbol-to-institute permutation or reveal undisclosed locations.
	var sources := STYLE.label("研究所记录（%d/4）：%s" % [known.size(), "、".join(known) if not known.is_empty() else "暂无"], 22)
	sources.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(sources)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	content.add_child(row)
	for symbol: String in RULES.SYMBOLS:
		var button := STYLE.button(symbol + "\n手印", func() -> void: pass, 30)
		button.toggle_mode = true
		button.custom_minimum_size = Vector2(0, 92)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_stylebox_override("normal", STYLE.surface(Color.TRANSPARENT, 12, STYLE.RULE))
		button.add_theme_stylebox_override("pressed", STYLE.surface(Color(0.53, 0.24, 0.18, 0.16), 12, STYLE.RED))
		button.toggled.connect(_on_toggled.bind(symbol))
		row.add_child(button)
		buttons.append(button)
	var hint := STYLE.label("选择四个手印，再确认同时按下。" if RULES.SOURCE.available() else "尚未开启潜意识调查。", 22)
	content.add_child(hint)
	var actions := HBoxContainer.new()
	content.add_child(actions)
	var cancel := STYLE.button("返回调查", close, 25)
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(cancel)
	confirm_button = STYLE.button("确认同时按下", confirm, 25)
	confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(confirm_button)
	get_viewport().size_changed.connect(_layout)
	_layout()
	call_deferred("_layout")
	_refresh()

func show_lock() -> void:
	GameManager.request_pause(PAUSE_TOKEN)

func _layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	panel.custom_minimum_size.x = minf(960, viewport_size.x - 48)
	panel.reset_size()
	panel.position = (viewport_size - panel.size) * 0.5

func _on_toggled(pressed: bool, symbol: String) -> void:
	if pressed and not handprints.has(symbol): handprints.append(symbol)
	elif not pressed: handprints.erase(symbol)
	_refresh()

func _refresh() -> void:
	confirm_button.disabled = handprints.size() != 4 or not RULES.ready()

func confirm() -> void:
	if _closed or not RULES.confirm(handprints): return
	_finish()
	opened.emit()

func close() -> void:
	if not _closed: _finish()

func _finish() -> void:
	_closed = true
	GameManager.release_pause(PAUSE_TOKEN)
	hide()
	queue_free()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		close()

func _exit_tree() -> void:
	if GameManager != null: GameManager.release_pause(PAUSE_TOKEN)
