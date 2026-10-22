extends RefCounted

# The plan specifies four worlds / four simultaneous handprints, but does not
# give a complete symbol-to-character permutation. Do not invent one.
const OPEN_FLAG := "source_plot/dining_backdoor_open"
const SCENE := "res://scenes/rooms/flower_sea.tscn"
const SYMBOLS := ["α", "β", "γ", "θ"]
const SOURCE = preload("res://scripts/clues/source_investigation.gd")
const RESEARCH := [
	{"name": "钟岳研究所", "flag": "", "clues": ["1_zhongyue_1", "1_zhongyue_2", "1_zhongyue_3", "3_xiayue_1"]},
	{"name": "梅塔研究所", "flag": "source_research/mu", "clues": ["2_mu_meta_research_clue", "3_mei_1"]},
	{"name": "周崇安研究所", "flag": "source_research/zhou", "clues": ["3_zhou_1"]},
	{"name": "异测会研究所", "flag": "source_research/lin", "clues": ["3_abismo_1"]},
]

static func research_known(entry: Dictionary) -> bool:
	var data: Node = Engine.get_main_loop().root.get_node("DataManager")
	if not String(entry.flag).is_empty() and data.has_flag(entry.flag):
		return true
	# Older saves already contain the authored research evidence, not this door's
	# new state. Recognize those facts without granting any missing evidence.
	for id: String in entry.clues:
		if data.has_clue(id): return true
	return false

static func ready() -> bool:
	if not SOURCE.available(): return false
	for entry: Dictionary in RESEARCH:
		if not research_known(entry): return false
	return true

static func confirm(handprints: Array) -> bool:
	if not ready() or handprints.size() != SYMBOLS.size(): return false
	for symbol: String in SYMBOLS:
		if handprints.count(symbol) != 1: return false
	Engine.get_main_loop().root.get_node("DataManager").set_flag(OPEN_FLAG, true)
	return true

static func can_enter() -> bool:
	return SOURCE.available() and Engine.get_main_loop().root.get_node("DataManager").has_flag(OPEN_FLAG)
