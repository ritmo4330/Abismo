extends SceneTree

const Catalog = preload("res://scripts/data/evidence_card_catalog.gd")
const OUTPUT := "C:/Users/LEGION/.codex/visualizations/2026/09/24/01a0d40a-9cd4-7022-a18e-0135878d5cb7/evidence-cards/"
var failures := 0

func _initialize() -> void:
	create_timer(100, true, false, true).timeout.connect(func() -> void: quit(1))
	call_deferred("run")

func run() -> void:
	var data := root.get_node("DataManager")
	var flow := root.get_node("FlowManager")
	flow.reset_gameplay_runtime()
	root.get_node("GameManager").enter_gameplay()
	flow.apply_flow_state("ch1_snow_villa", "ch1_6_private_chat")
	var host := Node2D.new()
	root.add_child(host)
	current_scene = host
	for name: String in ["clue_panel", "suspicion_panel"]:
		host.add_child(load("res://scenes/UI/%s.tscn" % name).instantiate())
	check(Catalog.authored().size() == 17, "All supplied pages imported")
	check(Catalog.clue_cards().is_empty() and Catalog.person_cards().is_empty(), "No undiscovered facts appear")
	flow.set_dialogic_var("Ch1.NPCIntro.Mu.Introed", true)
	var profiles := Catalog.person_cards()
	check(profiles.size() == 1 and profiles[0].facts.is_empty(), "Meeting Mu creates only the known profile")
	for i: int in range(1, 4):
		flow.set_dialogic_var("Ch1.NPCIntro.Mu.Selected%d" % i, true)
	profiles = Catalog.person_cards()
	check(profiles[0].facts.size() == 1, "Completing introductions reveals one fact")
	flow.set_dialogic_var("Ch1.PrivateChat.Mu.Asked.Zhong", true)
	profiles = Catalog.person_cards()
	check(profiles[0].facts.size() == 2, "Private conversation reveals only its fact")
	var saved: Dictionary = data.save_runtime_state().duplicate(true)
	data.reset_runtime_state()
	data.load_runtime_state(saved)
	check(not Catalog.authored()["person/mu"].has("facts"), "Reading never mutates authored facts")
	flow.set_dialogic_var("Ch1.NPCIntro.Zhong.Introed", true)
	flow.set_dialogic_var("Ch1.PrivateChat.Zhong.Removed.WorldTheory", true)
	profiles = Catalog.person_cards()
	var zhong: Dictionary = profiles.filter(func(c: Dictionary) -> bool: return c.person == "zhong")[0]
	check(not str(zhong.facts).contains("弦理论"), "Declining world theory does not reveal explanation")
	data.set_flag("cards/zhong/world_theory", true)
	profiles = Catalog.person_cards()
	zhong = profiles.filter(func(c: Dictionary) -> bool: return c.person == "zhong")[0]
	check(str(zhong.facts).contains("弦理论"), "Accepted explanation reveals the right fact")

	data.add_clue("1_testimony_3_all", "test", "cards")
	var pages := Catalog.clue_cards()
	check(pages.size() == 5, "Five statements become five separate cards")
	check(pages.all(func(c: Dictionary) -> bool: return c.evidence_id == "1_testimony_3_all"), "Pages retain the original evidence identity")
	var archive := host.get_node("CluePanel")
	archive._open_archive_panel()
	await process_frame
	var reader: CanvasLayer = archive._cards
	check(reader.visible and reader.cards.size() == 5, "Normal handbook entry opens card reading")
	var first: String = reader.selected_id
	reader.next_button.pressed.emit()
	check(reader.selected_id != first, "Next button turns a card")
	reader.previous_button.pressed.emit()
	check(reader.selected_id == first, "Previous button returns to first card")
	reader.search.text = "陈述人：周崇安"
	reader.search.text_changed.emit(reader.search.text)
	check(reader.filtered.size() == 1 and reader._current().source.contains("周崇安"), "Card search filters statements by speaker")
	reader.search.clear()
	reader.search.text_changed.emit("")
	reader._select("1_testimony_3_all/1")
	await snapshot("statement-card.png")
	root.size = Vector2i(1280, 720)
	root.content_scale_size = Vector2i(1280, 720)
	await process_frame
	await process_frame
	check(reader.surface.get_global_rect().end.x <= 1281 and reader.surface.get_global_rect().end.y <= 721, "Card interface fits 1280 by 720")
	await snapshot("statement-card-1280.png")
	reader.close_button.pressed.emit()
	check(not archive.visible and not paused, "Return releases the archive pause")

	data.add_suspicion("1_suspicion_butler_request", "test", "cards")
	var doubts := Catalog.suspicion_cards()
	check(doubts[0].title == "穆执的委托" and doubts[0].table[1][1] == "", "Mu owns the supplied unfilled commission card")
	archive._open_archive_panel()
	reader.open(1, "suspicion/1_suspicion_butler_request")
	await snapshot("commission-card.png")
	reader.open(2, "person/mu")
	await snapshot("profile-card.png")
	reader.close()
	check(not archive.visible, "Closing profile view returns to gameplay")

	data.add_clue("2_dream_rules", "test", "cards")
	var rules := Catalog.clue_cards(PackedStringArray(["2_dream_rules"]))
	check(rules.size() == 1 and rules[0].paragraphs.size() == 7 and rules[0].source == "陈述人：周崇安", "Seven dream rules remain a single attributed card")

	flow.apply_flow_state("ch1_snow_villa", "ch1_1_puzzle")
	var manual := host.get_node("SuspicionPanel")
	data.add_suspicion("1_suspicion_crime_info", "test", "cards")
	data.add_clue("1_puzzle_maid_scene", "test", "cards")
	manual._selected_suspicion_id = "1_suspicion_crime_info"
	manual._open_archive_panel()
	manual._cards.open(0, "1_puzzle_maid_scene", false, true)
	manual._cards.use_button.pressed.emit()
	check(manual._get_slot_ids("1_suspicion_crime_info")[0] == "1_puzzle_maid_scene", "Using a card fills the selected blank")
	check(not data.is_suspicion_resolved("1_suspicion_crime_info") and not manual._is_novel_evidence_fixed("1_suspicion_crime_info", "1_puzzle_maid_scene"), "Using a card does not auto-confirm")
	manual._on_locked_suspicion_requested("1_suspicion_crime_info", "")
	manual._cards.open(1, "suspicion/1_suspicion_butler_request", false)
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	manual._input(escape)
	check(manual.visible and not manual._cards.visible and manual._is_locked_and_unresolved(), "Card escape returns to the locked problem")
	print("Evidence card regression failures=", failures)
	quit(0 if failures == 0 else 1)

func snapshot(name: String) -> void:
	if not OS.get_cmdline_user_args().has("--capture"):
		return
	await create_timer(0.3, true, false, true).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name)

func check(ok: bool, message: String) -> void:
	print("PASS: " if ok else "FAIL: ", message)
	if not ok:
		failures += 1
