extends RefCounted


func get_var(path: String, default_value: Variant = null) -> Variant:
	if path.is_empty() or Dialogic == null:
		return default_value

	if Dialogic.VAR != null and Dialogic.VAR.has_method("get_variable"):
		return Dialogic.VAR.get_variable(path, default_value, true)

	var direct_value: Variant = Dialogic.VAR.get(path)
	if direct_value != null:
		return direct_value

	var current: Variant = Dialogic.VAR
	for part: String in path.split("."):
		if current == null:
			return default_value
		if current is Dictionary:
			current = (current as Dictionary).get(part, null)
		elif current is Object:
			current = (current as Object).get(part)
		else:
			return default_value

	if current == null:
		return default_value
	return current


func set_var(path: String, value: Variant) -> void:
	if path.is_empty() or Dialogic == null:
		return
	if Dialogic.VAR != null and Dialogic.VAR.has_method("set_variable"):
		if Dialogic.VAR.set_variable(path, value):
			return
	Dialogic.VAR.set(path, value)


func set_ch0_character_names_unknown() -> void:
	set_var("ButlerName", "？？")
	set_var("MetaName", "？？")
	set_var("ZhongQiName", "？？")


func set_ch0_character_names_revealed() -> void:
	set_var("ButlerName", "管家")
	set_var("MetaName", "梅塔")
	set_var("ZhongQiName", "钟歧")


func set_ch1_known_character_names_after_crime_scene() -> void:
	set_var("ButlerName", "管家")
	set_var("MetaName", "梅塔")
	set_var("ZhongQiName", "？？")
