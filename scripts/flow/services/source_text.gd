extends RefCounted

const ALIASES := {"穆暌信":"穆执", "松林夕":"周崇安", "苏溟玖":"林玖", "夏中清":"钟歧", "夏月":"钟岳", "松院长":"周院长", "松叔叔":"周叔叔", "苏姐姐":"林姐姐"}

static func data() -> Node:
	return Engine.get_main_loop().root.get_node("DataManager")

static func flow() -> Node:
	return Engine.get_main_loop().root.get_node("FlowManager")

static func paragraphs(key: String, underlined := false) -> PackedStringArray:
	var file := FileAccess.open("res://assets/data/source_text/" + key + ".json", FileAccess.READ)
	if file == null:
		push_error("Missing authored text: " + key)
		return []
	var doc: Dictionary = JSON.parse_string(file.get_as_text())
	var result := PackedStringArray()
	for paragraph: Dictionary in doc.get("paragraphs", []):
		var text := ""
		for run: Dictionary in paragraph.get("runs", []):
			var part := String(run.get("text", ""))
			for before: String in ALIASES:
				part = part.replace(before, ALIASES[before])
			if underlined and run.has("u") and run.u.get("val", "single") != "none":
				part = "[u]" + part + "[/u]"
			text += part
		if not text.strip_edges().is_empty():
			result.append(text)
	return result

static func configure_clues() -> void:
	var mapping := {"2_mu_3":"letter", "3_mei_1":"rules_meta", "3_zhou_1":"rules_zhou", "2_dream_rules":"rules_zhou", "3_study_darkroom_4":"cycle_notes"}
	for clue_id: String in mapping:
		var clue: ClueData = data().get_clue_def(clue_id)
		if clue != null:
			# Preserve the source location's introductory sentence.
			var prefix := clue.description.split("\n")[0]
			clue.description = prefix + "\n\n" + "\n\n".join(paragraphs(mapping[clue_id]))
	var notes: ClueData = data().get_clue_def("2_wu_dream_notes")
	if notes != null:
		notes.description = "\n\n".join(paragraphs("dream_notes").slice(1))
	for npc: String in ["mu", "zhou", "lin", "zhong"]:
		var clue := ClueData.new()
		clue.id = "source_nightmare_" + npc
		var lines := paragraphs("nightmare_" + npc)
		clue.title = lines[0]
		clue.description = "\n\n".join(lines.slice(1))
		clue.category_path = PackedStringArray(["梦墅", "梦魇回忆"])
		clue.clue_type = "lore"
		clue.chapter_id = "2"
		data().register_clue_def(clue)
	var pages := paragraphs("note_pages")
	for i in range(1, pages.size()):
		var clue := ClueData.new()
		clue.id = "source_note_page_" + str(i)
		clue.title = "笔记残页·" + str(i)
		clue.description = pages[i]
		clue.category_path = PackedStringArray(["梦墅", "笔记残页"])
		clue.clue_type = "lore"
		clue.chapter_id = "2"
		data().register_clue_def(clue)

static func notebook_body() -> String:
	return "\n\n".join(paragraphs("dream_notes", data().has_flag("source_notebook/underlined")).slice(1))

# Flowchart 6: solved by the player != reported to the butler != known to Mu.
static func character_ending(npc: String) -> String:
	if bool(flow().get_dialogic_var("Ending.ClearSnow", false)):
		return "perfect"
	if npc == "wu":
		return "farewell" if bool(flow().get_dialogic_var("Ch3.Route.Resistance", false)) else "wake"
	if npc == "player":
		return "audience" if data().has_flag("source_plot/player_identity_known") else "return"
	var reported: bool = data().has_flag("source_plot/reported_" + npc)
	if npc == "mu":
		return "death" if reported else "forget"
	var accused_mu := String(flow().get_dialogic_var("Ch2.AccusedKiller", "")) == "穆执"
	var shot := bool(flow().get_dialogic_var("Ch3.Weapon.Fired", false))
	if accused_mu or shot:
		return "death" if reported else "forget"
	if data().has_flag("source_plot/mu_knows_nightmare_" + npc):
		return "forget" if data().has_flag("source_plot/mu_knows_reason_" + npc) else "death"
	return "death" if reported else "forget"
