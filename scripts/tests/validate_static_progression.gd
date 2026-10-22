extends SceneTree

var _elapsed: float = 0.0
var _started: bool = false
var _study_case: bool = false
var _corridor_case: bool = false
var _events: Array[String] = []
var _initial_camera_x: float = 0.0
var _max_camera_x: float = 0.0


func _initialize() -> void:
	_study_case = OS.get_cmdline_user_args().has("--study")
	_corridor_case = OS.get_cmdline_user_args().has("--corridor")
	call_deferred("_boot")


func _boot() -> void:
	var bus: Node = root.get_node("EventBus")
	var flow: Node = root.get_node("FlowManager")
	var manager: Node = root.get_node("SceneManager")
	var game: Node = root.get_node("GameManager")
	flow.reset_gameplay_runtime()
	game.enter_gameplay()
	var host := Node2D.new()
	host.name = "GameRoot"
	root.add_child(host)
	current_scene = host
	bus.dialogue_finished.connect(_on_dialogue_finished)
	if _corridor_case:
		flow.apply_flow_state("ch1_snow_villa", "ch1_7_second_search")
		manager.initialize(host, "res://scenes/ch1_snow_villa/ch1_lab_corridor_cutscene.tscn", "InitialSpawn")
	elif _study_case:
		flow.apply_flow_state("ch1_snow_villa", "ch1_1_study_free_investigation")
		manager.initialize(host, "res://scenes/ch1_snow_villa/ch1_study.tscn", "SpawnFromChair")
		for clue_id: String in ["1_study_1", "1_study_2", "1_study_3", "1_study_4", "1_study_5"]:
			root.get_node("DataManager").discover_clue(clue_id, "test", "static_progression")
	else:
		flow.apply_flow_state("ch0_prologue", "ch0_0_2_snow_camp")
		flow.set_pending_auto_timeline("0_2_snow_camp_arrival")
		manager.initialize(host, "res://scenes/ch0_prologue/ch0_snow_field.tscn", "InitialSpawn")
		_initial_camera_x = manager.current_room.get_node("StaticPresentationCamera").position.x
	root.get_node("TextSpeedManager").set("_hold_acceleration", true)
	_started = true


func _process(delta: float) -> bool:
	if not _started:
		return false
	_elapsed += delta
	var manager: Node = root.get_node("SceneManager")
	var dialogic: Node = root.get_node("Dialogic")
	if _corridor_case:
		if dialogic.current_timeline != null and dialogic.current_timeline.resource_path.ends_with("1_7_lab_arrival.dtl"):
			print("PASS: corridor animation -> laboratory CG -> chapter title -> laboratory arrival, no movement input.")
			quit(0)
	elif _study_case:
		if dialogic.current_timeline != null and dialogic.current_timeline.resource_path.ends_with("1_1_puzzle_reasoning.dtl"):
			assert(_events.has("1_1_study_clues_finished"))
			assert(_events.has("1_1_puzzle_story"))
			assert(_events.has("1_1_puzzle_followup"))
			assert(_events.has("1_1_challenge_rules"))
			print("PASS: study clues -> narration -> puzzle -> challenge -> reasoning, no walking or chair clicks.")
			quit(0)
	elif manager.current_room != null:
		var camera: Camera2D = manager.current_room.get_node_or_null("StaticPresentationCamera")
		if camera != null:
			_max_camera_x = maxf(_max_camera_x, camera.position.x)
		if root.get_node("FlowManager").get_current_room_id() == "hall" and not manager.is_transitioning:
			var expected: Array[String] = ["0_2_snow_camp_arrival", "0_2_snow_path_interlude", "0_2_snow_path_arrival", "0_2_villa_gate_interlude", "0_2_villa_gate_arrival", "0_2_villa_gate_story", "0_2_villa_door_knock"]
			assert(_events == expected, "Prologue sequence mismatch: %s" % str(_events))
			assert(_max_camera_x > _initial_camera_x + 1500.0, "Camera did not pan across the snowfield")
			print("PASS: all seven snowfield dialogues in order -> hall, camera travelled left to right without player input.")
			quit(0)
	if _elapsed > 65.0:
		push_error("Static progression stalled: room=%s timelines=%s" % [root.get_node("FlowManager").get_current_room_id(), str(_events)])
		quit(1)
	return false


func _on_dialogue_finished(timeline_name: String) -> void:
	_events.append(timeline_name)
	print("Dialogue finished: ", timeline_name)
