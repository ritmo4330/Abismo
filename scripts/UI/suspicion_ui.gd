extends CanvasLayer

const PANEL_SIZE: Vector2 = Vector2(1560.0, 900.0)
const PANEL_ID: String = "suspicion_panel"
const PANEL_PAUSE_TOKEN: String = "suspicion_panel"
const ARCHIVE_SORT_DEFAULT: int = 0
const ARCHIVE_SORT_DISCOVER: int = 1
const MIN_SLOT_COUNT: int = 1

@onready var panel_frame: PanelContainer = $PanelRoot/PanelFrame
@onready var close_button: Button = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/HeaderBar/CloseButton
@onready var search_line_edit: LineEdit = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/SearchRow/SearchLineEdit
@onready var sort_option_button: OptionButton = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/SearchRow/SortOptionButton
@onready var suspicion_tree: Tree = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/LeftPane/LeftVBox/SuspicionTree
@onready var detail_title: Label = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/DetailTop/DetailTitle
@onready var detail_body: RichTextLabel = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/DetailTop/DetailBody
@onready var slot_row: HBoxContainer = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/ReasoningPanel/ReasoningVBox/SlotRow
@onready var slot_buttons: Array[Button] = [
	$PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/ReasoningPanel/ReasoningVBox/SlotRow/SlotButton1,
	$PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/ReasoningPanel/ReasoningVBox/SlotRow/SlotButton2,
	$PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/ReasoningPanel/ReasoningVBox/SlotRow/SlotButton3,
]
@onready var reason_button: Button = $PanelRoot/PanelFrame/FrameMargin/FrameVBox/BodySplit/RightPane/RightVBox/ReasoningPanel/ReasoningVBox/ReasonButton

var _is_open: bool = false
var _suppress_tree_selected_callback: bool = false
var _refresh_queued: bool = false
var _selected_suspicion_id: String = ""
var _archive_sort_mode: int = ARCHIVE_SORT_DEFAULT
var _slot_ids_by_suspicion: Dictionary = {}
var _locked_suspicion_id: String = ""
var _locked_conclusion_followup_timeline: String = ""
var _locked_suspicion_resolved: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process_input(true)
	hide()

	suspicion_tree.hide_root = true
	suspicion_tree.columns = 1
	sort_option_button.clear()
	sort_option_button.add_item("默认")
	sort_option_button.add_item("按发现时间")
	sort_option_button.select(ARCHIVE_SORT_DEFAULT)

	if not close_button.pressed.is_connected(_on_close_button_pressed):
		close_button.pressed.connect(_on_close_button_pressed)
	if not search_line_edit.text_changed.is_connected(_on_search_text_changed):
		search_line_edit.text_changed.connect(_on_search_text_changed)
	if not sort_option_button.item_selected.is_connected(_on_sort_option_button_item_selected):
		sort_option_button.item_selected.connect(_on_sort_option_button_item_selected)
	if not suspicion_tree.item_selected.is_connected(_on_suspicion_tree_item_selected):
		suspicion_tree.item_selected.connect(_on_suspicion_tree_item_selected)
	if not reason_button.pressed.is_connected(_on_reason_button_pressed):
		reason_button.pressed.connect(_on_reason_button_pressed)

	for i: int in slot_buttons.size():
		var slot_button: Button = slot_buttons[i]
		if not slot_button.pressed.is_connected(_on_slot_button_pressed):
			slot_button.pressed.connect(_on_slot_button_pressed.bind(i))

	if get_viewport() != null and not get_viewport().size_changed.is_connected(_on_viewport_size_changed):
		get_viewport().size_changed.connect(_on_viewport_size_changed)

	if DataManager != null and not DataManager.suspicion_updated.is_connected(_on_suspicion_updated):
		DataManager.suspicion_updated.connect(_on_suspicion_updated)
	if EventBus != null and not EventBus.clue_selected_for_reasoning.is_connected(_on_clue_selected_for_reasoning):
		EventBus.clue_selected_for_reasoning.connect(_on_clue_selected_for_reasoning)
	if EventBus != null and not EventBus.ui_panel_focus_requested.is_connected(_on_ui_panel_focus_requested):
		EventBus.ui_panel_focus_requested.connect(_on_ui_panel_focus_requested)
	if EventBus != null and not EventBus.ui_panel_closed.is_connected(_on_ui_panel_closed):
		EventBus.ui_panel_closed.connect(_on_ui_panel_closed)
	if EventBus != null and not EventBus.locked_suspicion_requested.is_connected(_on_locked_suspicion_requested):
		EventBus.locked_suspicion_requested.connect(_on_locked_suspicion_requested)

	_on_viewport_size_changed()
	_render_empty_state("暂无可显示的疑点。")


func _input(event: InputEvent) -> void:
	if _is_toggle_input(event):
		if _is_open:
			if _is_locked_and_unresolved():
				_show_locked_notice()
				get_viewport().set_input_as_handled()
				return
			_close_panel()
		else:
			if _is_locked_session_active():
				_open_locked_panel()
			else:
				_open_archive_panel()
		get_viewport().set_input_as_handled()
		return

	if not _is_open:
		return

	if _is_close_input(event):
		if _is_locked_and_unresolved():
			_show_locked_notice()
			get_viewport().set_input_as_handled()
			return
		_close_panel()
		get_viewport().set_input_as_handled()


func _on_close_button_pressed() -> void:
	if _is_locked_and_unresolved():
		_show_locked_notice()
		return
	_close_panel()


func _on_search_text_changed(_new_text: String) -> void:
	_refresh_suspicion_tree()


func _on_sort_option_button_item_selected(index: int) -> void:
	_archive_sort_mode = index
	_refresh_suspicion_tree()


func _on_suspicion_tree_item_selected() -> void:
	if _suppress_tree_selected_callback:
		return

	var item: TreeItem = suspicion_tree.get_selected()
	if item == null:
		return

	var suspicion_id_variant: Variant = item.get_metadata(0)
	if not (suspicion_id_variant is String):
		return

	var suspicion_id: String = String(suspicion_id_variant)
	if suspicion_id.is_empty():
		return
	if _is_locked_and_unresolved() and suspicion_id != _locked_suspicion_id:
		_select_suspicion_in_tree(_locked_suspicion_id)
		_show_locked_notice()
		return

	_selected_suspicion_id = suspicion_id
	_show_suspicion_detail(suspicion_id, true)


func _on_suspicion_updated(_suspicion_id: String) -> void:
	if not _is_open:
		return
	_queue_refresh()


func _on_slot_button_pressed(slot_index: int) -> void:
	if _selected_suspicion_id.is_empty():
		return
	if DataManager.is_suspicion_resolved(_selected_suspicion_id):
		return

	var context: Dictionary = {
		"source": "suspicion_ui",
		"suspicion_id": _selected_suspicion_id,
		"slot_index": slot_index,
	}
	EventBus.clue_selection_requested.emit(context)


func _on_reason_button_pressed() -> void:
	if _selected_suspicion_id.is_empty():
		return
	if DataManager.is_suspicion_resolved(_selected_suspicion_id):
		return

	var selected_ids: Array[String] = _get_slot_ids(_selected_suspicion_id)
	if not _are_all_slots_filled(selected_ids):
		return

	var suspicion_def: SuspicionData = _get_suspicion_def(_selected_suspicion_id)
	if suspicion_def == null:
		return

	if not ReasoningSystem.validate(suspicion_def, PackedStringArray(selected_ids)):
		_show_reasoning_notice("还不对哦，再想想", "warning")
		return

	if not DataManager.resolve_suspicion(_selected_suspicion_id):
		return

	_show_reasoning_notice("推理成功！", "success")
	_handle_locked_suspicion_resolved(_selected_suspicion_id)

	if not suspicion_def.conclusion_clue_id.is_empty():
		var payload: Dictionary = {
			"display_type": "single",
			"parent_clue_id": suspicion_def.conclusion_clue_id,
			"clue_ids": [suspicion_def.conclusion_clue_id],
		}
		var followup_timeline: String = suspicion_def.resolution_timeline
		if _selected_suspicion_id == _locked_suspicion_id and not _locked_conclusion_followup_timeline.is_empty():
			followup_timeline = _locked_conclusion_followup_timeline
		if not followup_timeline.is_empty():
			payload["followup_timeline"] = followup_timeline
		EventBus.clue_interaction_details_requested.emit(payload)
		return

	var timeline_after_resolution: String = suspicion_def.resolution_timeline
	if _selected_suspicion_id == _locked_suspicion_id and not _locked_conclusion_followup_timeline.is_empty():
		timeline_after_resolution = _locked_conclusion_followup_timeline
	if not timeline_after_resolution.is_empty():
		_close_panel()
		call_deferred("_request_resolution_timeline", timeline_after_resolution)


func _on_clue_selected_for_reasoning(context: Dictionary, clue_id: String) -> void:
	if String(context.get("source", "")) != "suspicion_ui":
		return
	if clue_id.is_empty():
		return

	var suspicion_id: String = String(context.get("suspicion_id", ""))
	var slot_index: int = int(context.get("slot_index", -1))
	if suspicion_id.is_empty():
		return
	if slot_index < 0 or slot_index >= _get_required_slot_count(suspicion_id):
		return

	var selected_ids: Array[String] = _get_slot_ids(suspicion_id)
	for i: int in selected_ids.size():
		if i != slot_index and selected_ids[i] == clue_id:
			selected_ids[i] = ""
	selected_ids[slot_index] = clue_id
	_store_slot_ids(suspicion_id, selected_ids)

	_selected_suspicion_id = suspicion_id
	if _is_locked_session_active():
		_open_locked_panel()
	else:
		_open_archive_panel()


func _on_ui_panel_focus_requested(panel_id: String) -> void:
	if panel_id == PANEL_ID:
		return
	_close_panel()


func _on_ui_panel_closed(panel_id: String) -> void:
	if panel_id != "clue_panel":
		return
	if not _is_locked_and_unresolved():
		return
	if _is_open:
		return
	call_deferred("_open_locked_panel")


func _on_locked_suspicion_requested(suspicion_id: String, conclusion_followup_timeline: String) -> void:
	if suspicion_id.is_empty():
		return
	if DataManager == null:
		return
	if not DataManager.has_suspicion(suspicion_id):
		DataManager.add_suspicion(suspicion_id, "flow", "locked_suspicion")
	_locked_suspicion_id = suspicion_id
	_locked_conclusion_followup_timeline = conclusion_followup_timeline
	_locked_suspicion_resolved = DataManager.is_suspicion_resolved(suspicion_id)
	_selected_suspicion_id = suspicion_id
	_open_locked_panel()


func _on_viewport_size_changed() -> void:
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return

	var scale_ratio: float = min(viewport_size.x / PANEL_SIZE.x, viewport_size.y / PANEL_SIZE.y)
	scale_ratio = min(scale_ratio, 1.0)

	panel_frame.size = PANEL_SIZE
	panel_frame.scale = Vector2(scale_ratio, scale_ratio)

	var scaled_size: Vector2 = PANEL_SIZE * scale_ratio
	panel_frame.position = (viewport_size - scaled_size) * 0.5


func _open_archive_panel() -> bool:
	if not _can_open_panel():
		return false

	_open_panel()
	_refresh_suspicion_tree()
	return true


func _open_locked_panel() -> bool:
	if _locked_suspicion_id.is_empty():
		return false
	if not _can_open_panel():
		return false

	_selected_suspicion_id = _locked_suspicion_id
	search_line_edit.text = ""
	_open_panel()
	_update_lock_widgets()
	_refresh_suspicion_tree()
	return true


func _open_panel() -> void:
	if not _is_open:
		EventBus.ui_panel_focus_requested.emit(PANEL_ID)
		_is_open = true
		show()
		if GameManager != null and GameManager.has_method("request_pause"):
			GameManager.request_pause(PANEL_PAUSE_TOKEN)


func _close_panel() -> void:
	if not _is_open:
		return

	_is_open = false
	hide()
	EventBus.ui_panel_closed.emit(PANEL_ID)
	if GameManager != null and GameManager.has_method("release_pause"):
		GameManager.release_pause(PANEL_PAUSE_TOKEN)
	if _is_locked_session_active() and not _is_locked_and_unresolved():
		_clear_locked_suspicion()


func _can_open_panel() -> bool:
	if SceneManager != null and SceneManager.is_transitioning:
		return false
	if GameManager != null and int(GameManager.current_state) == int(GameManager.GameState.DIALOGUE):
		return false
	if not _is_manual_access_unlocked():
		_show_manual_locked_notice()
		return false
	if GameManager == null:
		return true
	return true


func _queue_refresh() -> void:
	if _refresh_queued:
		return
	_refresh_queued = true
	call_deferred("_deferred_refresh_suspicion_tree")


func _deferred_refresh_suspicion_tree() -> void:
	_refresh_queued = false
	if not _is_open:
		return
	_refresh_suspicion_tree()


func _refresh_suspicion_tree() -> void:
	suspicion_tree.clear()
	var root: TreeItem = suspicion_tree.create_item()
	if root == null:
		_render_empty_state("疑点目录刷新失败，请重试。")
		return

	var category_items: Dictionary[String, TreeItem] = {}
	var first_suspicion_item: TreeItem = null
	var suspicion_items_by_id: Dictionary[String, TreeItem] = {}
	var filter_text: String = search_line_edit.text.strip_edges().to_lower()
	var discovered_ids: Array[String] = _get_sorted_discovered_suspicion_ids()

	for suspicion_id: String in discovered_ids:
		var suspicion_def: SuspicionData = _get_suspicion_def(suspicion_id)
		if suspicion_def == null:
			continue
		if _is_locked_session_active() and suspicion_id != _locked_suspicion_id:
			continue
		if not _is_suspicion_matching_filter(suspicion_id, suspicion_def, filter_text):
			continue

		var parent_item: TreeItem = root
		var path_key: String = ""
		var category_path: PackedStringArray = _get_normalized_category_path(suspicion_def)
		for segment_raw: String in category_path:
			var segment: String = segment_raw.strip_edges()
			if segment.is_empty():
				continue

			if path_key.is_empty():
				path_key = segment
			else:
				path_key = "%s/%s" % [path_key, segment]

			if not category_items.has(path_key):
				var category_item: TreeItem = suspicion_tree.create_item(parent_item)
				if category_item == null:
					continue
				category_item.set_text(0, segment)
				category_item.set_selectable(0, false)
				category_items[path_key] = category_item

			var next_parent: TreeItem = category_items.get(path_key, null)
			if next_parent == null:
				next_parent = root
			parent_item = next_parent

		var suspicion_item: TreeItem = suspicion_tree.create_item(parent_item)
		if suspicion_item == null:
			continue
		suspicion_item.set_metadata(0, suspicion_id)
		suspicion_item.set_text(0, _build_suspicion_tree_title(suspicion_id, suspicion_def))
		suspicion_items_by_id[suspicion_id] = suspicion_item
		if first_suspicion_item == null:
			first_suspicion_item = suspicion_item

	if first_suspicion_item == null:
		_render_empty_state("未找到符合条件的疑点。")
		return

	var selected_item: TreeItem = null
	if not _selected_suspicion_id.is_empty() and suspicion_items_by_id.has(_selected_suspicion_id):
		selected_item = suspicion_items_by_id[_selected_suspicion_id]
	else:
		selected_item = first_suspicion_item

	if selected_item == null:
		_render_empty_state("未找到符合条件的疑点。")
		return

	var selected_suspicion_id_variant: Variant = selected_item.get_metadata(0)
	if selected_suspicion_id_variant is String:
		_selected_suspicion_id = String(selected_suspicion_id_variant)

	_suppress_tree_selected_callback = true
	suspicion_tree.set_selected(selected_item, 0)
	_suppress_tree_selected_callback = false
	_show_suspicion_detail(_selected_suspicion_id, false)


func _select_suspicion_in_tree(suspicion_id: String) -> void:
	if suspicion_id.is_empty():
		return
	_selected_suspicion_id = suspicion_id
	_refresh_suspicion_tree()


func _show_suspicion_detail(suspicion_id: String, mark_read: bool = false) -> void:
	var suspicion_def: SuspicionData = _get_suspicion_def(suspicion_id)
	if suspicion_def == null:
		detail_title.text = suspicion_id
		detail_body.text = "未找到该疑点的数据定义。"
		_update_reasoning_panel()
		return

	var title: String = suspicion_def.title
	if title.is_empty():
		title = suspicion_id
	detail_title.text = title

	var state: Dictionary = DataManager.get_suspicion_state(suspicion_id)
	var section_lines: PackedStringArray = PackedStringArray()
	if not suspicion_def.chapter_id.is_empty():
		section_lines.append("章节：%s" % suspicion_def.chapter_id)
	if not suspicion_def.tags.is_empty():
		section_lines.append("标签：%s" % ", ".join(suspicion_def.tags))
	if bool(state.get("resolved", false)):
		section_lines.append("状态：已解决")
		var conclusion_clue_id: String = String(state.get("conclusion_clue_id", suspicion_def.conclusion_clue_id))
		if not conclusion_clue_id.is_empty():
			section_lines.append("结论：%s" % _get_clue_title(conclusion_clue_id))
	else:
		section_lines.append("状态：未解决")

	var body: String = suspicion_def.description
	if body.is_empty():
		body = "（暂无疑点描述）"

	if section_lines.is_empty():
		detail_body.text = body
	else:
		detail_body.text = "%s\n\n%s" % ["\n".join(section_lines), body]

	if mark_read:
		DataManager.mark_suspicion_read(suspicion_id)

	_update_reasoning_panel()


func _update_reasoning_panel() -> void:
	var disabled: bool = _selected_suspicion_id.is_empty()
	if not disabled:
		disabled = DataManager.is_suspicion_resolved(_selected_suspicion_id)

	var slot_count: int = _get_required_slot_count(_selected_suspicion_id)
	_ensure_slot_button_count(slot_count)

	var selected_ids: Array[String] = _get_slot_ids(_selected_suspicion_id, slot_count)
	for i: int in slot_buttons.size():
		var slot_button: Button = slot_buttons[i]
		slot_button.visible = i < slot_count
		if not slot_button.visible:
			continue
		slot_button.disabled = disabled
		var clue_id: String = selected_ids[i]
		if clue_id.is_empty():
			slot_button.text = "线索位 %d：点击选择" % (i + 1)
		else:
			slot_button.text = _get_clue_title(clue_id)

	reason_button.disabled = disabled or not _are_all_slots_filled(selected_ids)


func _handle_locked_suspicion_resolved(suspicion_id: String) -> void:
	if suspicion_id.is_empty():
		return
	if suspicion_id != _locked_suspicion_id:
		return
	_locked_suspicion_resolved = true
	_update_lock_widgets()


func _update_lock_widgets() -> void:
	var is_locked: bool = _is_locked_and_unresolved()
	close_button.disabled = is_locked
	search_line_edit.editable = not is_locked
	sort_option_button.disabled = is_locked


func _is_locked_session_active() -> bool:
	return not _locked_suspicion_id.is_empty()


func _is_locked_and_unresolved() -> bool:
	if _locked_suspicion_id.is_empty():
		return false
	if _locked_suspicion_resolved:
		return false
	if DataManager != null and DataManager.is_suspicion_resolved(_locked_suspicion_id):
		_locked_suspicion_resolved = true
		return false
	return true


func _clear_locked_suspicion() -> void:
	_locked_suspicion_id = ""
	_locked_conclusion_followup_timeline = ""
	_locked_suspicion_resolved = false
	close_button.disabled = false
	search_line_edit.editable = true
	sort_option_button.disabled = false


func _show_locked_notice() -> void:
	if ToastManager == null:
		return
	ToastManager.show_notice("先解决当前疑点。", "warning", 1.8)


func _render_empty_state(message: String) -> void:
	_selected_suspicion_id = ""
	detail_title.text = "疑点详情"
	detail_body.text = message
	_update_reasoning_panel()


func _ensure_slot_button_count(slot_count: int) -> void:
	slot_count = max(MIN_SLOT_COUNT, slot_count)
	while slot_buttons.size() < slot_count:
		var slot_button: Button = Button.new()
		slot_button.name = "SlotButton%d" % (slot_buttons.size() + 1)
		slot_button.custom_minimum_size = Vector2(0.0, 120.0)
		slot_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_row.add_child(slot_button)
		var slot_index: int = slot_buttons.size()
		slot_button.pressed.connect(_on_slot_button_pressed.bind(slot_index))
		slot_buttons.append(slot_button)


func _get_required_slot_count(suspicion_id: String) -> int:
	var suspicion_def: SuspicionData = _get_suspicion_def(suspicion_id)
	if suspicion_def == null:
		return MIN_SLOT_COUNT
	if suspicion_def.required_clue_ids.is_empty():
		return MIN_SLOT_COUNT
	return max(MIN_SLOT_COUNT, suspicion_def.required_clue_ids.size())


func _request_resolution_timeline(timeline_name: String) -> void:
	if timeline_name.is_empty():
		return
	EventBus.dialogue_requested.emit(timeline_name)


func _show_reasoning_notice(message: String, notice_type: String) -> void:
	if ToastManager == null:
		return
	ToastManager.show_notice(message, notice_type)


func _get_sorted_discovered_suspicion_ids() -> Array[String]:
	var ids: Array[String] = []
	for suspicion_id: String in DataManager.get_all_suspicions():
		ids.append(suspicion_id)

	if _archive_sort_mode == ARCHIVE_SORT_DISCOVER:
		ids.sort_custom(_sort_suspicions_by_discover_order)
		return ids

	ids.sort_custom(_sort_suspicions_by_default_order)
	return ids


func _sort_suspicions_by_discover_order(a: String, b: String) -> bool:
	return _get_discover_order(a) < _get_discover_order(b)


func _sort_suspicions_by_default_order(a: String, b: String) -> bool:
	var key_a: Array = _build_default_order_key(a)
	var key_b: Array = _build_default_order_key(b)
	return _is_order_key_less(key_a, key_b)


func _build_default_order_key(suspicion_id: String) -> Array:
	var suspicion_def: SuspicionData = _get_suspicion_def(suspicion_id)
	if suspicion_def == null:
		return [999, "", suspicion_id]
	var chapter_rank: int = _safe_to_int(suspicion_def.chapter_id, 999)
	return [chapter_rank, "/".join(suspicion_def.category_path), suspicion_def.title, suspicion_id]


func _is_order_key_less(left: Array, right: Array) -> bool:
	var compare_count: int = min(left.size(), right.size())
	for i: int in compare_count:
		if left[i] == right[i]:
			continue
		return left[i] < right[i]
	return left.size() < right.size()


func _build_suspicion_tree_title(suspicion_id: String, suspicion_def: SuspicionData) -> String:
	var title: String = suspicion_id
	if suspicion_def != null and not suspicion_def.title.is_empty():
		title = suspicion_def.title
	if DataManager.is_suspicion_resolved(suspicion_id):
		title = "%s（已解决）" % title

	var state: Dictionary = DataManager.get_suspicion_state(suspicion_id)
	if bool(state.get("read", false)):
		return title
	return "● %s" % title


func _get_normalized_category_path(suspicion_def: SuspicionData) -> PackedStringArray:
	if suspicion_def == null:
		return PackedStringArray(["未分类"])
	if suspicion_def.category_path.is_empty():
		return PackedStringArray(["未分类"])
	return suspicion_def.category_path


func _is_suspicion_matching_filter(suspicion_id: String, suspicion_def: SuspicionData, filter_text: String) -> bool:
	if filter_text.is_empty():
		return true

	var title: String = suspicion_id.to_lower()
	var description: String = ""
	var tags_text: String = ""
	var category_text: String = ""

	if suspicion_def != null:
		title = suspicion_def.title.to_lower()
		description = suspicion_def.description.to_lower()
		tags_text = ",".join(suspicion_def.tags).to_lower()
		category_text = "/".join(suspicion_def.category_path).to_lower()

	return title.contains(filter_text) \
		or description.contains(filter_text) \
		or tags_text.contains(filter_text) \
		or category_text.contains(filter_text)


func _get_suspicion_def(suspicion_id: String) -> SuspicionData:
	if suspicion_id.is_empty():
		return null
	if DataManager == null:
		return null
	if not DataManager.suspicion_defs.has(suspicion_id):
		return null

	var suspicion_def_variant: Variant = DataManager.suspicion_defs.get(suspicion_id, null)
	if suspicion_def_variant is SuspicionData:
		return suspicion_def_variant as SuspicionData
	return null


func _get_clue_title(clue_id: String) -> String:
	if clue_id.is_empty():
		return ""
	if DataManager == null or not DataManager.clue_defs.has(clue_id):
		return clue_id
	var clue_def_variant: Variant = DataManager.clue_defs.get(clue_id, null)
	if clue_def_variant is ClueData:
		var clue_def: ClueData = clue_def_variant as ClueData
		if not clue_def.title.is_empty():
			return clue_def.title
	return clue_id


func _get_slot_ids(suspicion_id: String, slot_count: int = -1) -> Array[String]:
	if slot_count < MIN_SLOT_COUNT:
		slot_count = _get_required_slot_count(suspicion_id)

	var result: Array[String] = []
	for _i: int in slot_count:
		result.append("")
	if suspicion_id.is_empty():
		return result
	if not _slot_ids_by_suspicion.has(suspicion_id):
		return result

	var stored_value: Variant = _slot_ids_by_suspicion.get(suspicion_id, [])
	if not (stored_value is Array):
		return result

	var stored_ids: Array = stored_value
	for i: int in min(stored_ids.size(), slot_count):
		result[i] = String(stored_ids[i])
	return result


func _store_slot_ids(suspicion_id: String, selected_ids: Array[String]) -> void:
	if suspicion_id.is_empty():
		return
	_slot_ids_by_suspicion[suspicion_id] = selected_ids.duplicate()


func _are_all_slots_filled(selected_ids: Array[String]) -> bool:
	if selected_ids.is_empty():
		return false
	var seen_ids: Dictionary[String, bool] = {}
	for i: int in selected_ids.size():
		var selected_id: String = selected_ids[i]
		if selected_id.is_empty():
			return false
		if seen_ids.has(selected_id):
			return false
		seen_ids[selected_id] = true
	return true


func _get_discover_order(suspicion_id: String) -> int:
	var state: Dictionary = DataManager.get_suspicion_state(suspicion_id)
	return int(state.get("discover_order", 999999))


func _safe_to_int(value: String, fallback: int) -> int:
	if value.is_valid_int():
		return int(value)
	return fallback


func _is_toggle_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	if _is_text_input_focused():
		return false
	if GameManager != null and int(GameManager.current_state) == int(GameManager.GameState.DIALOGUE):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	if key_event.keycode != KEY_V and key_event.physical_keycode != KEY_V:
		return false
	if key_event.alt_pressed or key_event.ctrl_pressed or key_event.meta_pressed:
		return false
	return true


func _is_text_input_focused() -> bool:
	var focused_control: Control = get_viewport().gui_get_focus_owner()
	return focused_control is LineEdit or focused_control is TextEdit


func _is_close_input(event: InputEvent) -> bool:
	if not (event is InputEventKey):
		return false
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed:
		return false
	if key_event.echo:
		return false
	return key_event.keycode == KEY_ESCAPE or key_event.physical_keycode == KEY_ESCAPE


func _is_manual_access_unlocked() -> bool:
	if FlowManager == null:
		return true
	if not FlowManager.has_method("are_manual_panels_unlocked"):
		return true
	return FlowManager.are_manual_panels_unlocked()


func _show_manual_locked_notice() -> void:
	if ToastManager == null:
		return
	ToastManager.show_notice("进入书房后才能打开推理手册。", "warning", 1.8)
