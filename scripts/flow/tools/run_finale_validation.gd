extends Node

const TIMELINES: PackedStringArray = [
	"res://assets/dialogues/ch2_deepening/2_6_memory_fragments.dtl",
	"res://assets/dialogues/ch3_transcend/3_1_route.dtl",
	"res://assets/dialogues/finale/4_1_ending_dust.dtl",
	"res://assets/dialogues/finale/4_2_ending_godslayer.dtl",
	"res://assets/dialogues/finale/4_3_ending_calm.dtl",
	"res://assets/dialogues/finale/4_4_ending_clear_snow.dtl",
	"res://assets/dialogues/finale/4_5_easter_egg.dtl",
]

func _ready() -> void:
	var failed: bool = false
	for path: String in TIMELINES:
		var timeline: Resource = load(path)
		if timeline == null:
			push_error("Finale validation: cannot load %s" % path)
			failed = true
			continue
		timeline.process()
		if timeline.events.is_empty():
			push_error("Finale validation: no events parsed from %s" % path)
			failed = true
		else:
			print("Parsed %s (%d events)" % [path, timeline.events.size()])
	get_tree().quit(1 if failed else 0)
