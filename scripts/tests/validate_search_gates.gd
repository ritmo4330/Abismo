extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var flow: Node = root.get_node("FlowManager")
	var data: Node = root.get_node("DataManager")
	var registry: RefCounted = load("res://scripts/flow/flow_registry.gd").new()
	var cases: Array[Array] = [
		["ch1_snow_villa", "ch1_4_first_search", "initial_search_required_clues", "Ch1.InitialSearch.Finished"],
		["ch1_snow_villa", "ch1_7_second_search", "second_search_required_clues", "Ch1.SecondSearch.Finished"],
		["ch2_deepening", "ch1_7_second_search", "second_search_required_clues", "Ch1.SecondSearch.Finished"],
		["ch2_deepening", "ch2_3_third_search", "third_search_required_clues", "Ch2.ThirdSearch.Finished"],
	]
	for test: Array in cases:
		flow.reset_gameplay_runtime()
		flow.apply_flow_state(test[0], test[1])
		var definition: RefCounted = registry.get_definition(test[0])
		var required: Array = definition.get(test[2])
		for i: int in range(required.size()):
			check(not bool(flow.get_dialogic_var(test[3], false)), "Missing clue keeps search open: " + String(required[i]))
			data.discover_clue(required[i], "test", "search_gate")
		check(bool(flow.get_dialogic_var(test[3], false)), "All required clues complete: " + String(test[1]))
		check(flow.get_current_step_id() == test[1], "Collecting clues does not skip the butler conversation")
		var saved: Dictionary = data.save_runtime_state()
		var state: Dictionary = flow.save_runtime_state()
		flow.reset_gameplay_runtime()
		data.load_runtime_state(saved)
		flow.load_runtime_state(state)
		check(bool(flow.get_dialogic_var(test[3], false)), "Loaded clues recalculate search completion")
	print("Search gate regression failures=", failures)
	quit(0 if failures == 0 else 1)

func check(ok: bool, text: String) -> void:
	print("PASS: " + text if ok else "FAIL: " + text)
	if not ok:
		failures += 1
