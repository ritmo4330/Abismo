extends Node2D

# Temporary, code-native flower-sea art authorized by the user after two
# image-generation network failures. Canvas and clue coordinates match the
# static-scene manifest; no source story text or dialogue is added here.
var flowers: Array[Dictionary] = []
const PETALS := [Color("aa789b"), Color("bba5ca"), Color("d9bd80"), Color("d8a7a5"), Color("888eae"), Color("d8cbbb")]

func _ready() -> void:
	name = "TemporaryFlowerSea"
	var rng := RandomNumberGenerator.new()
	rng.seed = 430916
	for index: int in 1250:
		var y := rng.randf_range(520, 1100)
		var depth := (y - 490) / 610
		flowers.append({"at": Vector2(rng.randf_range(-20, 1940), y), "size": rng.randf_range(2.5, 7.0) * (0.3 + depth), "color": PETALS[rng.randi_range(0, PETALS.size() - 1)], "phase": rng.randf_range(-0.7, 0.7)})
	queue_redraw()

func _draw() -> void:
	for strip: int in 110:
		var t := strip / 109.0
		draw_rect(Rect2(0, strip * 10, 1920, 11), Color("74818b").lerp(Color("d0c8ad"), minf(t * 2, 1)))
	_poly([Vector2(0,375), Vector2(190,190), Vector2(355,305), Vector2(520,120), Vector2(765,330), Vector2(960,220), Vector2(1215,365), Vector2(1490,210), Vector2(1720,320), Vector2(1920,190), Vector2(1920,650), Vector2(0,650)], Color("899290"))
	_poly([Vector2(0,465), Vector2(230,320), Vector2(420,410), Vector2(675,310), Vector2(870,435), Vector2(1100,340), Vector2(1340,450), Vector2(1630,350), Vector2(1920,405), Vector2(1920,700), Vector2(0,700)], Color("707e75"))
	# The villa's two wings frame the garden without hiding the open field.
	_villa(Rect2(5, 160, 620, 460), false)
	_villa(Rect2(1280, 165, 640, 455), true)
	_poly([Vector2(0,555), Vector2(400,505), Vector2(790,540), Vector2(1210,510), Vector2(1580,570), Vector2(1920,530), Vector2(1920,1080), Vector2(0,1080)], Color("4a5944"))
	# A worn path curves to the real return door at (.84, .36).
	_poly([Vector2(1570,530), Vector2(1690,530), Vector2(1690,650), Vector2(1585,780), Vector2(1600,1080), Vector2(1460,1080), Vector2(1450,775), Vector2(1580,635)], Color("8c8a6c"))
	for flower: Dictionary in flowers:
		var at: Vector2 = flower.at
		if at.x > 1480 and at.x < 1690 and at.y > 575: continue
		_flower(at, float(flower.size), flower.color, float(flower.phase))
	_security_bars_and_body()
	_folded_dress()
	# Slight atmospheric vignette, retaining readable clickable silhouettes.
	for strip: int in 18:
		draw_rect(Rect2(0, 900 + strip * 10, 1920, 11), Color(0.025, 0.035, 0.03, strip / 58.0))

func _villa(rect: Rect2, right: bool) -> void:
	draw_rect(rect, Color("7d7c6f"))
	_poly([rect.position + Vector2(-28, 20), rect.position + Vector2(110, -92), rect.position + Vector2(rect.size.x - 50, -92), rect.position + Vector2(rect.size.x + 35, 20)], Color("373e3c"))
	draw_rect(Rect2(rect.position + Vector2(0, 6), Vector2(rect.size.x, 14)), Color("3d4039"))
	draw_rect(Rect2(rect.position + Vector2(0, 198), Vector2(rect.size.x, 12)), Color("48483e"))
	for x: int in range(40, int(rect.size.x), 175):
		draw_rect(Rect2(rect.position + Vector2(x, 12), Vector2(10, rect.size.y - 12)), Color("48483e"))
		_window(rect.position + Vector2(x + 33, 53), Vector2(90, 112))
		if not right: _window(rect.position + Vector2(x + 33, 245), Vector2(90, 120))
	if right:
		# Door bounds agree with the manifest's generous return-click rectangle.
		var door := Rect2(1505, 255, 220, 328)
		draw_rect(door.grow(15), Color("333832"))
		draw_rect(door, Color("5e5847"))
		for line: int in 7:
			draw_line(door.position + Vector2(line * 32, 0), door.position + Vector2(line * 32, door.size.y), Color("44473c"), 2)
		draw_rect(Rect2(1535, 285, 160, 85), Color("707b72"))
		draw_line(Vector2(1615,285), Vector2(1615,370), Color("3d443c"), 5)
		draw_circle(Vector2(1692,444), 7, Color("b5a779"))
		draw_rect(Rect2(1488, 583, 253, 12), Color("b3ac94"))

func _window(at: Vector2, dimensions: Vector2) -> void:
	draw_rect(Rect2(at - Vector2(5,5), dimensions + Vector2(10,10)), Color("41483f"))
	draw_rect(Rect2(at, dimensions), Color("8c9b96"))
	_poly([at, at + Vector2(dimensions.x * .7,0), at + dimensions * .5, at + Vector2(0,dimensions.y)], Color(0.7,0.75,0.69,0.32))
	draw_line(at + Vector2(dimensions.x / 2, 0), at + Vector2(dimensions.x / 2, dimensions.y), Color("494f44"), 5)
	draw_line(at + Vector2(0, dimensions.y / 2), at + Vector2(dimensions.x, dimensions.y / 2), Color("494f44"), 5)

func _security_bars_and_body() -> void:
	# Distant non-graphic silhouette; the existing clue retains precise details.
	draw_line(Vector2(65,525), Vector2(590,525), Color("242e2b"), 10)
	draw_line(Vector2(65,620), Vector2(590,620), Color("242e2b"), 9)
	for index: int in 13:
		var x := 82.0 + index * 40
		draw_line(Vector2(x,460), Vector2(x,675), Color("2b3430"), 7)
		_poly([Vector2(x-9,465), Vector2(x,443), Vector2(x+9,465)], Color("242e2b"))
	_poly([Vector2(254,466),Vector2(311,442),Vector2(360,452),Vector2(415,498),Vector2(398,537),Vector2(342,508),Vector2(298,512)], Color("30343a"))
	draw_line(Vector2(340,493), Vector2(371,569), Color("34363b"), 19)
	draw_line(Vector2(369,565), Vector2(388,580), Color("767366"), 11)
	draw_line(Vector2(268,489), Vector2(209,563), Color("30343a"), 24)
	draw_line(Vector2(277,493), Vector2(265,578), Color("30343a"), 24)
	draw_line(Vector2(208,560), Vector2(187,568), Color("222c2b"), 16)
	draw_line(Vector2(263,577), Vector2(239,588), Color("222c2b"), 16)
	draw_circle(Vector2(421,522), 22, Color("7c796b"))
	draw_arc(Vector2(421,516), 23, PI, TAU, 14, Color("2c3332"), 12)
	# Broken flowerpot and spider-plant shapes already mentioned in the clue.
	_poly([Vector2(230,683),Vector2(249,667),Vector2(265,689),Vector2(247,700)], Color("9a7560"))
	_poly([Vector2(470,682),Vector2(491,664),Vector2(505,693)], Color("8d6755"))
	for offset: int in 7:
		draw_polyline(PackedVector2Array([Vector2(485,686),Vector2(475 + offset*8,648-offset*2),Vector2(458+offset*13,672)]), Color("82915c"), 3, true)

func _folded_dress() -> void:
	draw_ellipse_shadow(Vector2(1410,815), Vector2(118,34))
	_poly([Vector2(1328,777),Vector2(1467,765),Vector2(1511,817),Vector2(1354,839)], Color("c9c7b7"))
	_poly([Vector2(1335,772),Vector2(1462,760),Vector2(1501,804),Vector2(1351,823)], Color("ede9d8"))
	_poly([Vector2(1350,770),Vector2(1345,739),Vector2(1368,729),Vector2(1378,751),Vector2(1421,749),Vector2(1431,726),Vector2(1453,733),Vector2(1450,765),Vector2(1458,790),Vector2(1360,803)], Color("f1eddf"))
	draw_polyline(PackedVector2Array([Vector2(1378,751),Vector2(1396,762),Vector2(1421,749)]), Color("b5b6ab"), 3, true)
	for index: int in 6:
		draw_line(Vector2(1362+index*20,801-index*2), Vector2(1370+index*20,814-index*2), Color("c1c0af"), 2, true)
	draw_line(Vector2(1351,823), Vector2(1501,804), Color("adaf9e"), 2, true)

func draw_ellipse_shadow(center: Vector2, radius: Vector2) -> void:
	var points := PackedVector2Array()
	for index: int in 40:
		var angle := TAU * index / 40.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	draw_colored_polygon(points, Color(0.06, 0.10, 0.06, .55))

func _flower(at: Vector2, radius: float, color: Color, phase: float) -> void:
	draw_line(at, at + Vector2(phase * radius, radius * 3.2), Color("394937"), maxf(1, radius * .25))
	for index: int in 5:
		var angle := TAU * index / 5.0 + phase
		draw_circle(at + Vector2(cos(angle), sin(angle)) * radius * .55, radius * .58, color)
	draw_circle(at, radius * .27, Color("dcc798"))

func _poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)
