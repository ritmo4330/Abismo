extends RefCounted

const BodySearch = preload("res://scripts/data/body_search_summary.gd")
static var _authored: Dictionary = {}

static func data() -> Node:
	return Engine.get_main_loop().root.get_node("DataManager")

static func flow() -> Node:
	return Engine.get_main_loop().root.get_node("FlowManager")

static func authored() -> Dictionary:
	if _authored.is_empty():
		_authored = JSON.parse_string(FileAccess.get_file_as_string("res://assets/data/evidence_cards/cards.json"))
	return _authored

static func configure() -> void:
	for id: String in ["1_testimony_2_butler", "1_testimony_4_all", "2_dream_rules"]:
		var definition: ClueData = data().get_clue_def(id)
		var card: Dictionary = authored()[id]
		definition.title = card.title
		definition.description = "\n\n".join(card.paragraphs)
	var task: SuspicionData = data().get_suspicion_def("1_suspicion_butler_request")
	task.title = "穆执的委托"

static func _gate(gate: Array) -> bool:
	match gate[0]:
		"clue":
			return data().has_clue(gate[1])
		"var":
			return bool(flow().get_dialogic_var(gate[1], false))
		"flag":
			return data().has_flag(gate[1])
		"intro":
			for i: int in range(1, 4):
				if not bool(flow().get_dialogic_var("Ch1.NPCIntro.%s.Selected%d" % [gate[1], i], false)):
					return false
			return true
	return false

static func _person_known(person: String) -> bool:
	if person == "moyu":
		return str(flow().get_dialogic_var("ButlerName", "")) == "末雨"
	if person in ["meta", "butler"]:
		return bool(flow().get_dialogic_var("Ch1.InitialSearch.Enabled", false)) or data().has_clue("1_testimony_2_butler") or data().has_suspicion("1_suspicion_butler_request")
	var key: String = {"mu":"Mu", "zhou":"Zhou", "lin":"Lin", "wu":"Wu", "zhong":"Zhong"}[person]
	return bool(flow().get_dialogic_var("Ch1.NPCIntro.%s.Introed" % key, false))

static func clue_cards(ids: PackedStringArray = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if ids.is_empty():
		ids = data().get_discovered_clue_ids()
	for id: String in ids:
		if not data().has_clue(id):
			continue
		if BodySearch.is_part(id):
			continue
		if id == "1_testimony_3_all":
			for i: int in range(5):
				result.append(authored()[id + "/" + str(i)].duplicate(true))
		elif authored().has(id):
			result.append(authored()[id].duplicate(true))
		else:
			var definition: ClueData = data().get_clue_def(id)
			if definition == null:
				continue
			var body := definition.description
			var markup := false
			if id == BodySearch.SUMMARY_ID:
				body = BodySearch.render(data())
				markup = true
			elif id == "2_wu_dream_notes":
				body = preload("res://scripts/flow/services/source_text.gd").notebook_body()
				markup = true
			result.append({"id":id, "evidence_id":id, "title":definition.title, "source":"结论" if definition.is_conclusion else "线索", "paragraphs":[body], "markup":markup})
	return result

static func person_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for person: String in ["mu", "zhou", "lin", "wu", "zhong", "meta", "butler", "moyu"]:
		if not _person_known(person):
			continue
		var card: Dictionary = authored()["person/" + person].duplicate(true)
		var facts: Array[String] = []
		for entry: Dictionary in card.get("entries", []):
			if _gate(entry.gate):
				facts.append(entry.text)
		card["facts"] = facts
		result.append(card)
	return result

static func suspicion_cards() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id: String in data().get_discovered_suspicion_ids():
		var key := "suspicion/" + id
		if authored().has(key):
			result.append(authored()[key].duplicate(true))
			continue
		var definition: SuspicionData = data().get_suspicion_def(id)
		result.append({"id":key, "suspicion_id":id, "title":definition.title, "source":"疑点", "paragraphs":[definition.description]})
	return result
