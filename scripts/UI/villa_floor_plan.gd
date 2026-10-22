extends Control

signal location_selected(room_id: String)

const STYLE = preload("res://scripts/UI/casebook_style.gd")
const ROOMS := {
	"view:kitchen": ["厨房", Rect2(0.06, 0.08, 0.28, 0.13)],
	"view:pantry": ["食品储藏室", Rect2(0.34, 0.08, 0.24, 0.13)],
	"view:storeroom": ["储物间", Rect2(0.58, 0.08, 0.36, 0.13)],
	"can_ting": ["餐厅", Rect2(0.06, 0.21, 0.28, 0.12)],
	"zou_lang": ["一楼走廊", Rect2(0.34, 0.21, 0.60, 0.12)],
	"hall": ["大厅", Rect2(0.34, 0.33, 0.34, 0.12)],
	"shu_fang": ["书房", Rect2(0.68, 0.33, 0.26, 0.12)],
	"hui_ke_ting": ["会客厅", Rect2(0.06, 0.33, 0.28, 0.12)],
	"room_mu_zhi": ["穆执房间", Rect2(0.06, 0.62, 0.30, 0.14)],
	"room_zhou_chong_an": ["周崇安房间", Rect2(0.36, 0.62, 0.26, 0.14)],
	"room_meta": ["梅塔房间", Rect2(0.62, 0.62, 0.32, 0.14)],
	"floor2": ["二楼走廊", Rect2(0.06, 0.76, 0.88, 0.10)],
	"room_lin_jiu": ["林玖房间", Rect2(0.06, 0.86, 0.30, 0.14)],
	"room_wu_ting_xiang": ["乌停湘房间", Rect2(0.36, 0.86, 0.26, 0.14)],
	"room_zhong_qi": ["钟歧房间", Rect2(0.62, 0.86, 0.32, 0.14)],
}

var current_room := ""
var available: Dictionary = {}
var buttons: Dictionary = {}
var _blueprint: TextureRect

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(_layout)
	theme = STYLE.theme()
	var art_path := "res://assets/art/casebook/villa-floorplan-v2.png"
	if ResourceLoader.exists(art_path):
		_blueprint = TextureRect.new()
		_blueprint.texture = load(art_path)
		_blueprint.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_blueprint.stretch_mode = TextureRect.STRETCH_SCALE
		_blueprint.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		_blueprint.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_blueprint)
	for id: String in ROOMS:
		var button := STYLE.button(String(ROOMS[id][0]), func() -> void: location_selected.emit(id), 24)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_stylebox_override("normal", STYLE.surface(Color.TRANSPARENT, 2))
		button.add_theme_stylebox_override("disabled", STYLE.surface(Color.TRANSPARENT, 2))
		button.add_theme_stylebox_override("hover", STYLE.surface(Color(0.58, 0.25, 0.18, 0.11), 2, STYLE.RED))
		button.add_theme_stylebox_override("pressed", STYLE.surface(Color(0.58, 0.25, 0.18, 0.18), 2, STYLE.RED))
		button.add_theme_color_override("font_shadow_color", Color.TRANSPARENT)
		add_child(button)
		buttons[id] = button
	var first := STYLE.label("一楼", 27, true)
	first.name = "FloorOne"
	add_child(first)
	var second := STYLE.label("二楼", 27, true)
	second.name = "FloorTwo"
	add_child(second)
	_layout()

func configure(room_id: String, destinations: Dictionary) -> void:
	current_room = canonical(room_id)
	available = destinations
	if is_node_ready(): _layout()

static func canonical(room_id: String) -> String:
	return {"ch1_study": "shu_fang", "ch1_crime_scene_lin_room": "room_lin_jiu"}.get(room_id, room_id)

func _layout() -> void:
	if not is_node_ready(): return
	if _blueprint != null: _blueprint.size = size
	for id: String in buttons:
		var rect: Rect2 = ROOMS[id][1]
		var button: Button = buttons[id]
		button.position = rect.position * size
		button.size = rect.size * size
		button.disabled = id != current_room and not available.has(id)
		var room_name := String(ROOMS[id][0])
		var intro_id: String = {"room_mu_zhi": "Mu", "room_zhou_chong_an": "Zhou", "room_lin_jiu": "Lin", "room_wu_ting_xiang": "Wu", "room_zhong_qi": "Zhong"}.get(id, "")
		if not intro_id.is_empty() and not bool(FlowManager.get_dialogic_var("Ch1.NPCIntro.%s.Introed" % intro_id, false)):
			room_name = "客房"
		button.text = ("●  " if id == current_room else "") + room_name
		button.tooltip_text = "当前位置" if id == current_room else ("前往" if available.has(id) else "当前不可前往")
		button.modulate = Color.WHITE if available.has(id) or id == current_room else Color(1, 1, 1, 0.62)
		button.add_theme_color_override("font_disabled_color", STYLE.MUTED)
		if id == current_room:
			button.add_theme_stylebox_override("normal", STYLE.surface(Color(0.56, 0.22, 0.16, 0.12), 2, STYLE.RED))
			button.add_theme_color_override("font_color", STYLE.RED)
		else:
			button.add_theme_stylebox_override("normal", STYLE.surface(Color.TRANSPARENT, 2))
			button.remove_theme_color_override("font_color")
	$FloorOne.position = Vector2(size.x * 0.06, 2)
	$FloorTwo.position = Vector2(size.x * 0.06, size.y * 0.52)
	queue_redraw()

func _draw() -> void:
	if _blueprint != null: return
	var ink := Color(0.37, 0.32, 0.26, 0.65)
	draw_line(Vector2(size.x * 0.06, size.y * 0.47), Vector2(size.x * 0.94, size.y * 0.47), ink, 1)
	for i: int in range(7):
		var y := size.y * (0.325 + float(i) * 0.002)
		draw_line(Vector2(size.x * 0.35, y), Vector2(size.x * 0.45, y), ink, 1)
		var y2 := size.y * (0.762 + float(i) * 0.003)
		draw_line(Vector2(size.x * 0.08, y2), Vector2(size.x * 0.18, y2), ink, 1)
	# Door swings and small furniture symbols give the layout a floor-plan
	# reading, without pretending locked rooms are currently accessible.
	for id: String in ROOMS:
		var rect: Rect2 = ROOMS[id][1]
		var at := rect.position * size
		var dimensions := rect.size * size
		var bottom := at + Vector2(0, dimensions.y)
		var door_width := minf(28, dimensions.x * 0.18)
		var door := bottom + Vector2(dimensions.x * 0.70, 0)
		# Architectural outlines stay readable if an optional art asset is absent.
		draw_line(at, at + Vector2(dimensions.x, 0), ink, 3)
		draw_line(at, bottom, ink, 3)
		draw_line(at + Vector2(dimensions.x, 0), at + dimensions, ink, 3)
		draw_line(bottom, door - Vector2(door_width, 0), ink, 3)
		draw_line(door, at + dimensions, ink, 3)
		draw_arc(door, door_width, PI, PI * 1.5, 20, ink, 1)
		draw_line(door, door + Vector2(0, -door_width), ink, 1)
		var window_start := at + Vector2(dimensions.x * 0.30, -3)
		draw_line(window_start, window_start + Vector2(dimensions.x * 0.28, 0), ink, 1)
		draw_line(window_start + Vector2(0, 6), window_start + Vector2(dimensions.x * 0.28, 6), ink, 1)
		_furniture(id, at + Vector2(dimensions.x * 0.5, dimensions.y * 0.23), ink)
	# Stair treads connect the two surveyed floors visually.
	for y_range: Vector2 in [Vector2(0.21, 0.45), Vector2(0.65, 0.90)]:
		var stair := Rect2(Vector2(size.x * 0.012, size.y * y_range.x), Vector2(size.x * 0.036, size.y * (y_range.y - y_range.x)))
		draw_rect(stair, ink, false, 2)
		for step: int in range(12):
			var y := stair.position.y + stair.size.y * step / 12.0
			draw_line(Vector2(stair.position.x, y), Vector2(stair.end.x, y), ink, 1)

func _furniture(id: String, at: Vector2, ink: Color) -> void:
	var light := Color(ink, 0.25)
	if id.begins_with("room_"):
		draw_rect(Rect2(at - Vector2(19, 11), Vector2(38, 25)), ink, false, 2)
		draw_rect(Rect2(at - Vector2(16, 8), Vector2(14, 7)), light, true)
		draw_rect(Rect2(at + Vector2(2, -8), Vector2(14, 7)), light, true)
		draw_line(at + Vector2(-19, 0), at + Vector2(19, 0), ink, 1)
	elif id == "shu_fang":
		for side: float in [-1.0, 1.0]:
			var points := PackedVector2Array([at, at + Vector2(side * 23, -8), at + Vector2(side * 23, 15), at + Vector2(0, 20), at])
			draw_polyline(points, ink, 2, true)
			for n: int in range(3): draw_line(at + Vector2(side * 5, 1 + n * 5), at + Vector2(side * 18, -3 + n * 5), ink, 1)
	elif id in ["hall", "view:kitchen"]:
		draw_arc(at + Vector2(0, 8), 19, PI, TAU, 30, ink, 2, true)
		draw_line(at + Vector2(-25, 8), at + Vector2(25, 8), ink, 3)
		draw_circle(at + Vector2(0, -13), 3, ink)
	elif id in ["can_ting", "hui_ke_ting"]:
		draw_rect(Rect2(at - Vector2(23, 8), Vector2(46, 19)), ink, false, 2)
		for side: float in [-1.0, 1.0]:
			for n: int in range(3): draw_rect(Rect2(at + Vector2(-18 + n * 14, side * 18 - 3), Vector2(9, 6)), ink, false, 1)
