extends RefCounted

# Source: planning document 五 2 梦墅. These are separate locations, not
# replacements for the physical villa bedrooms. Lin's letter belongs outside.
const DREAM_ROOMS := {
	"room_mu_zhi": {"name":"穆执", "asset":"mu_room", "clues":["2_mu_1", "2_mu_2", "2_mu_3"]},
	"room_zhou_chong_an": {"name":"周崇安", "asset":"zhou_room", "clues":["2_zhou_1", "2_zhou_2", "2_zhou_3"]},
	"room_lin_jiu": {"name":"林玖", "asset":"lin_room_empty", "clues":["2_lin_2", "2_lin_3", "2_lin_4"]},
	"room_wu_ting_xiang": {"name":"乌停湘", "asset":"wu_room", "clues":["2_wu_1", "2_wu_2"]},
	"room_zhong_qi": {"name":"钟歧", "asset":"zhong_room", "clues":["2_zhong_1", "2_zhong_2"]},
	"room_meta": {"name":"梅塔", "asset":"meta_room", "clues":["2_mei_1", "2_mei_2"]},
}
const LATER_STEPS := ["ch2_3_third_search", "ch2_5_third_private_chat", "ch2_6_memory_fragments", "ch3_4_route"]
const RETIRED_CLUES := ["2_mu_burnt_church", "2_wu_dream_notebook", "2_zhong_anchor_records", "2_zhou_sleep_roster", "2_meta_research_plan"]
const DREAM_HOTSPOTS := [Rect2(0.32, 0.44, 0.13, 0.16), Rect2(0.58, 0.51, 0.15, 0.17), Rect2(0.74, 0.58, 0.13, 0.16)]
const DARKROOM_CLUES := ["3_study_darkroom_1", "3_study_darkroom_2", "3_study_darkroom_3", "3_study_darkroom_4", "3_study_darkroom_5", "3_study_darkroom_6"]

static func available() -> bool:
	return Engine.get_main_loop().root.get_node("FlowManager").get_current_step_id() in LATER_STEPS

static func views(room_id: String, physical_asset: String) -> Dictionary:
	if not available(): return {}
	if room_id in ["shu_fang", "ch1_study"]:
		var study_views := {"villa":{"name":"别墅 · 书房", "asset":physical_asset}}
		if Engine.get_main_loop().root.get_node("DataManager").has_flag("source_plot/darkroom_open"):
			# Source: a child's bedroom behind the study. Reuse existing bedroom art.
			study_views["darkroom"] = {"name":"书房暗室", "asset":"wu_room"}
		return study_views
	if not DREAM_ROOMS.has(room_id): return {}
	var info: Dictionary = DREAM_ROOMS[room_id]
	return {
		"villa": {"name":"别墅 · " + String(info.name) + "房间", "asset":physical_asset},
		"subconscious": {"name":"潜意识 · " + String(info.name) + "房间", "asset":String(info.asset)},
	}

static func placements() -> Array:
	var result: Array = []
	for room_id: String in DREAM_ROOMS:
		var clues: Array = DREAM_ROOMS[room_id].clues
		for index: int in clues.size():
			var placement := CluePlacementData.new()
			placement.placement_id = "source_" + String(clues[index])
			placement.clue_id = clues[index]
			placement.chapter_id = "2"
			placement.room_id = room_id
			placement.spawn_name = "SourceHotspot"
			placement.available_steps = PackedStringArray(LATER_STEPS)
			placement.space = "subconscious"
			placement.static_hotspot = DREAM_HOTSPOTS[index]
			result.append(placement)
	var letter := CluePlacementData.new()
	letter.placement_id = "source_lin_letter"
	letter.clue_id = "2_lin_1"
	letter.room_id = "room_lin_jiu"
	letter.spawn_name = "DeskPentagramPaper"
	letter.available_steps = PackedStringArray(LATER_STEPS)
	letter.space = "villa"
	letter.static_hotspot = Rect2(0.37, 0.41, 0.1, 0.09)
	result.append(letter)
	for room_id: String in ["shu_fang", "ch1_study"]:
		for index: int in DARKROOM_CLUES.size():
			var placement := CluePlacementData.new()
			placement.placement_id = "source_darkroom_" + room_id + "_" + str(index)
			placement.clue_id = DARKROOM_CLUES[index]
			placement.chapter_id = "3"
			placement.room_id = room_id
			placement.spawn_name = "SourceHotspot"
			placement.available_steps = PackedStringArray(["ch3_4_route"])
			placement.required_flags = PackedStringArray(["source_plot/darkroom_open"])
			placement.space = "darkroom"
			placement.static_hotspot = Rect2(0.24 + (index % 3) * 0.26, 0.39 + floori(float(index) / 3.0) * 0.24, 0.13, 0.15)
			result.append(placement)
	return result

static func optional_clues() -> Array:
	var result: Array = ["2_missing_body", "1_lin_7", "2_lin_1"]
	for room_id: String in DREAM_ROOMS:
		result.append_array(DREAM_ROOMS[room_id].clues)
	return result
