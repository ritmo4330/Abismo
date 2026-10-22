extends Control

@onready var start_button = $StartButton
@onready var load_button = $LoadButton
@onready var quit_button = $QuitButton

const GAME_ROOT_SCENE_PATH: String = "res://scenes/game_root.tscn"
const BOOK = preload("res://scripts/UI/casebook_style.gd")
var _menu_overlay: Control

func _ready():
	GameManager.enter_main_menu()
	if AudioManager != null and AudioManager.has_method("play_bgm"):
		AudioManager.play_bgm("cassandra_memory", 1.5)

	if start_button:
		start_button.pressed.connect(_on_start_button_pressed)
	if load_button:
		load_button.disabled = SaveManager == null or not (SaveManager.has_save() or SaveManager.has_autosave())
		load_button.pressed.connect(_on_load_button_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_button_pressed)
	var settings := get_node_or_null("SettingsButton") as Button
	if settings:
		settings.mouse_filter = Control.MOUSE_FILTER_STOP
		settings.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		settings.pressed.connect(_open_settings)

func _on_start_button_pressed():
	if SaveManager != null:
		SaveManager.cancel_pending_load()
	GameManager.enter_gameplay()
	GameManager.set_next_boot_mode(GameManager.BOOT_MODE_CH0_PROLOGUE)
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)


func _on_load_button_pressed() -> void:
	if SaveManager == null:
		return
	var column := _open_sheet("读取存档")
	var manual := BOOK.button("手动存档", _load_slot.bind(false), 28)
	manual.disabled = not SaveManager.has_save()
	BOOK.style_ribbon(manual)
	column.add_child(manual)
	var automatic := BOOK.button("结局前 · 自动存档", _load_slot.bind(true), 28)
	automatic.disabled = not SaveManager.has_autosave()
	BOOK.style_ribbon(automatic)
	column.add_child(automatic)
	_add_close(column)

func _load_slot(automatic: bool) -> void:
	var slot: String = SaveManager._get_autosave_slot_name() if automatic else ""
	if not SaveManager.request_load_game(slot): return
	GameManager.enter_gameplay()
	get_tree().change_scene_to_file(GAME_ROOT_SCENE_PATH)

func _open_sheet(title: String) -> VBoxContainer:
	_close_sheet()
	_menu_overlay = Control.new()
	_menu_overlay.name = "MenuSheet"
	_menu_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_menu_overlay)
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.12, 0.10, 0.08, 0.55)
	_menu_overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_menu_overlay.add_child(center)
	var paper := PanelContainer.new()
	paper.custom_minimum_size = Vector2(570, 420)
	BOOK.decorate(paper)
	var material := BOOK.paper_style()
	material.set("tint", Color(1.12, 1.12, 1.08))
	paper.add_theme_stylebox_override("panel", material)
	center.add_child(paper)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	paper.add_child(column)
	var heading := BOOK.label(title, 38, true)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	column.add_child(HSeparator.new())
	return column

func _add_close(column: VBoxContainer) -> void:
	var close := BOOK.button("返回", _close_sheet, 28)
	BOOK.style_ribbon(close)
	column.add_child(close)

func _close_sheet() -> void:
	if is_instance_valid(_menu_overlay):
		remove_child(_menu_overlay)
		_menu_overlay.queue_free()
	_menu_overlay = null

func _open_settings() -> void:
	var column := _open_sheet("系统设置")
	var speed := OptionButton.new()
	for title: String in TextSpeedManager.MODE_NAMES: speed.add_item("文字速度 · " + title)
	speed.select(TextSpeedManager._mode_index)
	speed.item_selected.connect(TextSpeedManager.set_speed_mode)
	column.add_child(speed)
	for type: String in ["bgm", "sfx"]:
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 24)
		column.add_child(row)
		var label := BOOK.label("音乐" if type == "bgm" else "音效", 27)
		label.custom_minimum_size.x = 90
		row.add_child(label)
		var slider := HSlider.new()
		slider.custom_minimum_size = Vector2(300, 44)
		slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slider.max_value = 1.0
		slider.step = 0.01
		var property: String = type + "_volume_db"
		slider.value = db_to_linear(float(AudioManager.get(property)))
		slider.value_changed.connect(func(value: float) -> void: AudioManager.set(property, linear_to_db(maxf(value, 0.00001))))
		row.add_child(slider)
	var full := CheckButton.new()
	full.text = "全屏显示"
	full.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	full.toggled.connect(func(enabled: bool) -> void: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED))
	column.add_child(full)
	_add_close(column)

func _on_quit_button_pressed():
	get_tree().quit()
