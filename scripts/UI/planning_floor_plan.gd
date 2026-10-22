extends Control

signal location_selected(room_id: String)
const STYLE = preload("res://scripts/UI/casebook_style.gd")
# Coordinates transcribed from the two plans in section 3.1.1 of the supplied
# DOCX (word/media/image9.png, image10.png). Character aliases are modernized.
const ROOMS := {
	"shu_fang": ["书房", 1, Rect2(0, 0.145, 0.13, 0.295)],
	"hui_ke_ting": ["会客厅", 1, Rect2(0, 0.725, 0.13, 0.275)],
	"zou_lang": ["走廊", 1, Rect2(0.13, 0.145, 0.082, 0.855)],
	"can_ting": ["餐厅", 1, Rect2(0.212, 0.145, 0.45, 0.305)],
	"flower_sea": ["后院 · 花海", 1, Rect2(0.212, 0, 0.45, 0.145)],
	"hall": ["大厅", 1, Rect2(0.33, 0.45, 0.455, 0.55)],
	"view:kitchen": ["厨房", 1, Rect2(0.662, 0.145, 0.338, 0.2)],
	"view:pantry": ["食品储藏室", 1, Rect2(0.785, 0.345, 0.215, 0.24)],
	"view:storeroom": ["储物间", 1, Rect2(0.785, 0.585, 0.215, 0.415)],
	"room_meta": ["梅塔房间", 2, Rect2(0.13, 0, 0.52, 0.23)],
	"room_mu_zhi": ["穆执房间", 2, Rect2(0.65, 0, 0.22, 0.23)],
	"room_zhong_qi": ["钟歧房间", 2, Rect2(0, 0.12, 0.13, 0.44)],
	"room_zhou_chong_an": ["周崇安房间", 2, Rect2(0, 0.56, 0.13, 0.44)],
	"room_lin_jiu": ["林玖房间", 2, Rect2(0.87, 0.12, 0.13, 0.44)],
	"room_wu_ting_xiang": ["乌停湘房间", 2, Rect2(0.87, 0.56, 0.13, 0.44)],
	"floor2": ["二楼走廊", 2, Rect2(0.13, 0.23, 0.74, 0.26)],
}
var current_room := ""
var available: Dictionary = {}
var buttons: Dictionary = {}
var shown_floor := 1
var _floor_tabs: Array[Button] = []
var _legend: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	theme = STYLE.theme()
	resized.connect(_layout)
	for floor_index: int in range(1, 3):
		var tab := STYLE.button("一楼" if floor_index == 1 else "二楼", show_floor.bind(floor_index), 28)
		tab.toggle_mode = true
		tab.position = Vector2(8 + (floor_index - 1) * 166, 2)
		tab.size = Vector2(154, 60)
		STYLE.style_ribbon(tab)
		add_child(tab)
		_floor_tabs.append(tab)
	for id: String in ROOMS:
		var button := STYLE.button(String(ROOMS[id][0]), func() -> void: location_selected.emit(id), 25)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		for state: String in ["normal", "disabled"]:
			button.add_theme_stylebox_override(state, STYLE.surface(Color.TRANSPARENT, 3))
		button.add_theme_stylebox_override("hover", STYLE.surface(Color(0.55, 0.23, 0.16, 0.1), 3))
		button.add_theme_stylebox_override("pressed", STYLE.surface(Color(0.55, 0.23, 0.16, 0.18), 3))
		add_child(button)
		buttons[id] = button
	_legend = STYLE.label("● 当前位置", 24)
	add_child(_legend)
	_layout()

static func canonical(id: String) -> String:
	return {"ch1_study": "shu_fang", "ch1_crime_scene_lin_room": "room_lin_jiu"}.get(id, id)

func configure(room_id: String, destinations: Dictionary) -> void:
	current_room = canonical(room_id)
	available = destinations
	if ROOMS.has(current_room): shown_floor = int(ROOMS[current_room][1])
	_layout()

func show_floor(floor: int) -> void:
	shown_floor = clampi(floor, 1, 2)
	_layout()

func _plan_rect() -> Rect2:
	return Rect2(12, 104, maxf(100, size.x - 24), maxf(70, (size.x - 24) * 0.5625))

func _layout() -> void:
	if not is_node_ready(): return
	var plan := _plan_rect()
	for tab: Button in _floor_tabs:
		tab.button_pressed = _floor_tabs.find(tab) + 1 == shown_floor
	for id: String in buttons:
		var button: Button = buttons[id]
		var normalized: Rect2 = ROOMS[id][2]
		button.position = plan.position + normalized.position * plan.size
		button.size = normalized.size * plan.size
		button.visible = int(ROOMS[id][1]) == shown_floor
		button.disabled = id != current_room and not available.has(id)
		var room_name := String(ROOMS[id][0])
		var actor: String = {"room_mu_zhi":"Mu", "room_zhou_chong_an":"Zhou", "room_lin_jiu":"Lin", "room_wu_ting_xiang":"Wu", "room_zhong_qi":"Zhong"}.get(id, "")
		if not actor.is_empty() and not bool(FlowManager.get_dialogic_var("Ch1.NPCIntro.%s.Introed" % actor, false)): room_name = "客房"
		button.text = ("● " if id == current_room else "") + room_name
		button.add_theme_color_override("font_color", STYLE.RED if id == current_room else STYLE.INK)
		button.add_theme_color_override("font_disabled_color", STYLE.MUTED)
	_legend.position = Vector2(12, plan.end.y + 40)
	queue_redraw()

func _p(x: float, y: float) -> Vector2:
	var rect := _plan_rect()
	return rect.position + Vector2(x, y) * rect.size

func _wall(a: Vector2, b: Vector2) -> void:
	draw_line(_p(a.x,a.y), _p(b.x,b.y), Color(0.31,0.25,0.19,0.85), 2.5, true)

func _draw() -> void:
	if not is_node_ready(): return
	var ink := Color(0.31,0.25,0.19,0.85)
	var plan := _plan_rect()
	draw_rect(plan, ink, false, 2.5)
	if shown_floor == 1:
		_wall(Vector2(0,.145),Vector2(1,.145))
		_wall(Vector2(.13,.145),Vector2(.13,1))
		_wall(Vector2(.212,.145),Vector2(.212,1))
		_wall(Vector2(0,.44),Vector2(.13,.44))
		_wall(Vector2(0,.725),Vector2(.13,.725))
		_wall(Vector2(.212,.345),Vector2(.33,.345))
		_wall(Vector2(.33,.345),Vector2(.33,.585))
		_wall(Vector2(.33,.45),Vector2(.662,.45))
		_wall(Vector2(.662,.145),Vector2(.662,.585))
		_wall(Vector2(.662,.345),Vector2(1,.345))
		_wall(Vector2(.785,.345),Vector2(.785,1))
		_wall(Vector2(.785,.585),Vector2(1,.585))
		draw_string(STYLE.reading_font(), _p(.005,.60), "卫生间", HORIZONTAL_ALIGNMENT_CENTER, plan.size.x*.12, 21, STYLE.MUTED)
		_stair(Rect2(.212,.345,.118,.24), true)
		_stair(Rect2(.662,.345,.123,.24), true)
		for point: Vector2 in [Vector2(.13,.24),Vector2(.13,.52),Vector2(.13,.81),Vector2(.662,.23),Vector2(.785,.66)]: _door(point)
	else:
		_wall(Vector2(.13,.23),Vector2(.87,.23))
		_wall(Vector2(.65,0),Vector2(.65,.23))
		_wall(Vector2(.13,.23),Vector2(.13,1))
		_wall(Vector2(.87,.23),Vector2(.87,1))
		_wall(Vector2(0,.56),Vector2(.13,.56))
		_wall(Vector2(.87,.56),Vector2(1,.56))
		_wall(Vector2(.33,.49),Vector2(.655,.49))
		_wall(Vector2(.215,.625),Vector2(.215,1))
		_wall(Vector2(.765,.625),Vector2(.765,1))
		_stair(Rect2(.215,.37,.115,.255), false)
		_stair(Rect2(.655,.37,.11,.255), false)
		draw_string(STYLE.reading_font(), _p(.34,.80), "挑空 · 护栏", HORIZONTAL_ALIGNMENT_CENTER, plan.size.x*.31, 25, STYLE.MUTED)
		for point: Vector2 in [Vector2(.13,.40),Vector2(.13,.78),Vector2(.87,.40),Vector2(.87,.78),Vector2(.46,.23),Vector2(.72,.23)]: _door(point)

func _stair(normalized: Rect2, up: bool) -> void:
	var rect := _plan_rect()
	var box := Rect2(rect.position + normalized.position * rect.size, normalized.size * rect.size)
	draw_rect(box, Color(0.4,.32,.24,.55), false, 1.5)
	for index: int in range(1,7):
		var y := box.position.y + box.size.y*index/7.0
		draw_line(Vector2(box.position.x,y),Vector2(box.end.x,y),Color(.4,.32,.24,.35),1)
	var center := box.get_center()
	var direction := -1.0 if up else 1.0
	draw_line(center-Vector2(0,12)*direction,center+Vector2(0,12)*direction,STYLE.INK,2)
	draw_line(center+Vector2(0,12)*direction,center+Vector2(-6,5)*direction,STYLE.INK,2)
	draw_line(center+Vector2(0,12)*direction,center+Vector2(6,5)*direction,STYLE.INK,2)

func _door(at: Vector2) -> void:
	var point := _p(at.x,at.y)
	draw_arc(point, 18, 0, PI*.5, 16, Color(.4,.32,.24,.7), 1.2, true)
