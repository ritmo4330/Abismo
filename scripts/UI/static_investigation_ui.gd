extends CanvasLayer


const ROOM_DISPLAY_NAMES: Dictionary = {
	"ch0_black_screen": "继续",
	"ch0_snow_field": "雪原",
	"ch1_study": "书房",
	"shu_fang": "书房",
	"hall": "大厅",
	"floor2": "二楼走廊",
	"zou_lang": "走廊",
	"can_ting": "餐厅",
	"hui_ke_ting": "会客厅",
	"room_lin_jiu": "林玖房间",
	"ch1_crime_scene_lin_room": "林玖房间",
	"room_meta": "梅塔房间",
	"room_mu_zhi": "穆执房间",
	"room_wu_ting_xiang": "乌停湘房间",
	"room_zhong_qi": "钟歧房间",
	"room_zhou_chong_an": "周崇安房间",
	"zhong_yue_lab": "钟岳研究所",
}

var _navigation_panel: PanelContainer = null
var _navigation_row: HFlowContainer = null
var _npc_row: HFlowContainer = null
var _room_name_label: Label = null
var _current_room: Node2D = null
var _target_name_cache: Dictionary = {}
var _portrait_regions: Dictionary = {}
var _last_step_id: String = ""
var _casebook: Control


func _ready() -> void:
	layer = 65
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_interface()
	hide()
	if EventBus != null:
		if not EventBus.room_loaded.is_connected(_on_room_loaded):
			EventBus.room_loaded.connect(_on_room_loaded)
		if not EventBus.dialogue_finished.is_connected(_on_dialogue_finished):
			EventBus.dialogue_finished.connect(_on_dialogue_finished)
	if GameManager != null and not GameManager.game_state_changed.is_connected(_on_game_state_changed):
		GameManager.game_state_changed.connect(_on_game_state_changed)
	if not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)


func _build_interface() -> void:
	_casebook = load("res://scripts/UI/casebook_hub.gd").new()
	add_child(_casebook)
	_casebook.build(self)




func _on_room_loaded(room: Node2D, room_id: String) -> void:
	_current_room = room
	_casebook.room_loaded()
	var art: Node = room.get_node_or_null("StaticRoomArt")
	if art != null and not art.view_changed.is_connected(_on_art_view_changed):
		art.view_changed.connect(_on_art_view_changed)
	_room_name_label.text = String(ROOM_DISPLAY_NAMES.get(room_id, room_id))
	call_deferred("_refresh_navigation")


func _on_art_view_changed() -> void:
	call_deferred("_refresh_navigation")


func _on_dialogue_finished(_timeline_name: String) -> void:
	call_deferred("_refresh_navigation")


func _on_game_state_changed(_previous_state: int, new_state: int) -> void:
	visible = new_state == GameManager.GameState.IN_GAME and FlowManager.is_player_interface_available()


func _process(_delta: float) -> void:
	var step_id: String = FlowManager.get_current_step_id()
	if step_id != _last_step_id:
		_casebook.close_map()
		_last_step_id = step_id
		hide()
		_navigation_panel.hide()
		call_deferred("_refresh_navigation")
		return
	visible = FlowManager.is_player_interface_available() or (_casebook.map_open and not FlowManager.is_story_presentation_active())


func _on_viewport_size_changed() -> void:
	if SceneManager != null and SceneManager.has_method("refresh_static_camera"):
		SceneManager.refresh_static_camera()
	call_deferred("_position_navigation_panel")


func _refresh_navigation() -> void:
	if _casebook.map_open: return
	_last_step_id = FlowManager.get_current_step_id()
	_refresh_actions()
	_casebook.refresh()


func _refresh_actions() -> void:
	if _navigation_row == null:
		return
	for child: Node in _navigation_row.get_children():
		_navigation_row.remove_child(child)
		child.queue_free()
	for child: Node in _npc_row.get_children():
		_npc_row.remove_child(child)
		child.queue_free()
	if _current_room == null or not is_instance_valid(_current_room):
		_navigation_panel.visible = false
		return
	if FlowManager.get_current_chapter_id() == "ch0_prologue":
		_navigation_panel.hide()
		return
	if FlowManager.get_current_step_id() in ["ch1_1_puzzle", "ch1_5_initial_reasoning", "ch2_1_second_reasoning", "ch2_4_third_reasoning"]:
		var button := Button.new()
		button.text = "推理手册"
		button.custom_minimum_size = Vector2(220, 52)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_manual_pressed)
		_navigation_row.add_child(button)
		_npc_row.hide()
		_navigation_panel.show()
		call_deferred("_position_navigation_panel")
		return
	if not _current_room.has_method("setup_camera_limits") or _current_room.has_method("configure_presentation_camera"):
		_navigation_panel.visible = false
		return
	var art: Node = _current_room.get_node_or_null("StaticRoomArt")
	if art != null:
		var view_name: String = String(art.call("get_view_name"))
		if not view_name.is_empty():
			_room_name_label.text = view_name
		if String(art.get("current_view")) in ["", "hall", "villa"]:
			for node: Node in _current_room.find_children("*", "Area2D", true, false):
				if node is NpcDialogue:
					_add_npc_button(node as NpcDialogue)
		if FlowManager.get_current_step_id() != "ch1_3_intro_hall":
			var views: Dictionary = art.call("get_views")
			for view_id: String in views:
				var button := Button.new()
				button.text = String(views[view_id].get("name", view_id))
				button.disabled = String(art.get("current_view")) == view_id
				button.custom_minimum_size = Vector2(148, 48)
				button.focus_mode = Control.FOCUS_NONE
				button.add_theme_font_size_override("font_size", 22)
				button.pressed.connect(_on_view_pressed.bind(view_id))
				_navigation_row.add_child(button)

	var seen_actions: Dictionary = {}
	var next_timeline_trigger: Ch0TimelineTrigger = _find_next_timeline_trigger()
	for node: Node in _current_room.find_children("*", "Area2D", true, false):
		if art != null and String(art.get("current_view")) not in ["", "hall", "villa"]:
			continue
		if not _is_navigation_action(node):
			continue
		if node is Ch0TimelineTrigger and node != next_timeline_trigger:
			continue
		var action_key: String = _get_action_key(node)
		if action_key.is_empty() or seen_actions.has(action_key):
			continue
		seen_actions[action_key] = true
		_add_navigation_button(node)

	_npc_row.visible = _npc_row.get_child_count() > 0
	_navigation_panel.visible = _navigation_row.get_child_count() > 0 or _npc_row.visible
	if _navigation_panel.visible:
		call_deferred("_position_navigation_panel")


func _position_navigation_panel() -> void:
	_casebook._layout()




func _on_view_pressed(view_id: String) -> void:
	_casebook.close_map()
	if not FlowManager.is_free_investigation_active():
		return
	if GameManager.current_state != GameManager.GameState.IN_GAME or SceneManager.is_transitioning:
		return
	if FlowManager.is_current_room_exit_blocked():
		return
	var art: Node = _current_room.get_node_or_null("StaticRoomArt")
	if art != null:
		art.call("set_view", view_id)
		InteractionFeedback.play_panel_toggle()
		call_deferred("_refresh_navigation")


func _on_manual_pressed() -> void:
	if not FlowManager.is_player_interface_available():
		return
	var host: Node = get_tree().current_scene
	var manual: Node = host.get_node_or_null("SuspicionPanel") if host != null else null
	if manual != null:
		manual.call("_open_archive_panel")


func _add_npc_button(npc: NpcDialogue) -> void:
	var portraits: Dictionary = {
		"butler": "butler_neutral.png", "meta": "meta_neutral.png", "mu": "mu_zhi_neutral.png",
		"zhou": "zhou_chong_an_neutral.png", "lin": "lin_jiu_nerutral.png", "wu": "wu_ting_xiang_neutral.png", "zhong": "zhong_qi_neutral.png",
	}
	var names: Dictionary = {"butler": "管家", "meta": "梅塔", "mu": "穆执", "zhou": "周崇安", "lin": "林玖", "wu": "乌停湘", "zhong": "钟歧"}
	var intro_ids: Dictionary = {"mu": "Mu", "zhou": "Zhou", "lin": "Lin", "wu": "Wu", "zhong": "Zhong"}
	var button := Button.new()
	button.custom_minimum_size = Vector2(520, 60)
	preload("res://scripts/UI/casebook_style.gd").style_ribbon(button)
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_on_action_pressed.bind(npc))
	_npc_row.add_child(button)
	_casebook.install_portrait(button, npc)
	var content := HBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 16
	content.offset_right = -28
	content.add_theme_constant_override("separation", 18)
	button.add_child(content)
	var portrait := TextureRect.new()
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.custom_minimum_size = Vector2(48, 48)
	portrait.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	var cameo := ShaderMaterial.new()
	cameo.shader = preload("res://assets/UI/casebook_cameo.gdshader")
	portrait.material = cameo
	var path: String = "res://assets/characters/npcs/" + String(portraits.get(npc.npc_id, ""))
	if ResourceLoader.exists(path):
		var texture: Texture2D = load(path) as Texture2D
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		if not _portrait_regions.has(path):
			var bounds := Rect2(texture.get_image().get_used_rect())
			bounds.size.y *= 0.36
			_portrait_regions[path] = bounds
		atlas.region = _portrait_regions[path]
		portrait.texture = atlas
	content.add_child(portrait)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", 26)
	var intro_id: String = String(intro_ids.get(npc.npc_id, ""))
	var known: bool = intro_id.is_empty() or bool(FlowManager.get_dialogic_var("Ch1.NPCIntro.%s.Introed" % intro_id, false))
	label.text = String(names.get(npc.npc_id, "？？？")) if known else "？？？"
	content.add_child(label)


func _find_next_timeline_trigger() -> Ch0TimelineTrigger:
	var result: Ch0TimelineTrigger = null
	for node: Node in _current_room.find_children("*", "Area2D", true, false):
		if not (node is Ch0TimelineTrigger):
			continue
		if not _is_navigation_action(node):
			continue
		var trigger: Ch0TimelineTrigger = node as Ch0TimelineTrigger
		if result == null or trigger.global_position.x < result.global_position.x:
			result = trigger
	return result


func _is_navigation_action(node: Node) -> bool:
	if node is Door or node is Passage or node is Ch0SceneDoor:
		if FlowManager.get_current_step_id() in ["ch1_1_study_wake", "ch1_1_study_free_investigation", "ch1_1_puzzle"]:
			return false
		if not String(node.get_meta("static_art_view", "")).is_empty():
			return false
		if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
			return false
		return true
	if node is Ch0TimelineTrigger:
		var trigger: Ch0TimelineTrigger = node as Ch0TimelineTrigger
		if trigger.one_shot and trigger._has_triggered:
			return false
		if not trigger.played_flag.is_empty() and DataManager.has_flag(trigger.played_flag):
			return false
		return true
	return false


func _get_action_key(node: Node) -> String:
	if node is Ch0TimelineTrigger:
		return "timeline:%s" % (node as Ch0TimelineTrigger).timeline_name
	var target_path: Variant = node.get("target_scene_path")
	if target_path == null:
		return node.get_path()
	return "scene:%s" % String(target_path)


func _add_navigation_button(action: Node) -> void:
	var button := Button.new()
	button.text = _get_action_label(action)
	button.custom_minimum_size = Vector2(148.0, 48.0)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", Color("302e2b"))
	button.add_theme_color_override("font_hover_color", Color("87443e"))
	button.pressed.connect(_on_action_pressed.bind(action))
	_navigation_row.add_child(button)


func _get_action_label(action: Node) -> String:
	if action is Door and action.flow_signal_name == "exit_second_search":
		return "调查完成"
	if action is Ch0TimelineTrigger:
		return "继续"
	var target_path_value: Variant = action.get("target_scene_path")
	if target_path_value == null:
		return "继续"
	var target_path: String = String(target_path_value)
	if _target_name_cache.has(target_path):
		return String(_target_name_cache[target_path])

	var resolved_path: String = target_path
	if resolved_path.begins_with("uid://"):
		resolved_path = ResourceUID.get_id_path(ResourceUID.text_to_id(resolved_path))
	var display_name: String = String(ROOM_DISPLAY_NAMES.get(resolved_path.get_file().get_basename(), "继续"))
	_target_name_cache[target_path] = display_name
	return display_name


func _on_action_pressed(action: Node) -> void:
	_casebook.close_map()
	if action == null or not is_instance_valid(action):
		return
	if GameManager != null and GameManager.current_state != GameManager.GameState.IN_GAME:
		return
	if SceneManager.is_transitioning:
		return
	if not FlowManager.is_free_investigation_active():
		return
	if InteractionFeedback != null and action is Node2D:
		InteractionFeedback.show_world_interaction(action as Node2D)
	if action.has_method("interact"):
		action.call("interact", SceneManager.current_player as Player)
	call_deferred("_refresh_navigation")
