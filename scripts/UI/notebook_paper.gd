extends StyleBox

# Live paper and pencil surfaces: text and controls stay native, selectable UI.
var role := "page"
var seam_ratio := 0.27
var mark_y := 32.0
var mark_x := -1.0
var mark_radius := 88.0
var scan: Texture2D

func _draw(item: RID, rect: Rect2) -> void:
	var paper := Color("f7f3eb")
	var ink := Color("202b43")
	var red := Color("aa5145")
	if role == "book":
		RenderingServer.canvas_item_add_rect(item, rect, Color("494644"))
		var page := rect.grow(-8)
		var outline := _rounded(page, 22)
		RenderingServer.canvas_item_add_polygon(item, outline, PackedColorArray([paper]))
		_paper_texture(item, page, outline)
		outline.append(outline[0])
		RenderingServer.canvas_item_add_polyline(item, outline, PackedColorArray([Color(0.52, 0.46, 0.37, 0.5)]), 1.6, true)
		var spine := rect.position.x + rect.size.x * seam_ratio
		for i: int in range(15):
			var alpha := 0.025 * (1.0 - float(i) / 15.0)
			_line(item, Vector2(spine - i, page.position.y), Vector2(spine - i, page.end.y), Color(0.26, 0.22, 0.18, alpha), 1.0)
			_line(item, Vector2(spine + i, page.position.y), Vector2(spine + i, page.end.y), Color(0.26, 0.22, 0.18, alpha), 1.0)
		for y: int in range(int(page.position.y + 80), int(page.end.y - 35), 115):
			RenderingServer.canvas_item_add_circle(item, Vector2(spine, y), 1.8, Color(0.37, 0.32, 0.25, 0.25))
	elif role in ["page", "writing", "reading"]:
		if role == "page":
			RenderingServer.canvas_item_add_rect(item, rect, paper)
			_texture(item, rect)
		for y: int in range(int(rect.position.y + 48), int(rect.end.y - 12), 48):
			_line(item, Vector2(rect.position.x + 12, y), Vector2(rect.end.x - 12, y), Color(0.34, 0.45, 0.49, 0.065), 1.0)
		if role == "reading":
			var tape := PackedVector2Array()
			for point: Vector2 in [Vector2(-30, -9), Vector2(32, -10), Vector2(31, 8), Vector2(-29, 9)]:
				tape.append(rect.position + Vector2(14, -3) + point.rotated(-0.5))
			RenderingServer.canvas_item_add_polygon(item, tape, PackedColorArray([Color(0.79, 0.70, 0.48, 0.22)]))
	elif role in ["index", "selected"]:
		if role == "selected":
			var mark := Rect2(rect.position + Vector2(4, 12), rect.size - Vector2(8, 21))
			var brush := PackedVector2Array([mark.position, Vector2(mark.end.x - 7, mark.position.y + 2), Vector2(mark.end.x, mark.position.y + 12), Vector2(mark.end.x - 5, mark.position.y + 25), Vector2(mark.end.x, mark.end.y - 3), Vector2(mark.position.x + 8, mark.end.y), Vector2(mark.position.x, mark.end.y - 7)])
			RenderingServer.canvas_item_add_polygon(item, brush, PackedColorArray([Color(0.96, 0.75, 0.35, 0.22)]))
			_line(item, rect.position + Vector2(3, 9), Vector2(rect.position.x + 2, rect.end.y - 9), red, 2.0)
			_line(item, rect.position + Vector2(7, 12), Vector2(rect.position.x + 6, rect.end.y - 12), Color(red, 0.5), 1.0)
			_oval(item, Vector2(rect.position.x + mark_x if mark_x >= 0 else rect.get_center().x, rect.position.y + mark_y), Vector2(minf(mark_radius, rect.size.x * 0.45), 23), Color(red, 0.8))
		_line(item, Vector2(rect.position.x + 8, rect.end.y - 1), rect.end - Vector2(8, 1), Color(ink, 0.18), 1.0)
	elif role in ["tab", "active_tab"]:
		var tab := PackedVector2Array([rect.position + Vector2(2, 2), Vector2(rect.end.x - 4, rect.position.y), Vector2(rect.end.x, rect.end.y - 3), Vector2(rect.end.x - 12, rect.end.y - 1), Vector2(rect.end.x - 21, rect.end.y - 3), Vector2(rect.end.x - 33, rect.end.y), Vector2(rect.position.x + 21, rect.end.y - 2), Vector2(rect.position.x, rect.end.y)])
		var shadow := tab.duplicate()
		for i: int in shadow.size(): shadow[i] += Vector2(1.5, 3)
		RenderingServer.canvas_item_add_polygon(item, shadow, PackedColorArray([Color(0.20, 0.18, 0.14, 0.13)]))
		RenderingServer.canvas_item_add_polygon(item, tab, PackedColorArray([Color("f1ebde") if role == "tab" else Color("f8e8b9")]))
		_line(item, Vector2(rect.position.x, rect.end.y - 1), rect.end - Vector2(1, 2), Color(ink, 0.24), 1.0)
		if role == "active_tab":
			_oval(item, rect.get_center(), Vector2(rect.size.x * 0.42, rect.size.y * 0.37), red)
	elif role == "action":
		_border(item, rect.grow(-3), red)
		_line(item, rect.position + Vector2(6, rect.size.y - 5), rect.end - Vector2(4, 2), Color(red, 0.35), 1.0)
	elif role == "search":
		var outline := _rounded(rect.grow(-2), 10)
		outline.append(outline[0])
		RenderingServer.canvas_item_add_polyline(item, outline, PackedColorArray([Color(ink, 0.7)]), 1.2, true)
		_oval(item, Vector2(rect.position.x + 23, rect.get_center().y - 2), Vector2(8, 8), Color(ink, 0.8))
		_pen_line(item, Vector2(rect.position.x + 29, rect.get_center().y + 4), Vector2(rect.position.x + 37, rect.get_center().y + 12), Color(ink, 0.8), 1.8, 0.25)
	elif role == "ink_rule":
		_pen_line(item, Vector2(rect.position.x, rect.get_center().y), Vector2(rect.end.x, rect.get_center().y), Color(ink, 0.7), 1.0, 1.2)
	elif role == "heading":
		_pen_line(item, Vector2(rect.position.x, rect.end.y - 3), rect.end - Vector2(4, 6), Color(red, 0.8), 1.8, 3.0)
		_pen_line(item, Vector2(rect.position.x + 8, rect.end.y - 1), rect.end - Vector2(16, 4), Color(red, 0.2), 0.8, 1.8)

func _rounded(rect: Rect2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	var centers := [rect.position + Vector2(radius, radius), Vector2(rect.end.x - radius, rect.position.y + radius), rect.end - Vector2(radius, radius), Vector2(rect.position.x + radius, rect.end.y - radius)]
	for corner: int in range(4):
		for step: int in range(9):
			var angle := PI + corner * PI * 0.5 + step * PI / 16.0
			points.append(centers[corner] + Vector2(cos(angle), sin(angle)) * radius)
	return points

func _paper_texture(item: RID, rect: Rect2, points: PackedVector2Array) -> void:
	if scan == null: return
	var uvs := PackedVector2Array()
	for point: Vector2 in points:
		uvs.append(Vector2(0.25, 0.25) + (point - rect.position) / rect.size * 0.5)
	RenderingServer.canvas_item_add_polygon(item, points, PackedColorArray([Color(1, 1, 1, 0.14)]), uvs, scan.get_rid())

func _texture(item: RID, rect: Rect2) -> void:
	if scan != null:
		var center := Rect2(Vector2(scan.get_width(), scan.get_height()) * 0.25, Vector2(scan.get_width(), scan.get_height()) * 0.5)
		RenderingServer.canvas_item_add_texture_rect_region(item, rect, scan.get_rid(), center, Color(1, 1, 1, 0.075))

func _line(item: RID, a: Vector2, b: Vector2, color: Color, width := 1.0) -> void:
	RenderingServer.canvas_item_add_line(item, a, b, color, width, true)

func _border(item: RID, rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array([rect.position + Vector2(1, 2), Vector2(rect.end.x - 1, rect.position.y), rect.end - Vector2(1, 1), Vector2(rect.position.x, rect.end.y - 1), rect.position + Vector2(1, 2)])
	for i: int in range(points.size() - 1):
		_pen_line(item, points[i], points[i + 1], color, 1.25, 1.3)

func _pen_line(item: RID, a: Vector2, b: Vector2, color: Color, width: float, amplitude: float) -> void:
	var normal := (b - a).normalized().orthogonal()
	var pieces := maxi(12, int(a.distance_to(b) / 9))
	for i: int in range(pieces):
		var t0 := float(i) / pieces
		var t1 := float(i + 1) / pieces
		var bend0 := sin(t0 * PI) * (sin(t0 * 7.2) + 0.35 * sin(t0 * 17.1)) * amplitude
		var bend1 := sin(t1 * PI) * (sin(t1 * 7.2) + 0.35 * sin(t1 * 17.1)) * amplitude
		_line(item, a.lerp(b, t0) + normal * bend0, a.lerp(b, t1) + normal * bend1, color, width * (0.9 + 0.14 * sin(t0 * 8.3)))

func _oval(item: RID, center: Vector2, radius: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	for i: int in range(49):
		var angle := TAU * float(i) / 48.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y + cos(angle) * 2))
	RenderingServer.canvas_item_add_polyline(item, points, PackedColorArray([color]), 1.4, true)
