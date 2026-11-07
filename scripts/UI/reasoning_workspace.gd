extends RefCounted

const STYLE = preload("res://scripts/UI/casebook_style.gd")
const NOVEL := {
 "1_suspicion_crime_info": ["【1】这一段的环境描写交代了案件发生的地点特征，但是【2】中的角色对话细节却不像是发生在这样的环境中", ["1_puzzle_maid_scene", "1_puzzle_first_discussion"]],
 "1_suspicion_x_disability": ["在描述了X的残疾的段落中，【1】中的动作描写似乎表明X并没有【2】中所述的残疾，但是考虑到挑战读者部分提到的【3】，可以发现这其中必定有端倪", ["1_puzzle_x_impossible_2", "1_puzzle_x_impossible_1", "1_puzzle_challenge_rules"]],
 "1_suspicion_strange_description": ["女仆死后，能完成【1】中添茶工作的人可以是管家；但是在【2】中，在管家也死亡之后，却仍有人承担了相似的工作", ["1_puzzle_x_impossible_1", "1_puzzle_x_impossible_2"]],
 "1_suspicion_nonexistent_service": ["在女仆和管家死后，仍有人为X“递上肉饼”。从排除法的角度出发，【1】这一段能说明这些人都有自己的行动，似乎没有人能递上这块肉饼，但事情一定发生了。结合“挑战读者”中的【2】，或许能揭示出叙述性诡计的一角", ["1_puzzle_second_discussion", "1_puzzle_challenge_rules"]],
 "1_suspicion_hidden_chars": ["根据已得出的结论【1】，再与【2】相对照，排除了一切不可能，剩下的无论多么离奇也是真相", ["1_conclusion_hidden_server", "1_puzzle_cast"]],
 "1_suspicion_impossible_crime": ["根据已得出的结论，【1】能证明与X有关的怪异之处；【2】能证明与地点有关的怪异之处；【3】能证明与死者有关的怪异之处，而这些怪异之处都有某些共同特征", ["1_conclusion_disability_superposition", "1_conclusion_environment_paradox", "1_conclusion_dead_not_dead"]]
}
static func answer(question: String, index: int) -> String:
	if not NOVEL.has(question): return ""
	var answers: Array = NOVEL[question][1]
	return String(answers[index]) if index >= 0 and index < answers.size() else ""
static func matches(question: String, slots: Array[String]) -> bool:
	if not NOVEL.has(question): return true
	var answers: Array = NOVEL[question][1]
	if slots.size() != answers.size(): return false
	for i: int in slots.size():
		if slots[i] != answers[i]: return false
	return true

var host: Node
var catalog: Tree
var search: LineEdit
var preview_title: Label
var preview_body: RichTextLabel
var question_select: OptionButton
var add_button: Button
var remove_button: Button
var progress: Label
var selected_clue := ""
var active_slot := 0
var _question := ""
var _questions: Array[String] = []
var _refreshing := false

func build(owner_panel: Node) -> void:
	host = owner_panel
	host.find_child("HeaderTitle", true, false).text = "调查手册"
	var left: VBoxContainer = host.suspicion_tree.get_parent()
	host.search_line_edit.get_parent().hide()
	host.suspicion_tree.hide()
	left.add_child(STYLE.label("线索", 30, true))
	search = LineEdit.new()
	search.name = "EvidenceSearch"
	search.placeholder_text = "搜索已收录线索"
	search.custom_minimum_size.y = 48
	search.text_changed.connect(func(_text: String) -> void: refresh())
	left.add_child(search)
	catalog = Tree.new()
	catalog.name = "EvidenceCatalog"
	catalog.hide_root = true
	catalog.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalog.custom_minimum_size.y = 230
	catalog.add_theme_font_size_override("font_size", 28)
	catalog.item_selected.connect(_on_evidence_selected)
	catalog.item_activated.connect(_add_evidence)
	left.add_child(catalog)
	left.add_child(HSeparator.new())
	preview_title = STYLE.label("线索详情", 25, true)
	preview_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(preview_title)
	preview_body = RichTextLabel.new()
	preview_body.name = "EvidenceDescription"
	preview_body.custom_minimum_size.y = 180
	preview_body.scroll_active = true
	preview_body.add_theme_font_size_override("normal_font_size", 24)
	left.add_child(preview_body)
	var actions := HBoxContainer.new()
	left.add_child(actions)
	add_button = STYLE.button("加入证据", _add_evidence, 25)
	add_button.name = "AddEvidence"
	add_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_button.custom_minimum_size.y = 54
	STYLE.style_ribbon(add_button)
	actions.add_child(add_button)
	remove_button = STYLE.button("移除选中证据", _remove_evidence, 23)
	remove_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	remove_button.custom_minimum_size.y = 54
	actions.add_child(remove_button)
	var right: VBoxContainer = host.detail_title.get_parent().get_parent()
	host.detail_title.hide()
	var heading := STYLE.label("问题", 30, true)
	heading.name = "CurrentCaseHeading"
	right.add_child(heading)
	right.move_child(heading, 0)
	question_select = OptionButton.new()
	question_select.name = "QuestionSelector"
	question_select.custom_minimum_size.y = 54
	question_select.clip_text = true
	question_select.add_theme_color_override("font_disabled_color", STYLE.INK)
	question_select.add_theme_font_size_override("font_size", 27)
	question_select.item_selected.connect(_on_question_selected)
	right.add_child(question_select)
	right.move_child(question_select, 1)
	progress = STYLE.label("", 22)
	progress.add_theme_color_override("font_color", STYLE.RED)
	host.slot_row.get_parent().add_child(progress)
	host.slot_row.get_parent().move_child(progress, 1)
	host.find_child("ReasoningTitle", true, false).text = "已选证据"
	var controls: VBoxContainer = host.slot_row.get_parent()
	controls.add_theme_constant_override("separation", 10)
	var section: PanelContainer = controls.get_parent()
	section.custom_minimum_size.y = 220
	section.size_flags_vertical = Control.SIZE_SHRINK_END
	section.add_theme_stylebox_override("panel", STYLE.surface(Color(1, 1, 1, 0.13), 12, STYLE.RULE))
	host.slot_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	host.reason_button.custom_minimum_size.y = 48

func refresh() -> void:
	if _refreshing or catalog == null: return
	_refreshing = true
	host.find_child("CurrentCaseHeading", true, false).text = preload("res://scripts/UI/casebook_cases.gd").reasoning_title()
	preload("res://scripts/UI/archive_presentation.gd").set_tabs_enabled(host, not host._is_locked_and_unresolved())
	if _question != String(host._selected_suspicion_id):
		_question = String(host._selected_suspicion_id)
		active_slot = 0
	_questions.clear()
	question_select.clear()
	for id: String in host._get_sorted_discovered_suspicion_ids():
		if host._is_locked_session_active() and id != String(host._locked_suspicion_id): continue
		var definition: Resource = DataManager.get_suspicion_def(id)
		if definition == null: continue
		_questions.append(id)
		question_select.add_item(("✓  " if DataManager.is_suspicion_resolved(id) else "") + String(definition.title))
		if id == _question: question_select.select(_questions.size() - 1)
	question_select.disabled = host._is_locked_and_unresolved() or _questions.is_empty()
	_rebuild_evidence()
	var slots: Array[String] = host._get_slot_ids(_question)
	active_slot = clampi(active_slot, 0, maxi(0, slots.size() - 1))
	var found := 0
	for id: String in slots:
		if not id.is_empty(): found += 1
	progress.text = "已选 %d / %d" % [found, slots.size()]
	var editable := not _question.is_empty() and not DataManager.is_suspicion_resolved(_question)
	add_button.disabled = not editable or selected_clue.is_empty()
	remove_button.disabled = not editable or slots.is_empty() or slots[active_slot].is_empty() or host._is_novel_evidence_fixed(_question, slots[active_slot])
	for index: int in host.slot_buttons.size():
		var button: Button = host.slot_buttons[index]
		button.add_theme_color_override("font_color", STYLE.RED if index == active_slot and editable else STYLE.INK)
		var fixed: bool = index < slots.size() and host._is_novel_evidence_fixed(_question, slots[index])
		button.disabled = not editable or fixed
		if fixed and not button.text.begins_with("✓ "): button.text = "✓ " + button.text
		button.add_theme_color_override("font_disabled_color", STYLE.INK)
		button.tooltip_text = "已确认" if fixed else ("选择此证据位置" if editable else "")
	if NOVEL.has(_question):
		var prompt: String = NOVEL[_question][0]
		for i: int in slots.size():
			var marker := "【%d】" % (i + 1)
			if not slots[i].is_empty():
				prompt = prompt.replace(marker, marker + "《" + host._get_clue_title(slots[i]) + "》")
			if i < host.slot_buttons.size() and slots[i].is_empty():
				host.slot_buttons[i].text = marker
		host.detail_body.text = prompt
		host.find_child("ReasoningTitle", true, false).text = "推理填空"
	else:
		host.find_child("ReasoningTitle", true, false).text = "已选证据"
	_refreshing = false

func select_slot(index: int) -> void:
	active_slot = index
	refresh()
	search.grab_focus()

func _rebuild_evidence() -> void:
	catalog.clear()
	var root := catalog.create_item()
	var groups: Dictionary = {}
	var selected_item: TreeItem
	var first_item: TreeItem
	var query := search.text.strip_edges().to_lower()
	for id: String in DataManager.get_discovered_clue_ids("discover"):
		var definition: Resource = DataManager.get_clue_def(id)
		if definition == null: continue
		if not query.is_empty() and not (String(definition.title) + " " + String(definition.description)).to_lower().contains(query): continue
		var parent := root
		var path := ""
		for segment: String in definition.category_path:
			if segment.is_empty(): continue
			path += "/" + segment
			if not groups.has(path):
				var group := catalog.create_item(parent)
				group.set_text(0, segment)
				group.set_selectable(0, false)
				groups[path] = group
			parent = groups[path]
		var item := catalog.create_item(parent)
		item.set_text(0, String(definition.title))
		item.set_metadata(0, id)
		if first_item == null: first_item = item
		if id == selected_clue: selected_item = item
	if selected_item == null: selected_item = first_item
	if selected_item != null:
		catalog.set_selected(selected_item, 0)
		catalog.ensure_cursor_is_visible()
		selected_clue = String(selected_item.get_metadata(0))
	else:
		selected_clue = ""
	_update_preview()

func _update_preview() -> void:
	var definition: Resource = DataManager.get_clue_def(selected_clue) if not selected_clue.is_empty() else null
	preview_title.text = String(definition.title) if definition != null else "线索详情"
	preview_body.text = String(definition.description) if definition != null else ("暂未收录线索。" if search.text.is_empty() else "未找到符合条件的线索。")

func _on_evidence_selected() -> void:
	if _refreshing: return
	var item := catalog.get_selected()
	if item == null or not (item.get_metadata(0) is String): return
	selected_clue = String(item.get_metadata(0))
	DataManager.mark_clue_read(selected_clue)
	_update_preview()
	add_button.disabled = _question.is_empty() or DataManager.is_suspicion_resolved(_question)

func _on_question_selected(index: int) -> void:
	if index < 0 or index >= _questions.size() or host._is_locked_and_unresolved(): return
	host._selected_suspicion_id = _questions[index]
	host._show_suspicion_detail(_questions[index], true)

func _add_evidence() -> void:
	if add_button.disabled or not DataManager.has_clue(selected_clue): return
	var current: Array[String] = host._get_slot_ids(_question)
	if active_slot < current.size() and host._is_novel_evidence_fixed(_question, current[active_slot]): return
	host._on_clue_selected_for_reasoning({"source": "suspicion_ui", "suspicion_id": _question, "slot_index": active_slot}, selected_clue)
	var slots: Array[String] = host._get_slot_ids(_question)
	for index: int in slots.size():
		if slots[index].is_empty():
			active_slot = index
			break
	refresh()

func _remove_evidence() -> void:
	if remove_button.disabled: return
	var slots: Array[String] = host._get_slot_ids(_question)
	if host._is_novel_evidence_fixed(_question, slots[active_slot]): return
	slots[active_slot] = ""
	host._store_slot_ids(_question, slots)
	host._update_reasoning_panel()

