extends SceneTree

const TIMELINES: PackedStringArray = [
	"res://assets/dialogues/ch2_deepening/2_3_third_search_intro.dtl",
	"res://assets/dialogues/ch2_deepening/2_3_third_search_turn.dtl",
	"res://assets/dialogues/ch2_deepening/2_3_missing_body_found.dtl",
	"res://assets/dialogues/ch2_deepening/2_4_third_reasoning.dtl",
	"res://assets/dialogues/ch2_deepening/2_5_mu.dtl",
	"res://assets/dialogues/ch2_deepening/2_5_zhou.dtl",
	"res://assets/dialogues/ch2_deepening/2_5_lin.dtl",
	"res://assets/dialogues/ch2_deepening/2_5_wu.dtl",
	"res://assets/dialogues/ch2_deepening/2_5_zhong.dtl",
]


func _initialize() -> void:
	var failed: bool = false
	for timeline_path: String in TIMELINES:
		var timeline: Resource = load(timeline_path)
		if timeline == null:
			failed = true
			push_error("Unable to load timeline: %s" % timeline_path)
		else:
			print("Loaded timeline: %s" % timeline_path)
	quit(1 if failed else 0)
