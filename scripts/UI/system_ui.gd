extends CanvasLayer

const FlowSteps = preload("res://scripts/flow/flow_steps.gd")
const BOOK = preload("res://scripts/UI/casebook_style.gd")

const PANEL_ID := "system_panel"
const PAUSE_TOKEN := "system_panel"
const DIALOG_BOX_STYLE := "res://assets/UI/dialogues/VisualNovelTextbox/dialogue_box_panel.tres"
const NAME_BOX_STYLE := "res://assets/UI/dialogues/VisualNovelTextbox/name_label_panel.tres"

const CHARACTERS := [
	{"id": "Mu", "name": "穆执", "portrait": "res://assets/characters/npcs/mu_zhi_neutral.png", "role": "我是一名教徒，如果你对我的信仰感兴趣的话，有机会我可以和你交流。", "reason": "实不相瞒，我的住处同样在这座山上。来到此地之前，我前往教堂参加礼拜，返回时突遇暴风雪，我只能就近找到这里，便请求管家收留了我。", "plan": "我对逝者的遭遇深感不幸，希望你能帮助我们找到凶手。否则就这样待在同一个屋檐下，难免会有些芥蒂。", "past": "我信仰上界教派，不知道你有没有听说过。"},
	{"id": "Zhou", "name": "周崇安", "portrait": "res://assets/characters/npcs/zhou_chong_an_neutral.png", "role": "我是一名孤儿院院长，管理着本市的孤儿院。", "reason": "我来到这座山上有一些事情要处理，下山的时候突然遇到暴风雪，幸好能找到这幢别墅让我避避风雪。", "plan": "我还有些自己的事情想要调查，不过我也会尽力配合你的调查。", "past": "他是一个教徒，经常资助我管理的孤儿院。我与他的接触仅限于此。"},
	{"id": "Lin", "name": "林玖", "portrait": "res://assets/characters/npcs/lin_jiu_nerutral.png", "role": "我是一名学前教师，在周院长管理的孤儿院任职。周院长就是那边那位最年长的人，他对大家都很好。", "reason": "我带乌停湘上山来找穆执，结果还没赶到他的小木屋就下起了暴风雪，我们只好找到最近的这座别墅避雪。", "plan": "凶手……就在我们之中，对吧？我很担心……", "past": "异测会是一个所谓的以探寻超自然现象为职责，力求为有记录的超自然现象寻求科学解释的组织……我只知道这么多。"},
	{"id": "Wu", "name": "乌停湘", "portrait": "res://assets/characters/npcs/wu_ting_xiang_neutral.png", "role": "我是一名高中生，和林姐姐——噢，她叫林玖——我们居住在孤儿院。", "reason": "是林姐姐带我跑出孤儿院的，她说异测会要来抓我，于是我们就跑了出来。", "plan": "被卷入了这么一场案件，也只能在雪停之前尽可能找到真相了吧。", "past": "异测会是一个致力于为超自然现象寻求科学解释的组织，已经成为了一个权威机构，但是他们的研究也不一定全是对的，我们还是要有自己的判断力。"},
	{"id": "Zhong", "name": "钟歧", "portrait": "res://assets/characters/npcs/zhong_qi_neutral.png", "role": "我是一名物理学研究助理，参与我爷爷的研究团队的研究。", "reason": "梅塔要来抓我，我打算躲在山深处避一避，没成想正好掉进了他的圈套。好在他死了，人不是我杀的，但我要感谢这个除害的凶手。", "plan": "梅塔不是什么好人，我好奇的是案件背后的真相。", "past": "梅塔是一个疯子。他暗中抓捕有能力探索世界之理的人，以精神治疗为借口囚禁在他的“十七号精神卫生中心”。并最终将他们的大脑离体培养，成为为梅塔思考的机器。我比较幸运，是穆叔叔救我出来。"},
]

const FIRST_SEARCH_CLUES := ["1_lin_1", "1_lin_2", "1_lin_3", "1_lin_5", "1_lin_6", "1_lin_6_key", "1_mei_1", "1_mei_2", "1_mu_1", "1_wu_1", "1_zhong_1", "1_zhou_1", "1_zhou_2"]
const SECOND_SEARCH_CLUES := ["1_zhongyue_1", "1_zhongyue_2", "1_zhongyue_3"]
const THIRD_SEARCH_CLUES := preload("res://scripts/UI/investigation_tasks.gd").THIRD

var _is_open := false
var _selected_index := 0
var _portrait: TextureButton
var _name_label: Label
var _affinity_label: Label
var _affinity_bar: ProgressBar
var _summary_panel: PanelContainer
var _summary_title: Label
var _detail_body: RichTextLabel
var _task_title: Label
var _task_body: RichTextLabel
var _history_body: RichTextLabel
var _history_overlay: PanelContainer
var _status_label: Label


func _ready() -> void:
	layer = 240
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	_build_interface()
	hide()
	if EventBus != null and not EventBus.ui_panel_focus_requested.is_connected(_on_panel_focus_requested):
		EventBus.ui_panel_focus_requested.connect(_on_panel_focus_requested)
	if SaveManager != null:
		if not SaveManager.save_completed.is_connected(_on_save_completed):
			SaveManager.save_completed.connect(_on_save_completed)
		if not SaveManager.load_completed.is_connected(_on_load_completed):
			SaveManager.load_completed.connect(_on_load_completed)


func _input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_TAB or key_event.physical_keycode == KEY_TAB:
		if GameManager != null and int(GameManager.current_state) == int(GameManager.GameState.MAIN_MENU):
			return
		if _is_open:
			_close_panel()
		else:
			_open_panel()
		get_viewport().set_input_as_handled()
	elif _is_open and (key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE):
		_close_panel()
		get_viewport().set_input_as_handled()


func _build_interface() -> void:
	var host := get_node("ThemeRoot") as Control
	host.theme = BOOK.theme()

	var dimmer := ColorRect.new()
	dimmer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dimmer.color = Color(0.015, 0.02, 0.027, 0.26)
	dimmer.mouse_filter = Control.MOUSE_FILTER_STOP
	host.add_child(dimmer)

	var left := Control.new()
	left.anchor_right = 0.72
	left.anchor_bottom = 1.0
	left.grow_horizontal = Control.GROW_DIRECTION_END
	left.grow_vertical = Control.GROW_DIRECTION_END
	host.add_child(left)
	_build_portrait_area(left)

	var sidebar := PanelContainer.new()
	sidebar.anchor_left = 0.72
	sidebar.anchor_right = 1.0
	sidebar.anchor_bottom = 1.0
	BOOK.decorate(sidebar)
	host.add_child(sidebar)
	_build_sidebar(sidebar)
	_build_history_overlay(host)
	_build_hidden_developer_button(host)


func _build_hidden_developer_button(parent: Control) -> void:
	# 隐藏开发入口：系统界面左下角的透明热区。
	var button := Button.new()
	button.name = "HiddenDeveloperSkip"
	button.anchor_top = 0.95
	button.anchor_right = 0.028
	button.anchor_bottom = 1.0
	button.grow_vertical = Control.GROW_DIRECTION_BEGIN
	button.flat = true
	button.focus_mode = Control.FOCUS_NONE
	button.tooltip_text = ""
	button.modulate = Color(1, 1, 1, 0.015)
	button.z_index = 100
	button.pressed.connect(_developer_skip_current_reasoning)
	parent.add_child(button)


func _developer_skip_current_reasoning() -> void:
	if FlowManager == null:
		return
	var step_id: String = FlowManager.get_current_step_id()
	if step_id not in [FlowSteps.CH1_INITIAL_REASONING, FlowSteps.CH2_SECOND_REASONING, FlowSteps.CH2_THIRD_REASONING]:
		_status_label.text = "当前不在可跳过的推理阶段"
		if ToastManager != null:
			ToastManager.show_notice("当前阶段不能使用推理跳过", "task", 2.0)
		return
	if Dialogic != null and Dialogic.current_timeline != null:
		await Dialogic.end_timeline(true)
	if not FlowManager.developer_skip_current_reasoning():
		return
	if ToastManager != null:
		ToastManager.show_notice("开发功能：已进入下一阶段", "task", 2.5)
	_close_panel()


func _build_portrait_area(parent: Control) -> void:
	_portrait = TextureButton.new()
	_portrait.anchor_left = 0.07
	_portrait.anchor_top = 0.015
	_portrait.anchor_right = 0.93
	_portrait.anchor_bottom = 0.88
	_portrait.ignore_texture_size = true
	_portrait.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.tooltip_text = ""
	_portrait.pressed.connect(_open_character_summary)
	parent.add_child(_portrait)

	var previous_button := _make_nav_button("〈")
	previous_button.anchor_left = 0.015
	previous_button.anchor_top = 0.31
	previous_button.anchor_right = 0.10
	previous_button.anchor_bottom = 0.54
	previous_button.pressed.connect(_cycle_character.bind(-1))
	parent.add_child(previous_button)

	var next_button := _make_nav_button("〉")
	next_button.anchor_left = 0.90
	next_button.anchor_top = 0.31
	next_button.anchor_right = 0.985
	next_button.anchor_bottom = 0.54
	next_button.pressed.connect(_cycle_character.bind(1))
	parent.add_child(next_button)

	var identity_panel := PanelContainer.new()
	identity_panel.anchor_left = 0.08
	identity_panel.anchor_top = 0.82
	identity_panel.anchor_right = 0.92
	identity_panel.anchor_bottom = 0.985
	identity_panel.add_theme_stylebox_override("panel", _dialog_style())
	parent.add_child(identity_panel)
	var identity_margin := MarginContainer.new()
	identity_margin.add_theme_constant_override("margin_left", 38)
	identity_margin.add_theme_constant_override("margin_top", 18)
	identity_margin.add_theme_constant_override("margin_right", 32)
	identity_margin.add_theme_constant_override("margin_bottom", 16)
	identity_panel.add_child(identity_margin)
	var identity_row := HBoxContainer.new()
	identity_row.add_theme_constant_override("separation", 24)
	identity_margin.add_child(identity_row)

	var name_panel := PanelContainer.new()
	name_panel.custom_minimum_size = Vector2(260, 56)
	name_panel.add_theme_stylebox_override("panel", _name_style())
	identity_row.add_child(name_panel)
	_name_label = Label.new()
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_name_label.add_theme_font_size_override("font_size", 34)
	_name_label.add_theme_color_override("font_color", BOOK.INK)
	name_panel.add_child(_name_label)

	var affinity_box := VBoxContainer.new()
	affinity_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	affinity_box.add_theme_constant_override("separation", 2)
	identity_row.add_child(affinity_box)
	_affinity_label = Label.new()
	_affinity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_affinity_label.add_theme_font_size_override("font_size", 27)
	_affinity_label.add_theme_color_override("font_color", BOOK.RED)
	affinity_box.add_child(_affinity_label)
	_affinity_bar = ProgressBar.new()
	_affinity_bar.min_value = 0
	_affinity_bar.max_value = 100
	_affinity_bar.show_percentage = false
	_affinity_bar.custom_minimum_size = Vector2(0, 22)
	_affinity_bar.add_theme_stylebox_override("background", _flat_style(Color(0.12, 0.12, 0.13, 0.85), Color(0.02, 0.02, 0.02), 2, 2))
	_affinity_bar.add_theme_stylebox_override("fill", _flat_style(Color(0.78, 0.61, 0.28, 1), Color(0.96, 0.84, 0.55), 1, 2))
	affinity_box.add_child(_affinity_bar)

	_summary_panel = PanelContainer.new()
	_summary_panel.anchor_left = 0.09
	_summary_panel.anchor_top = 0.10
	_summary_panel.anchor_right = 0.91
	_summary_panel.anchor_bottom = 0.82
	_summary_panel.z_index = 20
	_summary_panel.add_theme_stylebox_override("panel", _dialog_style())
	_summary_panel.hide()
	parent.add_child(_summary_panel)
	var summary_margin := MarginContainer.new()
	summary_margin.add_theme_constant_override("margin_left", 54)
	summary_margin.add_theme_constant_override("margin_top", 46)
	summary_margin.add_theme_constant_override("margin_right", 42)
	summary_margin.add_theme_constant_override("margin_bottom", 34)
	_summary_panel.add_child(summary_margin)
	var summary_vbox := VBoxContainer.new()
	summary_vbox.add_theme_constant_override("separation", 14)
	summary_margin.add_child(summary_vbox)
	var summary_header := HBoxContainer.new()
	summary_vbox.add_child(summary_header)
	_summary_title = Label.new()
	_summary_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_summary_title.add_theme_font_size_override("font_size", 34)
	_summary_title.add_theme_font_override("font", _bold_font())
	_summary_title.add_theme_color_override("font_color", Color(0.07, 0.07, 0.075))
	summary_header.add_child(_summary_title)
	var summary_close := Button.new()
	summary_close.text = "×"
	summary_close.flat = true
	summary_close.custom_minimum_size = Vector2(58, 50)
	summary_close.add_theme_font_size_override("font_size", 34)
	summary_close.pressed.connect(_summary_panel.hide)
	summary_header.add_child(summary_close)
	_detail_body = RichTextLabel.new()
	_detail_body.bbcode_enabled = true
	_detail_body.fit_content = false
	_detail_body.scroll_active = true
	_detail_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_body.add_theme_font_size_override("normal_font_size", 25)
	_detail_body.add_theme_color_override("default_color", Color(0.07, 0.07, 0.075))
	summary_vbox.add_child(_detail_body)


func _build_sidebar(parent: PanelContainer) -> void:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 26)
	parent.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "调查档案"
	title.add_theme_font_override("font", _bold_font())
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.085))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(54, 48)
	close_button.add_theme_font_size_override("font_size", 30)
	close_button.pressed.connect(_close_panel)
	header.add_child(close_button)

	var task_frame := PanelContainer.new()
	task_frame.custom_minimum_size = Vector2(0, 170)
	task_frame.add_theme_stylebox_override("panel", _dialog_style())
	column.add_child(task_frame)
	var task_margin := MarginContainer.new()
	task_margin.add_theme_constant_override("margin_left", 28)
	task_margin.add_theme_constant_override("margin_top", 20)
	task_margin.add_theme_constant_override("margin_right", 24)
	task_margin.add_theme_constant_override("margin_bottom", 18)
	task_frame.add_child(task_margin)
	var task_vbox := VBoxContainer.new()
	task_margin.add_child(task_vbox)
	_task_title = Label.new()
	_task_title.add_theme_font_override("font", _bold_font())
	_task_title.add_theme_font_size_override("font_size", 28)
	_task_title.add_theme_color_override("font_color", Color(0.08, 0.08, 0.085))
	task_vbox.add_child(_task_title)
	_task_body = RichTextLabel.new()
	_task_body.bbcode_enabled = true
	_task_body.fit_content = false
	_task_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_task_body.add_theme_font_size_override("normal_font_size", 23)
	_task_body.add_theme_color_override("default_color", Color(0.08, 0.08, 0.085))
	task_vbox.add_child(_task_body)

	_add_action_button(column, "推理手册", _open_clue_manual)
	_add_action_button(column, "历史文本", _open_history)
	_add_action_button(column, "保存进度", _save_game)
	_add_action_button(column, "读取存档", _load_game)

	_status_label = Label.new()
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.add_theme_font_size_override("font_size", 20)
	_status_label.add_theme_color_override("font_color", Color(0.12, 0.12, 0.12))
	column.add_child(_status_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)


func _build_history_overlay(parent: Control) -> void:
	_history_overlay = PanelContainer.new()
	_history_overlay.anchor_left = 0.14
	_history_overlay.anchor_top = 0.10
	_history_overlay.anchor_right = 0.86
	_history_overlay.anchor_bottom = 0.90
	_history_overlay.z_index = 40
	_history_overlay.add_theme_stylebox_override("panel", _dialog_style())
	_history_overlay.hide()
	parent.add_child(_history_overlay)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 62)
	margin.add_theme_constant_override("margin_top", 52)
	margin.add_theme_constant_override("margin_right", 48)
	margin.add_theme_constant_override("margin_bottom", 38)
	_history_overlay.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "历史文本"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_override("font", _bold_font())
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.07, 0.07, 0.075))
	header.add_child(title)
	var close_button := Button.new()
	close_button.text = "×"
	close_button.flat = true
	close_button.custom_minimum_size = Vector2(62, 52)
	close_button.add_theme_font_size_override("font_size", 36)
	close_button.pressed.connect(_history_overlay.hide)
	header.add_child(close_button)
	_history_body = RichTextLabel.new()
	_history_body.bbcode_enabled = false
	_history_body.scroll_active = true
	_history_body.scroll_following = true
	_history_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_history_body.add_theme_font_size_override("normal_font_size", 25)
	_history_body.add_theme_color_override("default_color", Color(0.07, 0.07, 0.075))
	column.add_child(_history_body)


func _make_nav_button(symbol: String) -> Button:
	var button := Button.new()
	button.text = symbol
	button.flat = true
	button.add_theme_font_size_override("font_size", 72)
	button.add_theme_color_override("font_color", Color(0.94, 0.94, 0.9, 0.95))
	button.add_theme_color_override("font_hover_color", Color(1, 0.84, 0.48, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.78, 0.61, 0.28, 1))
	return button


func _add_action_button(parent: Control, label_text: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = label_text
	button.custom_minimum_size = Vector2(0, 68)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 27)
	button.add_theme_color_override("font_color", Color(0.08, 0.08, 0.085))
	button.add_theme_color_override("font_hover_color", Color(0.33, 0.22, 0.08))
	button.add_theme_stylebox_override("normal", _button_style())
	button.add_theme_stylebox_override("hover", _button_style(Color(1, 0.92, 0.72, 1)))
	button.add_theme_stylebox_override("pressed", _button_style(Color(0.88, 0.75, 0.48, 1)))
	button.pressed.connect(callback)
	parent.add_child(button)


func _open_panel() -> void:
	if _is_open:
		return
	if not FlowManager.is_player_interface_available():
		return
	if EventBus != null:
		EventBus.ui_panel_focus_requested.emit(PANEL_ID)
	_is_open = true
	show()
	_summary_panel.hide()
	_history_overlay.hide()
	if GameManager != null:
		GameManager.request_pause(PAUSE_TOKEN)
	if InteractionFeedback != null:
		InteractionFeedback.play_panel_toggle()
	_refresh_all()


func _close_panel() -> void:
	if not _is_open:
		return
	_is_open = false
	_summary_panel.hide()
	_history_overlay.hide()
	hide()
	if GameManager != null:
		GameManager.release_pause(PAUSE_TOKEN)
	if InteractionFeedback != null:
		InteractionFeedback.play_panel_toggle()
	if EventBus != null:
		EventBus.ui_panel_closed.emit(PANEL_ID)


func _on_panel_focus_requested(panel_id: String) -> void:
	if panel_id != PANEL_ID:
		_close_panel()


func _cycle_character(direction: int) -> void:
	_selected_index = wrapi(_selected_index + direction, 0, CHARACTERS.size())
	_summary_panel.hide()
	_refresh_character()
	if InteractionFeedback != null:
		InteractionFeedback.play_panel_toggle()


func _refresh_all() -> void:
	_refresh_character()
	_refresh_task()
	_refresh_history()


func _refresh_character() -> void:
	var character: Dictionary = CHARACTERS[_selected_index]
	var character_id := String(character["id"])
	var revealed := _are_group_portraits_revealed()
	var introed := _var_bool("Ch1.NPCIntro.%s.Introed" % character_id)
	_portrait.texture_normal = load(String(character["portrait"])) as Texture2D
	_portrait.modulate = Color.WHITE if revealed else Color(0.015, 0.015, 0.018, 1)
	_portrait.disabled = not revealed
	_name_label.text = String(character["name"]) if introed else "？？？"
	var affinity := _get_affinity(character_id)
	_affinity_label.text = "信任  %d / 100" % affinity if revealed else "信任  --"
	_affinity_bar.value = affinity
	_affinity_bar.visible = revealed
	_summary_title.text = String(character["name"]) if introed else "？？？"

	var lines: Array[String] = []
	if not introed:
		lines.append("[color=#303030]身份资料　未解锁[/color]")
	else:
		if _var_bool("Ch1.NPCIntro.%s.Selected1" % character_id):
			lines.append("[b]身份[/b]　%s" % String(character["role"]))
		else:
			lines.append("[b]身份[/b]　未解锁")
		if _var_bool("Ch1.NPCIntro.%s.Selected2" % character_id):
			lines.append("[b]来到别墅的原因[/b]　%s" % String(character["reason"]))
		else:
			lines.append("[b]来到别墅的原因[/b]　未解锁")
		if _var_bool("Ch1.NPCIntro.%s.Selected3" % character_id):
			lines.append("[b]接下来的打算[/b]　%s" % String(character["plan"]))
		else:
			lines.append("[b]接下来的打算[/b]　未解锁")
		if _var_bool("Ch1.PrivateChat.%s.Finished" % character_id):
			lines.append("[b]私聊记录[/b]　%s" % String(character["past"]))
		else:
			lines.append("[b]私聊记录[/b]　未解锁")
	_detail_body.text = "\n".join(lines)


func _refresh_task() -> void:
	var task: Dictionary = load("res://scripts/UI/investigation_tasks.gd").current()
	_task_title.text = "当前任务　%s" % task.title
	_task_body.text = String(task.body) + ("（%d/%d）" % [task.found, task.total] if int(task.total) > 0 else "")


func _refresh_history() -> void:
	if Dialogic == null or not Dialogic.has_subsystem("History"):
		_history_body.text = "暂无记录"
		return
	var history: Array = Dialogic.History.get_simple_history()
	if history.is_empty():
		_history_body.text = "暂无记录"
		return
	var dialogue_entries: Array[Dictionary] = []
	for entry_value: Variant in history:
		if not (entry_value is Dictionary):
			continue
		var entry := entry_value as Dictionary
		if String(entry.get("event_type", "")) != "Text":
			continue
		dialogue_entries.append(entry)
	var lines: Array[String] = []
	for index: int in range(maxi(0, dialogue_entries.size() - 14), dialogue_entries.size()):
		var entry: Dictionary = dialogue_entries[index]
		var text_value := String(entry.get("text", "")).strip_edges()
		if text_value.is_empty():
			continue
		var speaker := String(entry.get("character", ""))
		lines.append(("%s：%s" % [speaker, text_value]) if not speaker.is_empty() else text_value)
	_history_body.text = "\n\n".join(lines)
	await get_tree().process_frame
	_history_body.scroll_to_line(maxi(0, _history_body.get_line_count() - 1))


func _open_character_summary() -> void:
	_history_overlay.hide()
	_summary_panel.show()
	if InteractionFeedback != null:
		InteractionFeedback.play_panel_toggle()


func _open_history() -> void:
	_summary_panel.hide()
	_refresh_history()
	_history_overlay.show()
	if InteractionFeedback != null:
		InteractionFeedback.play_panel_toggle()


func _open_clue_manual() -> void:
	_close_panel()
	var clue_panel := get_tree().current_scene.get_node_or_null("CluePanel")
	if clue_panel != null and clue_panel.has_method("open_archive_panel"):
		clue_panel.open_archive_panel()


func _save_game() -> void:
	_status_label.text = "保存中……"
	SaveManager.save_game()


func _load_game() -> void:
	if SaveManager == null or not SaveManager.request_load_game():
		_status_label.text = "没有本地存档"
		return
	_close_panel()
	GameManager.enter_main_menu()
	GameManager.enter_gameplay()
	get_tree().change_scene_to_file("res://scenes/game_root.tscn")


func _on_save_completed(_success: bool, message: String) -> void:
	_status_label.text = message


func _on_load_completed(_success: bool, message: String) -> void:
	_status_label.text = message


func _get_affinity(character_id: String) -> int:
	if Dialogic != null and Dialogic.VAR != null:
		return clampi(int(Dialogic.VAR.get_variable("Affinity.%s" % character_id, 50, true)), 0, 100)
	return 50


func _var_bool(path: String) -> bool:
	return Dialogic != null and Dialogic.VAR != null and bool(Dialogic.VAR.get_variable(path, false, true))


func _are_group_portraits_revealed() -> bool:
	if FlowManager == null:
		return false
	return FlowManager.get_current_step_id() in [
		FlowSteps.CH1_CRIME_SCENE, FlowSteps.CH1_BODY_CG, FlowSteps.CH1_INTRO_HALL,
		FlowSteps.CH1_FIRST_SEARCH, FlowSteps.CH1_INITIAL_REASONING,
		FlowSteps.CH1_PRIVATE_CHAT, FlowSteps.CH1_SECOND_SEARCH,
		FlowSteps.CH2_SECOND_REASONING, FlowSteps.CH2_SECOND_PRIVATE_CHAT,
		FlowSteps.CH2_THIRD_SEARCH, FlowSteps.CH2_THIRD_REASONING,
		FlowSteps.CH2_THIRD_PRIVATE_CHAT,
		FlowSteps.CH2_MEMORY_FRAGMENTS, FlowSteps.CH3_ROUTE,
		FlowSteps.FINALE_ENDING, FlowSteps.FINALE_EPILOGUE, FlowSteps.GAME_COMPLETE,
	]


func _count_completed_introductions() -> int:
	var count := 0
	for character: Dictionary in CHARACTERS:
		var character_id := String(character["id"])
		if _var_bool("Ch1.NPCIntro.%s.Selected1" % character_id) and _var_bool("Ch1.NPCIntro.%s.Selected2" % character_id) and _var_bool("Ch1.NPCIntro.%s.Selected3" % character_id):
			count += 1
	return count


func _count_finished_private_chats() -> int:
	var count := 0
	for character: Dictionary in CHARACTERS:
		if _var_bool("Ch1.PrivateChat.%s.Finished" % String(character["id"])):
			count += 1
	return count


func _count_found_clues(clue_ids: Array) -> int:
	var count := 0
	for clue_id: String in clue_ids:
		if DataManager != null and DataManager.has_clue(clue_id):
			count += 1
	return count


func _dialog_style() -> StyleBox:
	return BOOK.paper_style()


func _bold_font() -> Font:
	return BOOK.display_font()


func _name_style() -> StyleBox:
	return BOOK.cut_style("name")


func _button_style(tint: Color = Color.WHITE) -> StyleBox:
	var style := _dialog_style()
	style.content_margin_left = 18.0
	style.content_margin_top = 8.0
	style.content_margin_right = 18.0
	style.content_margin_bottom = 8.0
	if style is StyleBoxTexture:
		(style as StyleBoxTexture).modulate_color = Color(tint.r, tint.g, tint.b, 0.92)
	return style


func _flat_style(background: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	return style
