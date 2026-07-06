extends RefCounted

const FlowDialogicVars = preload("res://scripts/flow/flow_dialogic_vars.gd")


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


func apply_character_name_state(name_state: String) -> void:
	match name_state:
		"all_unknown":
			_set_character_names("？？", "？？", "？？")
		"butler_meta_known":
			_set_character_names("管家", "梅塔", "？？")
		"all_revealed":
			_set_character_names("管家", "梅塔", "钟歧")
		_:
			_set_character_names("管家", "梅塔", "钟歧")


func _set_character_names(butler_name: String, meta_name: String, zhong_qi_name: String) -> void:
	set_var(FlowDialogicVars.BUTLER_NAME, butler_name)
	set_var(FlowDialogicVars.META_NAME, meta_name)
	set_var(FlowDialogicVars.ZHONG_QI_NAME, zhong_qi_name)
