class_name ContentRegistry
extends RefCounted

const CLUE_RESOURCE_ROOT: String = "res://assets/objects/clues"
const SUSPICION_RESOURCE_ROOT: String = "res://assets/objects/suspicions"
const RESOURCE_EXTENSION: String = "tres"

var _clue_defs: Dictionary[String, ClueData] = {}
var _suspicion_defs: Dictionary[String, SuspicionData] = {}


func load_all() -> Array[String]:
	_clue_defs.clear()
	_suspicion_defs.clear()
	_register_clue_defs_in_directory(CLUE_RESOURCE_ROOT)
	_register_suspicion_defs_in_directory(SUSPICION_RESOURCE_ROOT)
	return validate_references()


func register_clue_def(clue_def: ClueData) -> void:
	if clue_def == null:
		return
	if clue_def.id.is_empty():
		push_error("ContentRegistry.register_clue_def(): clue id is empty.")
		return
	if _clue_defs.has(clue_def.id):
		if _clue_defs[clue_def.id] == clue_def:
			return
		push_error("ContentRegistry: duplicate clue id '%s'." % clue_def.id)
		return
	_clue_defs[clue_def.id] = clue_def


func register_clue_defs(clue_def_list: Array[ClueData]) -> void:
	for clue_def: ClueData in clue_def_list:
		register_clue_def(clue_def)


func register_suspicion_def(suspicion_def: SuspicionData) -> void:
	if suspicion_def == null:
		return
	if suspicion_def.id.is_empty():
		push_error("ContentRegistry.register_suspicion_def(): suspicion id is empty.")
		return
	if _suspicion_defs.has(suspicion_def.id):
		if _suspicion_defs[suspicion_def.id] == suspicion_def:
			return
		push_error("ContentRegistry: duplicate suspicion id '%s'." % suspicion_def.id)
		return
	_suspicion_defs[suspicion_def.id] = suspicion_def


func register_suspicion_defs(suspicion_def_list: Array[SuspicionData]) -> void:
	for suspicion_def: SuspicionData in suspicion_def_list:
		register_suspicion_def(suspicion_def)


func has_clue_def(clue_id: String) -> bool:
	return not clue_id.is_empty() and _clue_defs.has(clue_id)


func get_clue_def(clue_id: String) -> ClueData:
	if clue_id.is_empty():
		return null
	return _clue_defs.get(clue_id, null)


func has_suspicion_def(suspicion_id: String) -> bool:
	return not suspicion_id.is_empty() and _suspicion_defs.has(suspicion_id)


func get_suspicion_def(suspicion_id: String) -> SuspicionData:
	if suspicion_id.is_empty():
		return null
	return _suspicion_defs.get(suspicion_id, null)


func get_clue_ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for clue_id: String in _clue_defs.keys():
		result.append(clue_id)
	return result


func get_suspicion_ids() -> PackedStringArray:
	var result: PackedStringArray = PackedStringArray()
	for suspicion_id: String in _suspicion_defs.keys():
		result.append(suspicion_id)
	return result


func validate_references() -> Array[String]:
	var errors: Array[String] = []
	for clue_id: String in _clue_defs.keys():
		var clue_def: ClueData = _clue_defs[clue_id]
		if not clue_def.parent_clue_id.is_empty() and not _clue_defs.has(clue_def.parent_clue_id):
			errors.append("Clue '%s' references missing parent clue '%s'." % [clue_id, clue_def.parent_clue_id])
		for child_id: String in clue_def.child_clue_ids:
			if child_id.is_empty():
				errors.append("Clue '%s' has an empty child clue id." % clue_id)
			elif not _clue_defs.has(child_id):
				errors.append("Clue '%s' references missing child clue '%s'." % [clue_id, child_id])

	for suspicion_id: String in _suspicion_defs.keys():
		var suspicion_def: SuspicionData = _suspicion_defs[suspicion_id]
		for required_clue_id: String in suspicion_def.required_clue_ids:
			if required_clue_id.is_empty():
				errors.append("Suspicion '%s' has an empty required clue id." % suspicion_id)
			elif not _clue_defs.has(required_clue_id):
				errors.append("Suspicion '%s' references missing required clue '%s'." % [suspicion_id, required_clue_id])
		if not suspicion_def.conclusion_clue_id.is_empty() and not _clue_defs.has(suspicion_def.conclusion_clue_id):
			errors.append("Suspicion '%s' references missing conclusion clue '%s'." % [suspicion_id, suspicion_def.conclusion_clue_id])
		for unlock_suspicion_id: String in suspicion_def.unlock_suspicion_ids:
			if unlock_suspicion_id.is_empty():
				errors.append("Suspicion '%s' has an empty unlocked suspicion id." % suspicion_id)
			elif not _suspicion_defs.has(unlock_suspicion_id):
				errors.append("Suspicion '%s' references missing unlocked suspicion '%s'." % [suspicion_id, unlock_suspicion_id])
	return errors


func _register_clue_defs_in_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("ContentRegistry: unable to open clue resource directory '%s'." % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var resource_name: String = _normalize_exported_resource_name(entry_name)
		var entry_path: String = directory_path.path_join(resource_name)
		if directory.current_is_dir():
			_register_clue_defs_in_directory(entry_path)
		elif resource_name.get_extension().to_lower() == RESOURCE_EXTENSION:
			_try_register_clue_def_resource(entry_path)

		entry_name = directory.get_next()
	directory.list_dir_end()


func _try_register_clue_def_resource(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource == null:
		push_error("ContentRegistry: failed to load clue resource '%s'." % resource_path)
		return
	if resource is ClueData:
		register_clue_def(resource as ClueData)


func _register_suspicion_defs_in_directory(directory_path: String) -> void:
	var directory: DirAccess = DirAccess.open(directory_path)
	if directory == null:
		push_error("ContentRegistry: unable to open suspicion resource directory '%s'." % directory_path)
		return

	directory.list_dir_begin()
	var entry_name: String = directory.get_next()
	while not entry_name.is_empty():
		if entry_name.begins_with("."):
			entry_name = directory.get_next()
			continue

		var resource_name: String = _normalize_exported_resource_name(entry_name)
		var entry_path: String = directory_path.path_join(resource_name)
		if directory.current_is_dir():
			_register_suspicion_defs_in_directory(entry_path)
		elif resource_name.get_extension().to_lower() == RESOURCE_EXTENSION:
			_try_register_suspicion_def_resource(entry_path)

		entry_name = directory.get_next()
	directory.list_dir_end()


func _try_register_suspicion_def_resource(resource_path: String) -> void:
	var resource: Resource = load(resource_path)
	if resource == null:
		push_error("ContentRegistry: failed to load suspicion resource '%s'." % resource_path)
		return
	if resource is SuspicionData:
		register_suspicion_def(resource as SuspicionData)


func _normalize_exported_resource_name(entry_name: String) -> String:
	if entry_name.ends_with(".remap"):
		return entry_name.trim_suffix(".remap")
	return entry_name
