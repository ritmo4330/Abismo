extends DialogicBackground

@onready var color_rect: ColorRect = $ColorRect


func _ready() -> void:
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _update_background(argument: String, _time: float) -> void:
	color_rect.color = Color.from_string(argument, Color.TRANSPARENT)
