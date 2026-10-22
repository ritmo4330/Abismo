extends SceneTree

const BOOK = preload("res://scripts/UI/casebook_style.gd")
var characters: Dictionary = {}
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	for folder: String in ["res://assets/dialogues", "res://assets/objects", "res://scripts/UI"]:
		scan_text(folder)
	var missing := ""
	var fallback_count := 0
	for code: int in characters:
		if not BOOK.FONT.has_char(code):
			fallback_count += 1
		if not BOOK.reading_font().has_char(code):
			missing += String.chr(code)
	check(missing.is_empty(), "Chinese text has glyph coverage: " + missing)
	print("Checked CJK glyphs=", characters.size(), ", fallback glyphs=", fallback_count)
	var theme: Theme = BOOK.theme()
	check(theme.get_font("normal_font", "RichTextLabel") == BOOK.reading_font(), "Rich text uses the same print face as paper controls")
	check(theme.get_font("bold_font", "RichTextLabel").base_font == BOOK.FONT, "Emphasized text keeps the same letterforms")
	check(BOOK.display_font(850).variation_embolden >= 0.35 and BOOK.display_font(850).variation_embolden <= 0.65, "Display headings use stronger ink without excessive bold")
	check(theme.get_color("font_shadow_color", "Button").a == 0, "Paper typography has no pasted-on shadow")
	check(BOOK.reading_font() == BOOK.reading_font(), "Reading font is shared consistently")
	print("Casebook typography failures=", failures)
	quit(0 if failures == 0 else 1)

func scan_text(path: String) -> void:
	for directory: String in DirAccess.get_directories_at(path):
		scan_text(path.path_join(directory))
	for file: String in DirAccess.get_files_at(path):
		if file.get_extension() not in ["dtl", "tres", "gd"]:
			continue
		var content := FileAccess.get_file_as_string(path.path_join(file))
		for index: int in content.length():
			var code := content.unicode_at(index)
			if code >= 0x3400 and code <= 0x9fff:
				characters[code] = true

func check(ok: bool, description: String) -> void:
	print(("PASS: " if ok else "FAIL: ") + description)
	if not ok:
		failures += 1
