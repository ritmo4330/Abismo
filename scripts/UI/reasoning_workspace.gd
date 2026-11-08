extends RefCounted

const STYLE = preload("res://scripts/UI/casebook_style.gd")
const Cases = preload("res://scripts/UI/casebook_cases.gd")
const BodySearchSummary = preload("res://scripts/data/body_search_summary.gd")
const SourceText = preload("res://scripts/flow/services/source_text.gd")
const ACCENT := Color("225b52")
const CARD := Color("f7f3e9")
const STROKE := Color("c9c5b4")

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
var add_button: Button
var remove_button: Button
var progress: Label
var selected_clue := ""
var active_slot := 0
var _question := ""
var _refreshing := false


func build(owner_screen: Node) -> void:
	host = owner_screen
	catalog = host.get_node("%EvidenceCatalog")
	search = host.get_node("%EvidenceSearch")
	preview_title = host.get_node("%EvidenceTitle")
	preview_body = host.get_node("%EvidenceDescription")
	add_button = host.get_node("%AddEvidence")
	remove_button = host.get_node("%RemoveEvidence")
	progress = host.get_node("%Progress")
	_apply_style()
	search.text_changed.connect(func(_text: String) -> void: refresh())
	catalog.item_selected.connect(_on_evidence_selected)
	catalog.item_activated.connect(_add_evidence)
	add_button.pressed.connect(_add_evidence)
	remove_button.pressed.connect(_remove_evidence)
	host.detail_body.meta_clicked.connect(_on_blank_clicked)


func _apply_style() -> void:
	var theme := STYLE.theme()
	var highlight := STYLE.surface(Color("dce9e1"), 7, Color("a8c5b8"))
	for state: String in ["selected", "selected_focus"]:
		theme.set_stylebox(state, "Tree", highlight)
	theme.set_color("font_selected_color", "Tree", ACCENT)
	theme.set_constant("v_separation", "Tree", 15)
	theme.set_font_size("font_size", "Tree", 24)
	theme.set_constant("line_separation", "RichTextLabel", 12)
	theme.set_stylebox("normal", "Button", STYLE.surface(Color("eee9dc"), 12))
	theme.set_stylebox("hover", "Button", highlight)
	theme.set_stylebox("pressed", "Button", highlight)
	host.get_node("%Screen").theme = theme
	for name: String in ["EvidencePane", "SuspicionPane", "QuestionPane"]:
		host.get_node("%" + name).add_theme_stylebox_override("panel", STYLE.surface(CARD, 20, STROKE))
	for name: String in ["ScreenTitle", "EvidenceHeading", "SuspicionHeading", "QuestionHeading", "DetailTitle", "EvidenceTitle"]:
		var heading: Label = host.get_node("%" + name)
		heading.add_theme_font_override("font", STYLE.display_font(700))
		heading.add_theme_font_size_override("font_size", 40 if name == "ScreenTitle" else (34 if name == "DetailTitle" else 27))
		if name != "DetailTitle" and name != "EvidenceTitle":
			heading.add_theme_color_override("font_color", ACCENT)
	host.get_node("%CaseTitle").add_theme_color_override("font_color", STYLE.MUTED)
	host.get_node("%ReasoningHint").add_theme_color_override("font_color", STYLE.RED)
	preview_body.add_theme_font_size_override("normal_font_size", 23)
	host.detail_body.add_theme_font_size_override("normal_font_size", 30)
	for button: Button in [add_button, host.reason_button]:
		button.add_theme_stylebox_override("normal", STYLE.surface(ACCENT, 12))
		button.add_theme_stylebox_override("hover", STYLE.surface(Color("2d7165"), 12))
		button.add_theme_stylebox_override("pressed", STYLE.surface(Color("19453e"), 12))
		for color_name: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			button.add_theme_color_override(color_name, Color.WHITE)


func refresh() -> void:
	if _refreshing:
		return
	_refreshing = true
	host.get_node("%CaseTitle").text = Cases.reasoning_title()
	var question_changed := _question != String(host._selected_suspicion_id)
	_question = String(host._selected_suspicion_id)
	var slots: Array[String] = host._get_slot_ids(_question)
	if question_changed:
		active_slot = 0
		_select_next_blank(slots)
	_rebuild_evidence()
	_render_question(slots)
	if question_changed:
		host.detail_body.scroll_to_line(0)
	_refreshing = false


func _render_question(slots: Array[String]) -> void:
	var definition: SuspicionData = DataManager.get_suspicion_def(_question)
	var editable: bool = host._can_fill_question(_question)
	var resolved := not _question.is_empty() and DataManager.is_suspicion_resolved(_question)
	var found := 0
	for id: String in slots:
		if not id.is_empty():
			found += 1

	host.detail_title.text = definition.title if definition != null else "暂无问题"
	if definition == null:
		host.detail_body.text = ""
		progress.text = "调查后收录的疑点会出现在这里。"
	elif resolved:
		progress.text = "已解决"
	elif editable:
		progress.text = "已填 %d / %d   ·   点击题面中的空格选择填入位置" % [found, slots.size()]
	else:
		progress.text = "其他轮次的疑点，可在此回看。"

	if definition != null:
		var text := _escape_bbcode(definition.description)
		var template := ""
		if NOVEL.has(_question):
			template = NOVEL[_question][0]
		elif not definition.required_clue_ids.is_empty():
			var markers: PackedStringArray = []
			for i: int in slots.size():
				markers.append("【%d】" % (i + 1))
			template = "用这些线索完成推理：\n" + "　".join(markers)

		if not template.is_empty():
			text += "\n\n" + _render_blanks(template, slots, editable)
		if resolved:
			var conclusion := DataManager.get_clue_def(definition.conclusion_clue_id)
			if conclusion != null and DataManager.has_clue(conclusion.id):
				text += "\n\n[b]" + _escape_bbcode(conclusion.title) + "[/b]\n" + _escape_bbcode(conclusion.description)
		host.detail_body.text = text

	_update_actions(slots)


func _render_blanks(template: String, slots: Array[String], editable: bool) -> String:
	var text := ""
	var cursor := 0
	for i: int in slots.size():
		var marker := "【%d】" % (i + 1)
		var position := template.find(marker, cursor)
		if position < 0:
			continue
		text += _escape_bbcode(template.substr(cursor, position - cursor))
		var fixed: bool = host._is_novel_evidence_fixed(_question, slots[i])
		var label := "【%d  待填】" % (i + 1) if slots[i].is_empty() else "【%s%s】" % ["✓ " if fixed else "", host._get_clue_title(slots[i])]
		if editable and not fixed:
			var accent := "#ffffff" if i == active_slot else "#225b52"
			var background := "#225b52" if i == active_slot else "#dce9e1"
			text += "[url=blank:%d][bgcolor=%s][color=%s][b]%s[/b][/color][/bgcolor][/url]" % [i, background, accent, _escape_bbcode(label)]
		else:
			text += "[color=#53685d]%s[/color]" % _escape_bbcode(label)
		cursor = position + marker.length()
	return text + _escape_bbcode(template.substr(cursor))


func _on_blank_clicked(meta: Variant) -> void:
	var target := String(meta)
	if target.begins_with("blank:"):
		select_slot(target.trim_prefix("blank:").to_int())


func select_slot(index: int) -> void:
	var slots: Array[String] = host._get_slot_ids(_question)
	if not host._can_fill_question(_question) or index < 0 or index >= slots.size():
		return
	if host._is_novel_evidence_fixed(_question, slots[index]):
		return
	active_slot = index
	_render_question(slots)


func _select_next_blank(slots: Array[String]) -> void:
	for index: int in slots.size():
		if slots[index].is_empty():
			active_slot = index
			return
	for index: int in slots.size():
		if not host._is_novel_evidence_fixed(_question, slots[index]):
			active_slot = index
			return


func _rebuild_evidence() -> void:
	catalog.clear()
	var root := catalog.create_item()
	var groups: Dictionary[String, TreeItem] = {}
	var selected_item: TreeItem
	var first_item: TreeItem
	var query := search.text.strip_edges().to_lower()
	var total := 0
	for id: String in DataManager.get_discovered_clue_ids("discover"):
		var definition := DataManager.get_clue_def(id)
		if definition == null:
			continue
		total += 1
		var searchable := definition.title + " " + definition.description
		if id == BodySearchSummary.SUMMARY_ID:
			searchable += " " + BodySearchSummary.render(DataManager)
		if not query.is_empty() and not searchable.to_lower().contains(query):
			continue
		var group_name := "结论" if definition.is_conclusion else "已收录线索"
		if not groups.has(group_name):
			var group := catalog.create_item(root)
			group.set_text(0, group_name)
			group.set_selectable(0, false)
			groups[group_name] = group
		var item := catalog.create_item(groups[group_name])
		item.set_text(0, definition.title)
		item.set_tooltip_text(0, definition.title)
		item.set_metadata(0, id)
		if first_item == null:
			first_item = item
		if id == selected_clue:
			selected_item = item

	host.get_node("%EvidenceHeading").text = "线索  %d" % total
	if selected_item == null:
		selected_item = first_item
	if selected_item != null:
		catalog.set_selected(selected_item, 0)
		catalog.ensure_cursor_is_visible()
		selected_clue = String(selected_item.get_metadata(0))
	else:
		selected_clue = ""
	_update_preview()


func _update_preview() -> void:
	var definition := DataManager.get_clue_def(selected_clue)
	preview_body.bbcode_enabled = false
	if definition == null:
		preview_title.text = "线索详情"
		preview_body.text = "暂未收录线索。" if search.text.is_empty() else "未找到符合条件的线索。"
		return

	preview_title.text = definition.title
	match selected_clue:
		BodySearchSummary.SUMMARY_ID:
			preview_body.bbcode_enabled = true
			preview_body.text = BodySearchSummary.render(DataManager)
		"2_wu_dream_notes":
			preview_body.bbcode_enabled = true
			preview_body.text = SourceText.notebook_body()
		_:
			preview_body.text = definition.description


func _on_evidence_selected() -> void:
	if _refreshing:
		return
	var item := catalog.get_selected()
	if item == null or not (item.get_metadata(0) is String):
		return
	selected_clue = String(item.get_metadata(0))
	DataManager.mark_clue_read(selected_clue)
	_update_preview()
	_update_actions(host._get_slot_ids(_question))


func _update_actions(slots: Array[String]) -> void:
	var editable: bool = host._can_fill_question(_question)
	var current: String = slots[active_slot] if active_slot < slots.size() else ""
	var fixed: bool = host._is_novel_evidence_fixed(_question, current)
	add_button.disabled = not editable or fixed or selected_clue.is_empty()
	remove_button.disabled = not editable or fixed or current.is_empty()
	add_button.text = "填入第 %d 空" % (active_slot + 1) if editable else "填入线索"
	remove_button.text = "清空第 %d 空" % (active_slot + 1) if editable else "清空空格"


func _add_evidence() -> void:
	if add_button.disabled or not DataManager.has_clue(selected_clue):
		return
	host._on_clue_selected_for_reasoning({"source": "suspicion_ui", "suspicion_id": _question, "slot_index": active_slot}, selected_clue)
	var slots: Array[String] = host._get_slot_ids(_question)
	_select_next_blank(slots)
	_render_question(slots)


func _remove_evidence() -> void:
	if remove_button.disabled:
		return
	var slots: Array[String] = host._get_slot_ids(_question)
	slots[active_slot] = ""
	host._store_slot_ids(_question, slots)
	host._update_reasoning_panel()


func _escape_bbcode(value: String) -> String:
	return value.replace("[", "[lb]")
