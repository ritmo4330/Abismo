extends SceneTree
var failures := 0
func _initialize() -> void:
	call_deferred("run")
func run() -> void:
	var data = root.get_node("DataManager")
	var summary = load("res://scripts/data/body_search_summary.gd")
	data.reset_runtime_state()
	check(not data.has_clue(summary.SUMMARY_ID), "No table before first search")
	data.add_clue("1_mu_0", "test", "first")
	check(data.has_clue(summary.SUMMARY_ID), "First search creates table")
	var text: String = summary.render(data)
	check(text.contains(summary.ROWS[0][3]) and not text.contains(summary.ROWS[0][4]) and not text.contains(summary.ROWS[2][3]), "Only discovered first result is shown")
	data.add_clue("1_lin_0", "test", "first")
	text = summary.render(data)
	check(text.contains(summary.ROWS[2][3]) and not text.contains(summary.ROWS[2][4]), "Lin first search does not reveal repeat")
	data.add_clue("1_lin_0_25", "test", "repeat")
	text = summary.render(data)
	check(text.contains("[i]" + summary.ROWS[2][4] + "[/i]") and not text.contains(summary.ROWS[0][4]), "Only acquired repeat is appended in italics")
	var saved: Dictionary = data.save_runtime_state().duplicate(true)
	data.reset_runtime_state()
	data.load_runtime_state(saved)
	check(summary.render(data) == text, "Save restores table details")
	data.reset_runtime_state()
	data._clues.discover_clue("1_zhou_0", "test", "legacy")
	var legacy: Dictionary = data.save_runtime_state().duplicate(true)
	data.reset_runtime_state()
	data.load_runtime_state(legacy)
	check(data.has_clue(summary.SUMMARY_ID) and summary.render(data).contains(summary.ROWS[1][3]), "Legacy saves rebuild table")
	var host := Node2D.new()
	root.add_child(host)
	current_scene = host
	var panel = load("res://scenes/UI/clue_panel.tscn").instantiate()
	host.add_child(panel)
	await process_frame
	var archive: Array[String] = panel._get_archive_sorted_discovered_ids()
	check(archive.has(summary.SUMMARY_ID) and not archive.has("1_zhou_0"), "Archive contains one table instead of separate body clues")
	panel._show_clue_detail(summary.SUMMARY_ID)
	check(panel.detail_body.bbcode_enabled and panel.detail_body.text.contains("[table=2]"), "Handbook renders the two-column table")
	print("Body search table failures=", failures)
	quit(0 if failures == 0 else 1)
func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok: failures += 1
