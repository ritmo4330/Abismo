class_name ReasoningResolutionService
extends RefCounted

const ContentRegistry = preload("res://scripts/data/content_registry.gd")
const ClueService = preload("res://scripts/data/clue_service.gd")
const SuspicionService = preload("res://scripts/data/suspicion_service.gd")
const ResolutionResult = preload("res://scripts/data/resolution_result.gd")

var _registry: ContentRegistry
var _clue_service: ClueService
var _suspicion_service: SuspicionService
var _set_flag_callable: Callable


func setup(
	registry: ContentRegistry,
	clue_service: ClueService,
	suspicion_service: SuspicionService,
	set_flag_callable: Callable
) -> void:
	_registry = registry
	_clue_service = clue_service
	_suspicion_service = suspicion_service
	_set_flag_callable = set_flag_callable


func resolve_suspicion(suspicion_id: String) -> ResolutionResult:
	if suspicion_id.is_empty():
		return ResolutionResult.failure(suspicion_id)
	if not _suspicion_service.has_suspicion(suspicion_id):
		return ResolutionResult.failure(suspicion_id)
	if _suspicion_service.is_resolved(suspicion_id):
		return ResolutionResult.failure(suspicion_id)

	var suspicion_def: SuspicionData = _registry.get_suspicion_def(suspicion_id)
	if suspicion_def == null:
		push_error("ReasoningResolutionService.resolve_suspicion(): suspicion id '%s' has no registered SuspicionData." % suspicion_id)
		return ResolutionResult.failure(suspicion_id)

	if not _suspicion_service.mark_resolved(suspicion_id, suspicion_def.conclusion_clue_id):
		return ResolutionResult.failure(suspicion_id)

	if not suspicion_def.conclusion_clue_id.is_empty():
		_clue_service.discover_clue(suspicion_def.conclusion_clue_id, "reasoning", suspicion_id)

	var unlocked_ids: PackedStringArray = PackedStringArray()
	for unlock_suspicion_id: String in suspicion_def.unlock_suspicion_ids:
		if unlock_suspicion_id.is_empty():
			continue
		if _suspicion_service.discover_suspicion(unlock_suspicion_id, "reasoning", suspicion_id):
			unlocked_ids.append(unlock_suspicion_id)

	if not suspicion_def.resolved_world_flag.is_empty() and _set_flag_callable.is_valid():
		_set_flag_callable.call(suspicion_def.resolved_world_flag, true)

	return ResolutionResult.success_result(
		suspicion_id,
		suspicion_def.conclusion_clue_id,
		unlocked_ids,
		suspicion_def.resolved_world_flag
	)
