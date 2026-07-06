extends Node

const ContentRegistry = preload("res://scripts/data/content_registry.gd")
const GameStateStore = preload("res://scripts/data/game_state_store.gd")
const ClueService = preload("res://scripts/data/clue_service.gd")
const SuspicionService = preload("res://scripts/data/suspicion_service.gd")
const ReasoningResolutionService = preload("res://scripts/data/reasoning_resolution_service.gd")
const NoticeService = preload("res://scripts/data/notice_service.gd")
const ClueState = preload("res://scripts/data/clue_state.gd")
const SuspicionState = preload("res://scripts/data/suspicion_state.gd")
const ResolutionResult = preload("res://scripts/data/resolution_result.gd")

signal clue_updated(clue_id: String)
signal suspicion_updated(suspicion_id: String)
signal affinity_changed(npc_id: String, new_value: int)
signal ui_notice_requested(message: String, notice_type: String)
signal world_flag_changed(flag_id: String, value: bool)

const AFFINITY_MIN: int = 0
const AFFINITY_MAX: int = 100
const AFFINITY_STAGE_ALIENATED: String = "alienated"
const AFFINITY_STAGE_NEUTRAL: String = "neutral"
const AFFINITY_STAGE_TRUSTED: String = "trusted"

var _registry: ContentRegistry = ContentRegistry.new()
var _store: GameStateStore = GameStateStore.new()
var _clues: ClueService = ClueService.new()
var _suspicions: SuspicionService = SuspicionService.new()
var _resolution: ReasoningResolutionService = ReasoningResolutionService.new()
var _notices: NoticeService = NoticeService.new()


func _ready() -> void:
	_clues.setup(_store, _registry)
	_suspicions.setup(_store, _registry)
	_resolution.setup(_registry, _clues, _suspicions, Callable(self, "set_flag"))
	_notices.setup(_registry)
	_connect_service_signals()

	var registry_errors: Array[String] = _registry.load_all()
	for error: String in registry_errors:
		push_error(error)


func reset_runtime_state() -> void:
	_store.reset()


func save_runtime_state() -> Dictionary:
	return _store.to_dict()


func load_runtime_state(data: Dictionary) -> void:
	_store.from_dict(data)
	for clue_id: String in _store.clue_states.keys():
		clue_updated.emit(clue_id)
	for suspicion_id: String in _store.suspicion_states.keys():
		suspicion_updated.emit(suspicion_id)
	for flag_id: String in _store.world_flags.keys():
		world_flag_changed.emit(flag_id, _store.world_flags[flag_id])
	for npc_id: String in _store.affinity.keys():
		affinity_changed.emit(npc_id, _store.affinity[npc_id])


func register_clue_def(clue_def: ClueData) -> void:
	_registry.register_clue_def(clue_def)


func register_clue_defs(clue_def_list: Array[ClueData]) -> void:
	_registry.register_clue_defs(clue_def_list)


func has_clue_def(clue_id: String) -> bool:
	return _registry.has_clue_def(clue_id)


func get_clue_def(clue_id: String) -> ClueData:
	return _registry.get_clue_def(clue_id)


func register_suspicion_def(suspicion_def: SuspicionData) -> void:
	_registry.register_suspicion_def(suspicion_def)


func register_suspicion_defs(suspicion_def_list: Array[SuspicionData]) -> void:
	_registry.register_suspicion_defs(suspicion_def_list)


func has_suspicion_def(suspicion_id: String) -> bool:
	return _registry.has_suspicion_def(suspicion_id)


func get_suspicion_def(suspicion_id: String) -> SuspicionData:
	return _registry.get_suspicion_def(suspicion_id)


func discover_clue(clue_id: String, source_type: String = "scene", source_id: String = "") -> bool:
	return _clues.discover_clue(clue_id, source_type, source_id)


func add_clue(clue_id: String, source_type: String = "scene", source_id: String = "") -> bool:
	return discover_clue(clue_id, source_type, source_id)


func has_clue(clue_id: String) -> bool:
	return _clues.has_clue(clue_id)


func mark_clue_read(clue_id: String) -> void:
	_clues.mark_read(clue_id)


func get_clue_state(clue_id: String) -> ClueState:
	return _clues.get_state(clue_id)


func get_discovered_clue_ids(sort_mode: String = "discover") -> PackedStringArray:
	return _clues.get_discovered_clue_ids(sort_mode)


func get_discovered_clues() -> PackedStringArray:
	return get_discovered_clue_ids()


func get_clues_by_category_path(path: PackedStringArray) -> PackedStringArray:
	return _clues.get_clues_by_category_path(path)


func get_clues_by_tag(tag: String) -> PackedStringArray:
	return _clues.get_clues_by_tag(tag)


func get_parent_clue_id(clue_id: String) -> String:
	return _clues.get_parent_clue_id(clue_id)


func get_child_clue_ids(clue_id: String) -> PackedStringArray:
	return _clues.get_child_clue_ids(clue_id)


func is_deep_unlocked(parent_clue_id: String) -> bool:
	return _clues.is_deep_unlocked(parent_clue_id)


func unlock_deep_clues(parent_clue_id: String) -> PackedStringArray:
	return _clues.unlock_deep_clues(parent_clue_id)


func mark_deep_unlocked(parent_clue_id: String) -> bool:
	if parent_clue_id.is_empty() or not has_clue(parent_clue_id) or is_deep_unlocked(parent_clue_id):
		return false
	unlock_deep_clues(parent_clue_id)
	return is_deep_unlocked(parent_clue_id)


func discover_suspicion(suspicion_id: String, source_type: String = "dialogue", source_id: String = "") -> bool:
	return _suspicions.discover_suspicion(suspicion_id, source_type, source_id)


func add_suspicion(suspicion_id: String, source_type: String = "dialogue", source_id: String = "") -> bool:
	return discover_suspicion(suspicion_id, source_type, source_id)


func has_suspicion(suspicion_id: String) -> bool:
	return _suspicions.has_suspicion(suspicion_id)


func get_suspicion_state(suspicion_id: String) -> SuspicionState:
	return _suspicions.get_state(suspicion_id)


func get_discovered_suspicion_ids(sort_mode: String = "discover") -> PackedStringArray:
	return _suspicions.get_discovered_suspicion_ids(sort_mode)


func get_all_suspicions() -> PackedStringArray:
	return get_discovered_suspicion_ids()


func is_suspicion_resolved(suspicion_id: String) -> bool:
	return _suspicions.is_resolved(suspicion_id)


func mark_suspicion_read(suspicion_id: String) -> void:
	_suspicions.mark_read(suspicion_id)


func resolve_suspicion(suspicion_id: String) -> ResolutionResult:
	return _resolution.resolve_suspicion(suspicion_id)


func set_flag(flag_id: String, value: bool = true) -> void:
	if flag_id.is_empty():
		return
	var previous_value: bool = has_flag(flag_id)
	_store.world_flags[flag_id] = value
	if previous_value != value:
		world_flag_changed.emit(flag_id, value)


func has_flag(flag_id: String) -> bool:
	if flag_id.is_empty():
		return false
	return _store.world_flags.get(flag_id, false)


func set_world_flag(flag_id: String, value: bool = true) -> void:
	set_flag(flag_id, value)


func get_world_flag(flag_id: String) -> bool:
	return has_flag(flag_id)


func change_affinity(npc_id: String, delta: int) -> int:
	if npc_id.is_empty():
		return 0
	return set_affinity(npc_id, get_affinity(npc_id) + delta)


func set_affinity(npc_id: String, value: int) -> int:
	if npc_id.is_empty():
		return 0
	var clamped_value: int = clampi(value, AFFINITY_MIN, AFFINITY_MAX)
	var previous_value: int = get_affinity(npc_id)
	_store.affinity[npc_id] = clamped_value
	if previous_value != clamped_value:
		affinity_changed.emit(npc_id, clamped_value)
	return clamped_value


func get_affinity(npc_id: String) -> int:
	if npc_id.is_empty():
		return 0
	return _store.affinity.get(npc_id, 0)


func get_affinity_stage(npc_id: String) -> String:
	var value: int = get_affinity(npc_id)
	if value < 30:
		return AFFINITY_STAGE_ALIENATED
	if value <= 70:
		return AFFINITY_STAGE_NEUTRAL
	return AFFINITY_STAGE_TRUSTED


func validate_content() -> Array[String]:
	return _registry.validate_references()


func _connect_service_signals() -> void:
	if not _clues.clue_updated.is_connected(_on_clue_updated):
		_clues.clue_updated.connect(_on_clue_updated)
	if not _clues.clue_discovered.is_connected(_notices.on_clue_discovered):
		_clues.clue_discovered.connect(_notices.on_clue_discovered)
	if not _clues.deep_clues_unlocked.is_connected(_notices.on_deep_clues_unlocked):
		_clues.deep_clues_unlocked.connect(_notices.on_deep_clues_unlocked)
	if not _suspicions.suspicion_updated.is_connected(_on_suspicion_updated):
		_suspicions.suspicion_updated.connect(_on_suspicion_updated)
	if not _suspicions.suspicion_discovered.is_connected(_notices.on_suspicion_discovered):
		_suspicions.suspicion_discovered.connect(_notices.on_suspicion_discovered)
	if not _notices.notice_requested.is_connected(_on_notice_requested):
		_notices.notice_requested.connect(_on_notice_requested)


func _on_clue_updated(clue_id: String) -> void:
	clue_updated.emit(clue_id)


func _on_suspicion_updated(suspicion_id: String) -> void:
	suspicion_updated.emit(suspicion_id)


func _on_notice_requested(message: String, notice_type: String) -> void:
	ui_notice_requested.emit(message, notice_type)
