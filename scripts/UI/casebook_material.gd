extends StyleBox

# Real CC0 document scan; no generated noise used as a paper substitute.
var scan: Texture2D
var kind := "sheet"
var tint := Color.WHITE
var active := false

func _draw(item: RID, rect: Rect2) -> void:
	if scan == null: return
	if kind == "book":
		var bookmark := PackedVector2Array([Vector2(rect.get_center().x + 12, rect.end.y - 35), Vector2(rect.get_center().x + 43, rect.end.y - 35), Vector2(rect.get_center().x + 43, rect.end.y + 20), Vector2(rect.get_center().x + 28, rect.end.y + 10), Vector2(rect.get_center().x + 12, rect.end.y + 20)])
		RenderingServer.canvas_item_add_polygon(item, bookmark, PackedColorArray([Color("743e36")]))
		_page(item, _shift(rect.grow(5), Vector2(3, 7)), Color("80715b"), 4)
		for i: int in range(3, 0, -1):
			_page(item, _shift(rect.grow(-float(i * 2)), Vector2(i * 2, i * 3)), Color("c9b99a"), i)
		var gap := 14.0
		var left := Rect2(rect.position, Vector2(rect.size.x * 0.5 - gap, rect.size.y))
		var right := Rect2(rect.position + Vector2(rect.size.x * 0.5 + gap, 0), Vector2(rect.size.x * 0.5 - gap, rect.size.y))
		_page(item, left, Color(1.06, 1.03, 0.96), 3)
		_page(item, right, Color(1.10, 1.07, 1.00), 9)
		for n: int in range(35):
			var alpha := 0.14 * pow(1.0 - float(n) / 35.0, 2)
			_line(item, Vector2(rect.get_center().x - gap - n, rect.position.y + 9), Vector2(rect.get_center().x - gap - n, rect.end.y - 7), Color(0.24, 0.16, 0.09, alpha), 2)
			_line(item, Vector2(rect.get_center().x + gap + n, rect.position.y + 9), Vector2(rect.get_center().x + gap + n, rect.end.y - 7), Color(0.24, 0.16, 0.09, alpha), 2)
		_border(item, right.grow(-27), Color(0.42, 0.29, 0.20, 0.36))
		_compass(item, right.end - Vector2(90, 100), 90, Color(0.35, 0.31, 0.25, 0.10))
		_botanical(item, Vector2(right.end.x - 40, right.end.y - 35), 0.8, Color(0.37, 0.31, 0.22, 0.16))
	elif kind == "newspaper":
		_page(item, _shift(rect, Vector2(-18, 15)), Color("b5a58a"), 2)
		_page(item, _shift(rect, Vector2(-8, -9)), Color("e5d6b8"), 9)
		_page(item, rect, Color(1.07, 1.04, 0.97), 6)
		var inset := rect.grow(-40)
		_line(item, Vector2(inset.position.x, rect.position.y + 22), Vector2(inset.end.x, rect.position.y + 22), Color("696056"), 4)
		_line(item, Vector2(inset.position.x, inset.end.y - 83), inset.end - Vector2(0, 83), Color("696056"), 5)
		# Narrow broken printer's rules, not synthetic unreadable language.
		for column: int in range(3):
			var x := inset.position.x + column * (inset.size.x / 3.0)
			for row: int in range(31):
				var y := inset.position.y + 145 + row * 19
				var width := inset.size.x / 3.0 - 16 - fmod(row * 37 + column * 19, 44)
				_line(item, Vector2(x, y), Vector2(x + width, y), Color(0.37, 0.32, 0.27, 0.10), 1)
		_magnifier(item, rect.position + rect.size * Vector2(0.24, 0.69), minf(rect.size.x * 0.09, 65))
		_compass(item, rect.position + rect.size * Vector2(0.78, 0.29), 60, Color(0.31, 0.27, 0.22, 0.13))
		_botanical(item, rect.position + Vector2(rect.size.x - 26, rect.size.y - 112), 0.65, Color(0.37, 0.31, 0.22, 0.22))
		_seal(item, rect.position + Vector2(rect.size.x - 76, 88), 26)
	elif kind == "location":
		var pts := PackedVector2Array([rect.position + Vector2(3, 6), Vector2(rect.end.x - 25, rect.position.y), Vector2(rect.end.x, rect.get_center().y), rect.end - Vector2(25, 3), Vector2(rect.position.x, rect.end.y - 2)])
		_poly(item, pts, rect, Color(1.08, 1.06, 1.0))
		_line(item, rect.position + Vector2(14, 9), Vector2(rect.end.x - 32, rect.position.y + 5), Color(0.4, 0.3, 0.2, 0.4))
		_line(item, Vector2(rect.position.x + 14, rect.end.y - 9), rect.end - Vector2(32, 9), Color(0.4, 0.3, 0.2, 0.4))
	elif kind == "name":
		_page(item, rect, Color(1.08, 1.04, 0.95), 3)
		_line(item, rect.position + Vector2(10, 5), rect.position + Vector2(10, rect.size.y - 7), Color("87443e"), 3)
		_paperclip(item, rect.position + Vector2(rect.size.x - 26, 8))
	elif kind == "ribbon":
		var pts := PackedVector2Array([rect.position + Vector2(12, 0), Vector2(rect.end.x - 14, rect.position.y + 2), rect.end - Vector2(2, 1), Vector2(rect.position.x + 4, rect.end.y), rect.position + Vector2(0, rect.size.y * 0.6)])
		_poly(item, pts, rect, tint)
		_line(item, rect.position + Vector2(18, rect.size.y - 7), rect.end - Vector2(18, 7), Color(0.4, 0.3, 0.2, 0.23), 1)
		_pin(item, rect.position + Vector2(rect.size.x - 18, 7))
	elif kind == "stamp":
		_page(item, rect, Color("eee5cf"), 2)
		_border(item, rect.grow(-9), Color("7f7665"))
	else:
		_page(item, rect, tint, 7)
		_border(item, rect.grow(-12), Color(0.42, 0.31, 0.21, 0.22))
		if rect.size.x > 400 and rect.size.y > 150:
			_botanical(item, rect.end - Vector2(22, 20), 0.4, Color(0.37, 0.31, 0.22, 0.15))

func _shift(rect: Rect2, delta: Vector2) -> Rect2:
	return Rect2(rect.position + delta, rect.size)

func _page(item: RID, rect: Rect2, color: Color, seed_value: int) -> void:
	var points := PackedVector2Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
	for side: int in range(4):
		var a: Vector2 = corners[side]
		var b: Vector2 = corners[(side + 1) % 4]
		var normal := (b - a).normalized().orthogonal()
		var count := maxi(8, int(a.distance_to(b) / 12))
		for i: int in range(count):
			var point := a.lerp(b, float(i) / count)
			point += normal * rng.randf_range(-1.7, 2.8)
			points.append(point)
	var shadow := PackedVector2Array()
	for p: Vector2 in points: shadow.append(p + Vector2(4, 6))
	RenderingServer.canvas_item_add_polygon(item, shadow, PackedColorArray([Color(0.07, 0.045, 0.02, 0.20)]))
	_poly(item, points, rect, color)

func _poly(item: RID, points: PackedVector2Array, rect: Rect2, color: Color) -> void:
	var uvs := PackedVector2Array()
	for p: Vector2 in points:
		var uv := (p - rect.position) / rect.size
		uvs.append(Vector2(0.06, 0.22) + uv * Vector2(0.88, 0.70))
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([color]), uvs, scan.get_rid())

func _line(item: RID, a: Vector2, b: Vector2, color: Color, width: float = 1) -> void:
	RenderingServer.canvas_item_add_line(item, a, b, color, width, true)

func _border(item: RID, rect: Rect2, color: Color) -> void:
	for offset: float in [0.0, 4.0]:
		var r := rect.grow(-offset)
		var points := PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), r.position])
		RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([color]), 1, true)

func _circle(item: RID, at: Vector2, radius: float, color: Color, width: float = 1) -> void:
	var points := PackedVector2Array()
	for n: int in range(97): points.append(at + Vector2.from_angle(TAU * n / 96.0) * radius)
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([color]), width, true)

func _compass(item: RID, at: Vector2, radius: float, color: Color) -> void:
	for r: float in [radius, radius * 0.92, radius * 0.72]: _circle(item, at, r, color)
	for n: int in range(32):
		var direction := Vector2.from_angle(TAU * n / 32.0)
		_line(item, at + direction * radius * (0.25 if n % 4 == 0 else 0.80), at + direction * radius, color)
	for n: int in range(8):
		var direction := Vector2.from_angle(TAU * n / 8.0)
		var points := PackedVector2Array([at, at + direction * radius * 0.7, at + direction.rotated(0.2) * radius * 0.22])
		RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([color]))

func _magnifier(item: RID, at: Vector2, radius: float) -> void:
	var ink := Color(0.24, 0.22, 0.18, 0.50)
	for r: float in [radius, radius - 4, radius - 7]: _circle(item, at, r, ink)
	var direction := Vector2(0.72, 0.69)
	_line(item, at + direction * (radius + 1), at + direction * (radius + 105), ink, 13)
	_line(item, at + direction * (radius + 8), at + direction * (radius + 100), Color(0.87, 0.82, 0.69, 0.8), 5)
	for n: int in range(20):
		var center := at + direction * (radius + 10 + n * 4)
		_line(item, center + Vector2(-4, 0), center + Vector2(4, -5), ink)

func _pin(item: RID, at: Vector2) -> void:
	_line(item, at + Vector2(-9, 22), at, Color("77716b"), 4)
	RenderingServer.canvas_item_add_circle(item, at + Vector2(1, 2), 9, Color(0.1, 0.05, 0.03, 0.25), true)
	RenderingServer.canvas_item_add_circle(item, at, 8, Color("713b35"), true)
	RenderingServer.canvas_item_add_circle(item, at - Vector2(2, 2), 3, Color("b77b6a"), true)

func _seal(item: RID, at: Vector2, radius: float) -> void:
	var edge := PackedVector2Array()
	for n: int in range(64):
		var angle := TAU * n / 64.0
		edge.append(at + Vector2.from_angle(angle) * radius * (1.0 + 0.055 * sin(angle * 9)))
	RenderingServer.canvas_item_add_circle(item, at + Vector2(2, 4), radius + 1, Color(0.12, 0.04, 0.02, 0.22), true)
	RenderingServer.canvas_item_add_polygon(item, edge, PackedColorArray([Color("82453c")]))
	_circle(item, at, radius * 0.79, Color("a96d59"), 2)
	_circle(item, at + Vector2(0, 1), radius * 0.70, Color("63342e"))
	for n: int in range(6):
		var axis := Vector2.from_angle(TAU * n / 6.0)
		_line(item, at, at + axis * radius * 0.48, Color("c28c72"), 1.3)
		for side: float in [-1.0, 1.0]:
			_line(item, at + axis * radius * 0.3, at + axis * radius * 0.18 + axis.orthogonal() * radius * 0.14 * side, Color("c28c72"))

func _paperclip(item: RID, at: Vector2) -> void:
	var points := PackedVector2Array([at + Vector2(0, 23), at + Vector2(0, -13), at + Vector2(4, -18), at + Vector2(11, -18), at + Vector2(15, -13), at + Vector2(15, 28), at + Vector2(11, 33), at + Vector2(4, 33), at + Vector2(4, -9), at + Vector2(9, -9), at + Vector2(9, 21)])
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([Color("7c6c51")]), 2.4, true)

func _botanical(item: RID, at: Vector2, scale_factor: float, ink: Color) -> void:
	for branch: int in range(3):
		var top := at + Vector2(-44 - branch * 28, -125 - branch * 10) * scale_factor
		var stem := PackedVector2Array()
		for n: int in range(25):
			var t := n / 24.0
			stem.append(at.lerp(top, t) + Vector2(sin(t * PI) * (-12 - branch * 3), 0) * scale_factor)
		RenderingServer.canvas_item_add_polyline(item, stem, PackedColorArray([ink]), 1.2, true)
		for n: int in range(1, 5):
			var root := stem[n * 4]
			var side := -1.0 if n % 2 == 0 else 1.0
			var tip := root + Vector2(side * 28 - 10, -26) * scale_factor
			var mid := root.lerp(tip, 0.5)
			var transverse := (tip - root).orthogonal().normalized() * 7 * scale_factor
			var leaf := PackedVector2Array([root, mid + transverse, tip, mid - transverse, root])
			RenderingServer.canvas_item_add_polygon(item, leaf, PackedColorArray([Color(ink, ink.a * 0.4)]))
			RenderingServer.canvas_item_add_polyline(item, leaf, PackedColorArray([ink]), 0.8, true)
			_line(item, root, tip, ink, 0.8)
		for petal: int in range(5):
			_circle(item, top + Vector2.from_angle(TAU * petal / 5.0) * 7 * scale_factor, 5 * scale_factor, ink)
		_circle(item, top, 3 * scale_factor, ink)
