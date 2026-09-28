@tool
extends DialogicLayoutLayer

## Example scene for viewing the History
## Implements most of the visual options from 1.x History mode

@export_group('Look')
@export_subgroup('Font')
@export var font_use_global_size: bool = true
@export var font_custom_size: int = 15
@export var font_use_global_fonts: bool = true
@export_file('*.ttf', '*.tres') var font_custom_normal: String = ""
@export_file('*.ttf', '*.tres') var font_custom_bold: String = ""
@export_file('*.ttf', '*.tres') var font_custom_italics: String = ""

@export_subgroup('Buttons')
@export var show_open_button: bool = true
@export var show_close_button: bool = true

@export_group('Settings')
@export_subgroup('Events')
@export var show_all_choices: bool = true
@export var show_join_and_leave: bool = true

@export_subgroup('Behaviour')
@export var scroll_to_bottom: bool = true
@export var show_name_colors: bool = true
@export var name_delimeter: String = ": "

var scroll_to_bottom_flag: bool = false

@export_group('Private')
@export var HistoryItem: PackedScene = null

var history_item_theme: Theme = null

func get_show_history_button() -> Button:
	return $ShowHistory


func get_hide_history_button() -> Button:
	return $HideHistory


func get_history_box() -> ScrollContainer:
	return %HistoryBox


func get_history_log() -> VBoxContainer:
	return %HistoryLog


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	DialogicUtil.autoload().History.open_requested.connect(_on_show_history_pressed)
	DialogicUtil.autoload().History.close_requested.connect(_on_hide_history_pressed)


func _apply_export_overrides() -> void:
	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	if history_subsystem != null:
		get_show_history_button().visible = show_open_button and history_subsystem.get(&'simple_history_enabled')
	else:
		set(&'visible', false)

	history_item_theme = Theme.new()

	if font_use_global_size:
		history_item_theme.default_font_size = get_global_setting(&'font_size', font_custom_size)
	else:
		history_item_theme.default_font_size = font_custom_size

	if font_use_global_fonts and ResourceLoader.exists(get_global_setting(&'font', '') as String):
		history_item_theme.default_font = load(get_global_setting(&'font', '') as String) as Font
	elif ResourceLoader.exists(font_custom_normal):
		history_item_theme.default_font = load(font_custom_normal)

	if ResourceLoader.exists(font_custom_bold):
		history_item_theme.set_font(&'RichtTextLabel', &'bold_font', load(font_custom_bold) as Font)
	if ResourceLoader.exists(font_custom_italics):
		history_item_theme.set_font(&'RichtTextLabel', &'italics_font', load(font_custom_italics) as Font)



func _process(_delta : float) -> void:
	if Engine.is_editor_hint():
		return
	# The hourglass belongs to the dialogue box: it follows the box lifecycle,
	# never survives a finished timeline, and remains disabled in full-text styles.
	if not get_history_box().visible:
		get_show_history_button().visible = _should_show_open_button()
		if get_show_history_button().visible:
			_sync_open_button_layout()
	if scroll_to_bottom_flag and get_history_box().visible and get_history_log().get_child_count():
		await get_tree().process_frame
		get_history_box().ensure_control_visible(get_history_log().get_children()[-1] as Control)
		scroll_to_bottom_flag = false


func _should_show_open_button() -> bool:
	if not show_open_button:
		return false
	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	if history_subsystem == null or not history_subsystem.get(&'simple_history_enabled'):
		return false
	if DialogicUtil.autoload().current_timeline == null:
		return false
	var textbox_layer: CanvasItem = get_tree().root.find_child("VN_TextboxLayer", true, false) as CanvasItem
	return textbox_layer != null and textbox_layer.is_visible_in_tree()


func _sync_open_button_layout() -> void:
	var name_panel: Control = get_tree().root.find_child("NameLabelPanel", true, false) as Control
	var dialogue_panel: Control = get_tree().root.find_child("DialogTextPanel", true, false) as Control
	if name_panel == null or dialogue_panel == null or not name_panel.is_visible_in_tree():
		return
	var name_rect: Rect2 = name_panel.get_global_rect()
	var dialogue_rect: Rect2 = dialogue_panel.get_global_rect()
	var button_side: float = maxf(name_rect.size.y, 36.0)
	var button: Button = get_show_history_button()
	button.size = Vector2(button_side, button_side)
	button.global_position = Vector2(dialogue_rect.end.x - button_side, name_rect.position.y)


func _on_show_history_pressed() -> void:
	DialogicUtil.autoload().paused = true
	show_history()


func show_history() -> void:
	for child: Node in get_history_log().get_children():
		child.queue_free()

	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	for info: Dictionary in history_subsystem.call(&'get_simple_history'):
		# The player-facing log is a dialogue transcript, not a stage-direction log.
		if String(info.get('event_type', '')) != "Text":
			continue
		var history_item : Node = HistoryItem.instantiate()
		history_item.set(&'theme', history_item_theme)
		match info.event_type:
			"Text":
				if info.has('character') and info['character']:
					if show_name_colors:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter, info['character_color'])
					else:
						history_item.call(&'load_info', info['text'], info['character']+name_delimeter)
				else:
					history_item.call(&'load_info', info['text'])
		get_history_log().add_child(history_item)

	if scroll_to_bottom:
		scroll_to_bottom_flag = true

	get_show_history_button().hide()
	get_hide_history_button().visible = show_close_button
	get_history_box().show()


func _on_hide_history_pressed() -> void:
	DialogicUtil.autoload().paused = false
	get_history_box().hide()
	get_hide_history_button().hide()
	var history_subsystem: Node = DialogicUtil.autoload().get(&'History')
	get_show_history_button().visible = _should_show_open_button()
