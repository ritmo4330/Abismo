extends RefCounted

const SUMMARY_ID := "1_body_search_summary"
const ROWS := [
	["1_mu_0", "1_mu_0_27", "穆执", "穆执身着一套考究的黑色西装，以白色衬衣打底，口袋里没有东西。", "仔细观察，你发现穆执西装的衣袖上沾有些许尘土。"],
	["1_zhou_0", "", "周崇安", "周崇安上着一件白色大衣，口袋里没有东西。脖子上围着一条浅灰色长围巾。下着一条棕色长裤，口袋里没有东西。", ""],
	["1_lin_0", "1_lin_0_25", "林玖", "林玖上着一件米色的羊毛衫，衣袖口被卷起。下着一条浅色的棉裤，口袋里没有东西。", "你将她的衣袖翻下来后，露出袖口上一片暗褐色的印迹。"],
	["1_wu_0", "", "乌停湘", "乌停湘上着一件白色羽绒服，口袋里没有东西。下着一条黑色长裤，口袋里没有东西。", ""],
	["1_zhong_0", "", "钟歧", "钟歧上着一件黑色羽绒服，内袋中有一把水果刀。下着一条深灰色长裤，口袋里没有东西。", ""],
]

static func is_part(id: String) -> bool:
	for row: Array in ROWS:
		if id == row[0] or (not String(row[1]).is_empty() and id == row[1]): return true
	return false

static func has_first(data: Node) -> bool:
	for row: Array in ROWS:
		if data.has_clue(row[0]): return true
	return false

static func render(data: Node) -> String:
	var result := "[table=2]"
	result += "[cell][b][/b][/cell][cell][b]搜身线索[/b][/cell]"
	for row: Array in ROWS:
		result += "[cell]" + String(row[2]) + "[/cell][cell]"
		if data.has_clue(row[0]): result += String(row[3])
		if not String(row[1]).is_empty() and data.has_clue(row[1]):
			if data.has_clue(row[0]): result += "\n"
			result += "[i]" + String(row[4]) + "[/i]"
		result += "[/cell]"
	return result + "[/table]"
