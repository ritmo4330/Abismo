extends Control

const BOOK = preload("res://scripts/UI/casebook_style.gd")
const TASKS = preload("res://scripts/UI/investigation_tasks.gd")
const PLAN = preload("res://scripts/UI/planning_floor_plan.gd")
const ROUTES = preload("res://scripts/UI/villa_map_routes.gd")
const SOURCE = preload("res://scripts/clues/source_investigation.gd")
const CANVAS := Vector2(1920, 1080)
const TOKEN := "investigation_map"
const PORTRAITS := {"butler": "butler_neutral.png", "meta": "meta_neutral.png", "mu": "mu_zhi_neutral.png", "zhou": "zhou_chong_an_neutral.png", "lin": "lin_jiu_nerutral.png", "wu": "wu_ting_xiang_neutral.png", "zhong": "zhong_qi_neutral.png"}

var _host: Node
var mode := "home"
var map_open := false
var _portrait: TextureRect
var _portrait_shadow: TextureRect
var _portrait_caption: PanelContainer
var _portrait_name: Label
var _portrait_atlases: Dictionary = {}
var _portrait_tween: Tween
var _preview_id := ""
var _portrait_context := ""
var _paper: PanelContainer
var _title: Label
var _actions: VBoxContainer
var _talk_scroll: ScrollContainer
var _talk_back: Button
var _dock: PanelContainer
var _task_title: Label
var _task_body: Label
var _task_progress: ProgressBar
var _map_overlay: Control
var _map_location: Label
var _map_heading: Label
var _map_task: Label
var _floor_plan: Control
var _destinations: Dictionary = {}
var _buttons: Dictionary = {}
var _clock := 0.0
var _travel_to_explore := false
var _space_toggle: Button
var _map_title: Label
var _dream_locations: VBoxContainer
var _pending_subconscious_room := ""

func build(host: Node) -> void:
	_host = host
	name = "InvestigationDesk"
	size = CANVAS
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = BOOK.theme()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_portrait_shadow = TextureRect.new()
	_portrait_shadow.position = Vector2(344, 136)
	_portrait_shadow.size = Vector2(800, 930)
	_portrait_shadow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait_shadow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait_shadow.modulate = Color(0.06, 0.045, 0.03, 0.25)
	add_child(_portrait_shadow)
	_portrait = TextureRect.new()
	_portrait.name = "ContextPortrait"
	_portrait.position = Vector2(330, 126)
	_portrait.size = Vector2(800, 930)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait)
	var location := paper(Vector2(36, 66), Vector2(270, 108))
	location.add_theme_stylebox_override("panel", BOOK.cut_style("location"))
	var location_column := VBoxContainer.new()
	location_column.add_theme_constant_override("separation", 0)
	location.add_child(location_column)
	location_column.add_child(BOOK.label("当前位置", 20))
	_host._room_name_label = BOOK.label("", 32, true)
	location_column.add_child(_host._room_name_label)
	_portrait_caption = paper(Vector2(910, 920), Vector2(260, 104))
	_portrait_caption.add_theme_stylebox_override("panel", BOOK.cut_style("name"))
	var identity := VBoxContainer.new()
	identity.add_theme_constant_override("separation", 2)
	_portrait_caption.add_child(identity)
	identity.add_child(BOOK.label("人物", 19))
	_portrait_name = BOOK.label("", 32, true)
	identity.add_child(_portrait_name)
	_portrait_caption.hide()
	var task := paper(Vector2(36, 770), Vector2(270, 254))
	var task_column := VBoxContainer.new()
	task_column.add_theme_constant_override("separation", 8)
	task.add_child(task_column)
	_task_title = BOOK.label("当前目标", 25, true)
	_task_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_column.add_child(_task_title)
	task_column.add_child(HSeparator.new())
	_task_body = BOOK.label("", 26)
	_task_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	task_column.add_child(_task_body)
	_task_progress = ProgressBar.new()
	_task_progress.custom_minimum_size.y = 5
	_task_progress.show_percentage = false
	_task_progress.add_theme_stylebox_override("background", BOOK.surface(Color("d9cfbd"), 0))
	_task_progress.add_theme_stylebox_override("fill", BOOK.surface(BOOK.RED, 0))
	task_column.add_child(_task_progress)
	_paper = paper(Vector2(1210, 168), Vector2(640, 752))
	_paper.name = "CaseNewspaper"
	BOOK.decorate(_paper, false, "newspaper")
	_host._navigation_panel = _paper
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	_paper.add_child(column)
	var masthead := BOOK.label("异  数", 32, true)
	masthead.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(masthead)
	column.add_child(HSeparator.new())
	_title = BOOK.label("雪墅调查", 23, true)
	_title.add_theme_color_override("font_color", BOOK.MUTED)
	column.add_child(_title)
	_actions = VBoxContainer.new()
	_actions.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_actions.alignment = BoxContainer.ALIGNMENT_CENTER
	_actions.add_theme_constant_override("separation", 8)
	column.add_child(_actions)
	for entry: Array in [["reason", "推理", host._on_manual_pressed], ["talk", "对话", show_dialogues], ["explore", "探索", show_exploration]]:
		var button := BOOK.button(entry[1], entry[2], 68)
		button.custom_minimum_size.y = 102
		button.add_theme_font_override("font", BOOK.display_font())
		button.alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.add_theme_stylebox_override("normal", BOOK.surface(Color.TRANSPARENT, 18))
		button.add_theme_stylebox_override("hover", BOOK.surface(Color(0.48, 0.22, 0.14, 0.055), 18))
		button.add_theme_stylebox_override("pressed", BOOK.surface(Color(0.48, 0.22, 0.14, 0.10), 18))
		_actions.add_child(button)
		_buttons[entry[0]] = button
	_talk_scroll = ScrollContainer.new()
	_talk_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_talk_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(_talk_scroll)
	_host._npc_row = HFlowContainer.new()
	_host._npc_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host._npc_row.add_theme_constant_override("v_separation", 6)
	_talk_scroll.add_child(_host._npc_row)
	_talk_back = BOOK.button("返回调查菜单", show_home, 26)
	_talk_back.custom_minimum_size.y = 50
	column.add_child(_talk_back)
	column.add_child(HSeparator.new())
	var footer := HFlowContainer.new()
	footer.add_theme_constant_override("h_separation", 8)
	footer.add_theme_constant_override("v_separation", 10)
	column.add_child(footer)
	for entry: Array in [["手册", open_clues], ["任务", open_tasks], ["地图", open_map], ["历史", open_history], ["存档", save_game], ["读档", load_game], ["系统", open_system]]:
		var button := BOOK.button(entry[0], entry[1], 23)
		button.custom_minimum_size = Vector2(66, 42)
		footer.add_child(button)
	_dock = paper(Vector2(550, 960), Vector2(820, 84))
	_dock.name = "ExplorationDock"
	_dock.add_theme_stylebox_override("panel", BOOK.paper_style())
	var dock_row := HBoxContainer.new()
	_dock.add_child(dock_row)
	for entry: Array in [["调查菜单", show_home], ["地图", open_map], ["线索", open_clues], ["推理", host._on_manual_pressed]]:
		var button := BOOK.button(entry[0], entry[1], 25)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		dock_row.add_child(button)
	_build_map()
	EventBus.ui_panel_focus_requested.connect(func(_id: String) -> void: close_map())
	_layout()

func paper(at: Vector2, dimensions: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = at
	panel.size = dimensions
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(panel)
	BOOK.decorate(panel)
	return panel

func _build_map() -> void:
	_map_overlay = Control.new()
	_map_overlay.name = "MapOverlay"
	_map_overlay.size = CANVAS
	_map_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_map_overlay)
	var dimmer := ColorRect.new()
	dimmer.size = CANVAS
	dimmer.color = Color(0.02, 0.025, 0.03, 0.63)
	_map_overlay.add_child(dimmer)
	var book := PanelContainer.new()
	book.name = "VillaMapBook"
	book.position = Vector2(120, 55)
	book.size = Vector2(1680, 970)
	_map_overlay.add_child(book)
	BOOK.decorate(book, true)
	var pages := HBoxContainer.new()
	pages.add_theme_constant_override("separation", 58)
	book.add_child(pages)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pages.add_child(left)
	var map_header := HBoxContainer.new()
	left.add_child(map_header)
	_map_title = BOOK.label("别墅 · 平面图", 36, true)
	_map_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_header.add_child(_map_title)
	_space_toggle = BOOK.button("潜意识", _toggle_map_space, 28)
	_space_toggle.name = "SubconsciousMap"
	_space_toggle.custom_minimum_size = Vector2(168, 58)
	map_header.add_child(_space_toggle)
	left.add_child(HSeparator.new())
	_floor_plan = PLAN.new()
	_floor_plan.custom_minimum_size = Vector2(730, 790)
	_floor_plan.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_floor_plan.location_selected.connect(_on_map_selected)
	left.add_child(_floor_plan)
	_dream_locations = VBoxContainer.new()
	_dream_locations.name = "SubconsciousLocations"
	_dream_locations.add_theme_constant_override("separation", 18)
	_dream_locations.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left.add_child(_dream_locations)
	_dream_locations.add_child(BOOK.label("潜意识房间", 34, true))
	for id: String in SOURCE.DREAM_ROOMS:
		var button := BOOK.button(String(SOURCE.DREAM_ROOMS[id].name) + "的潜意识房间", _enter_subconscious_room.bind(id), 30)
		button.name = "Subconscious_" + id
		button.custom_minimum_size.y = 76
		BOOK.style_ribbon(button)
		_dream_locations.add_child(button)
	_dream_locations.hide()
	var right := VBoxContainer.new()
	right.custom_minimum_size.x = 730
	right.add_theme_constant_override("separation", 16)
	pages.add_child(right)
	_map_heading = BOOK.label("当前位置", 24)
	right.add_child(_map_heading)
	_map_location = BOOK.label("", 38, true)
	_map_location.add_theme_color_override("font_color", BOOK.RED)
	right.add_child(_map_location)
	right.add_child(HSeparator.new())
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)
	_host._navigation_row = HFlowContainer.new()
	_host._navigation_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_host._navigation_row.add_theme_constant_override("h_separation", 12)
	_host._navigation_row.add_theme_constant_override("v_separation", 16)
	scroll.add_child(_host._navigation_row)
	right.add_child(BOOK.label("当前目标", 28, true))
	_map_task = BOOK.label("", 26)
	_map_task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_map_task)
	var back := BOOK.button("返回", close_map, 30)
	back.custom_minimum_size = Vector2(140, 62)
	back.size_flags_horizontal = Control.SIZE_SHRINK_END
	BOOK.style_ribbon(back)
	right.add_child(back)
	_map_overlay.hide()

func _layout() -> void:
	var view: Vector2 = get_viewport().get_visible_rect().size
	var ratio: float = minf(view.x / CANVAS.x, view.y / CANVAS.y)
	scale = Vector2.ONE * ratio
	position = (view - CANVAS * ratio) * 0.5

func room_loaded() -> void:
	close_map()
	mode = "explore" if _travel_to_explore or FlowManager.get_current_room_id() in ["ch1_study", "shu_fang", "flower_sea"] else "home"
	_travel_to_explore = false
	_preview_id = ""
	_portrait_context = ""
	if _pending_subconscious_room == String(_host._current_room.get("room_id")):
		call_deferred("_finish_subconscious_travel")

func refresh() -> void:
	_sync_context_portrait()
	if _reasoning(): mode = "home"
	_paper.visible = mode != "explore"
	_dock.visible = mode == "explore"
	_actions.visible = mode == "home"
	_talk_scroll.visible = mode == "talk"
	_talk_back.visible = mode == "talk"
	_title.text = "对话" if mode == "talk" else ("推理" if _reasoning() else "雪墅调查")
	(_buttons.reason as Button).text = "小说谜题" if FlowManager.get_current_step_id() == "ch1_1_puzzle" else "推理"
	(_buttons.talk as Button).disabled = _reasoning() or _host._npc_row.get_child_count() == 0
	(_buttons.explore as Button).disabled = _reasoning()
	_portrait.visible = mode != "explore" and not _preview_id.is_empty()
	_portrait_shadow.visible = _portrait.visible
	_portrait_caption.visible = _portrait.visible
	_refresh_portrait_name()
	_refresh_task()
	_layout()

func _reasoning() -> bool:
	return FlowManager.get_current_step_id() in ["ch1_1_puzzle", "ch1_5_initial_reasoning", "ch2_1_second_reasoning", "ch2_4_third_reasoning"]

func _process(delta: float) -> void:
	if _host == null: return
	_clock -= delta
	if _clock <= 0:
		_clock = 0.5
		_refresh_task()

func _refresh_task() -> void:
	var task: Dictionary = TASKS.current()
	_task_title.text = "当前目标\n" + String(task.title)
	var progress := "\n%d / %d" % [task.found, task.total] if int(task.total) > 0 else ""
	_task_body.text = String(task.body) + progress
	_task_progress.visible = int(task.total) > 0
	_task_progress.max_value = maxf(float(task.total), 1)
	_task_progress.value = float(task.found)
	_map_task.text = String(task.title) + "\n" + String(task.body) + progress

func show_home() -> void:
	mode = "home"
	_sync_context_portrait(true)
	refresh()
	InteractionFeedback.play_panel_toggle()

func show_dialogues() -> void:
	if not FlowManager.is_player_interface_available() or _reasoning(): return
	mode = "talk"
	_sync_context_portrait(true)
	refresh()
	InteractionFeedback.play_panel_toggle()

func show_exploration() -> void:
	if not FlowManager.is_free_investigation_active(): return
	mode = "explore"
	refresh()
	InteractionFeedback.play_panel_toggle()

func preview_character(id: String) -> void:
	if not _portrait_candidates().has(id): return
	if _preview_id == id: return
	_preview_id = id
	var path := "res://assets/characters/npcs/" + String(PORTRAITS.get(id, ""))
	if not ResourceLoader.exists(path): return
	if not _portrait_atlases.has(id):
		var texture: Texture2D = load(path)
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(texture.get_image().get_used_rect())
		_portrait_atlases[id] = atlas
	_portrait.texture = _portrait_atlases[id]
	_portrait_shadow.texture = _portrait.texture
	_portrait.visible = mode != "explore"
	_portrait_shadow.visible = _portrait.visible
	_portrait_caption.visible = _portrait.visible
	_refresh_portrait_name()
	if _portrait_tween != null: _portrait_tween.kill()
	_portrait.modulate = Color(1, 0.985, 0.96, 0.68)
	_portrait_tween = create_tween()
	_portrait_tween.tween_property(_portrait, "modulate", Color(1, 0.985, 0.96, 1), 0.18)

func _refresh_portrait_name() -> void:
	var names := {"butler": "管家", "meta": "梅塔", "mu": "穆执", "zhou": "周崇安", "lin": "林玖", "wu": "乌停湘", "zhong": "钟歧"}
	var intro: String = {"mu": "Mu", "zhou": "Zhou", "lin": "Lin", "wu": "Wu", "zhong": "Zhong"}.get(_preview_id, "")
	var known := intro.is_empty() or bool(FlowManager.get_dialogic_var("Ch1.NPCIntro.%s.Introed" % intro, false))
	_portrait_name.text = String(names.get(_preview_id, "")) if known else "？？？"

func install_portrait(button: Button, npc: NpcDialogue) -> void:
	button.mouse_entered.connect(preview_character.bind(npc.npc_id))

func _portrait_candidates() -> Array[String]:
	var candidates: Array[String] = []
	var room: Node = _host._current_room
	if not is_instance_valid(room): return candidates
	var step: String = FlowManager.get_current_step_id()
	# The butler has left the study. A question directory is not a conversation.
	if step.begins_with("ch1_1_") or FlowManager.get_current_chapter_id() == "ch0_prologue": return candidates
	var art: Node = room.get_node_or_null("StaticRoomArt")
	if art != null and String(art.current_view) not in ["", "hall", "villa"]: return candidates
	for node: Node in room.find_children("*", "Area2D", true, false):
		if node is NpcDialogue and not node.is_queued_for_deletion() and PORTRAITS.has(node.npc_id) and not candidates.has(node.npc_id):
			candidates.append(node.npc_id)
	return candidates

func _sync_context_portrait(reroll: bool = false) -> void:
	var candidates := _portrait_candidates()
	var room: Node = _host._current_room
	var context := "%s/%s/%s" % [room.get_instance_id() if is_instance_valid(room) else 0, FlowManager.get_current_step_id(), ",".join(candidates)]
	if not reroll and _portrait_context == context and (candidates.has(_preview_id) or candidates.is_empty()): return
	_portrait_context = context
	if candidates.is_empty():
		_preview_id = ""
		_portrait.texture = null
		_portrait_shadow.texture = null
		_portrait.hide()
		_portrait_shadow.hide()
		_portrait_caption.hide()
		return
	var choices: Array[String] = candidates.duplicate()
	# Default hall portraits show a guest, while hovering the butler remains valid.
	if choices.size() > 1: choices.erase("butler")
	if reroll and choices.size() > 1: choices.erase(_preview_id)
	preview_character(choices.pick_random())

func open_map(task_page: bool = false) -> void:
	if not FlowManager.is_player_interface_available(): return
	if not task_page and not FlowManager.is_free_investigation_active(): return
	_host._refresh_navigation()
	_destinations.clear()
	var locked: bool = task_page or FlowManager.get_current_step_id() in ["ch1_1_study_free_investigation", "ch1_3_intro_hall"]
	if not locked:
		for node: Node in _host._current_room.find_children("*", "Area2D", true, false):
			if _host._is_navigation_action(node):
				var path_value: Variant = node.get("target_scene_path")
				if path_value == null: continue
				var path := String(path_value)
				if path.is_empty(): continue
				if path.begins_with("uid://"): path = ResourceUID.get_id_path(ResourceUID.text_to_id(path))
				_destinations[PLAN.canonical(path.get_file().get_basename())] = node
	for button: Node in _host._navigation_row.get_children():
		(button as Button).disabled = locked
	var room_id: String = String(_host._current_room.get("room_id"))
	if not locked:
		var routes: Dictionary = ROUTES.reachable(room_id)
		for id: String in routes:
			if _destinations.has(id): continue
			_destinations[id] = routes[id]
			var label: String = String(_host.ROOM_DISPLAY_NAMES.get(id, id))
			var option := BOOK.button(label, _on_map_selected.bind(id), 26)
			option.custom_minimum_size = Vector2(290, 52)
			_host._navigation_row.add_child(option)
	var art: Node = _host._current_room.get_node_or_null("StaticRoomArt")
	if art != null and not locked:
		for view_id: String in art.get_views():
			if view_id in ["villa", "subconscious"]: continue
			# The floor plan's hall button must also return from kitchen,
			# pantry and storeroom views, not point to a missing view:hall cell.
			_destinations["hall" if view_id == "hall" else "view:" + view_id] = view_id
		if String(art.current_view) not in ["", "hall", "villa", "subconscious"]:
			room_id = "view:" + String(art.current_view)
	_floor_plan.configure(room_id, _destinations)
	_space_toggle.visible = not task_page and FlowManager.get_current_chapter_id() in ["ch2_deepening", "ch3_transcend"]
	_space_toggle.disabled = locked or not SOURCE.available()
	_space_toggle.tooltip_text = "第三轮搜证开启潜意识房间" if _space_toggle.disabled else "分别进入每个人的潜意识房间"
	_space_toggle.text = "潜意识"
	_map_title.text = "别墅 · 平面图"
	_floor_plan.show()
	_dream_locations.hide()
	for node: Node in _host._navigation_row.get_children():
		var option := node as Button
		if option == null: continue
		option.custom_minimum_size = Vector2(290, 58)
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		BOOK.style_ribbon(option)
	_host._navigation_row.get_parent().visible = not task_page
	_map_location.text = String(TASKS.current().title) if task_page else _host._room_name_label.text
	_map_heading.text = "当前任务" if task_page else "当前位置"
	_map_task.add_theme_font_size_override("font_size", 36 if task_page else 26)
	_map_task.size_flags_vertical = Control.SIZE_EXPAND_FILL if task_page else Control.SIZE_SHRINK_BEGIN
	map_open = true
	_map_overlay.show()
	GameManager.request_pause(TOKEN)
	InteractionFeedback.play_panel_toggle()

func open_tasks() -> void:
	open_map(true)

func _toggle_map_space() -> void:
	if _space_toggle.disabled: return
	var subconscious := not _dream_locations.visible
	_floor_plan.visible = not subconscious
	_dream_locations.visible = subconscious
	_space_toggle.text = "别墅" if subconscious else "潜意识"
	_map_title.text = "潜意识 · 房间" if subconscious else "别墅 · 平面图"
	_host._navigation_row.get_parent().visible = not subconscious
	for child: Node in _dream_locations.get_children():
		if child is Button:
			var id := String(child.name).trim_prefix("Subconscious_")
			child.disabled = id != String(_host._current_room.get("room_id")) and not ROUTES.reachable(String(_host._current_room.get("room_id"))).has(id)

func _enter_subconscious_room(room_id: String) -> void:
	if not SOURCE.available(): return
	_pending_subconscious_room = room_id
	close_map()
	if String(_host._current_room.get("room_id")) == room_id:
		_finish_subconscious_travel()
	else:
		_travel_to_explore = true
		if not ROUTES.travel(room_id): _pending_subconscious_room = ""

func _finish_subconscious_travel() -> void:
	while SceneManager.is_transitioning:
		await get_tree().process_frame
	if _pending_subconscious_room != String(_host._current_room.get("room_id")): return
	_pending_subconscious_room = ""
	var art: Node = _host._current_room.get_node_or_null("StaticRoomArt")
	if art != null: art.set_view("subconscious")
	show_exploration()

func _on_map_selected(id: String) -> void:
	if id == _floor_plan.current_room:
		close_map()
		show_exploration()
		return
	if not _destinations.has(id): return
	if _destinations[id] is Dictionary:
		close_map()
		_travel_to_explore = true
		if not ROUTES.travel(id): _travel_to_explore = false
	elif _destinations[id] is String:
		_host._on_view_pressed(_destinations[id])
	else:
		_travel_to_explore = true
		_host._on_action_pressed(_destinations[id])

func close_map() -> void:
	if not map_open: return
	map_open = false
	_map_overlay.hide()
	GameManager.release_pause(TOKEN)

func _exit_tree() -> void:
	if map_open: GameManager.release_pause(TOKEN)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_M or event.physical_keycode == KEY_M):
		if map_open: close_map()
		elif FlowManager.is_free_investigation_active(): open_map()
		else: return
		get_viewport().set_input_as_handled()
		return
	if map_open and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		close_map()
		get_viewport().set_input_as_handled()

func open_clues() -> void:
	_open_panel("CluePanel", "_open_archive_panel")

func open_system() -> void:
	_open_panel("SystemPanel", "_open_panel")

func open_history() -> void:
	open_system()
	var panel: Node = get_tree().current_scene.get_node_or_null("SystemPanel")
	if panel != null and panel.visible: panel.call("_open_history")

func _open_panel(node_name: String, method: String) -> void:
	close_map()
	if not FlowManager.is_player_interface_available(): return
	var panel: Node = get_tree().current_scene.get_node_or_null(NodePath(node_name))
	if panel != null: panel.call(method)

func save_game() -> void:
	if FlowManager.is_player_interface_available(): SaveManager.save_game()

func load_game() -> void:
	if not FlowManager.is_player_interface_available() or not SaveManager.request_load_game(): return
	GameManager.enter_main_menu()
	GameManager.enter_gameplay()
	get_tree().change_scene_to_file("res://scenes/game_root.tscn")
