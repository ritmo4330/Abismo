extends RefCounted

const FlowEffect = preload("res://scripts/flow/flow_effect.gd")


static func validate(registry: RefCounted) -> Array[String]:
	var errors: Array[String] = []
	if registry == null:
		return ["Flow registry is null."]

	for chapter_id: Variant in registry.get_chapter_ids():
		var definition: RefCounted = registry.get_definition(String(chapter_id))
		if definition == null:
			errors.append("Missing chapter definition: %s" % String(chapter_id))
			continue
		_validate_definition(definition, errors)
	return errors


static func _validate_definition(definition: RefCounted, errors: Array[String]) -> void:
	if String(definition.chapter_id).is_empty():
		errors.append("Chapter definition has an empty chapter_id.")
		return

	_validate_transition_table(definition.chapter_id, "entry", definition.entry_transitions, errors)
	_validate_transition_table(definition.chapter_id, "event", definition.event_transitions, errors)
	_validate_npc_locations(definition.chapter_id, definition.base_npc_locations_by_step, errors)
	_validate_follow_rules(definition.chapter_id, definition.follow_npc_rules_by_step, errors)
	_validate_bgm(definition.chapter_id, definition.step_bgm_configs, errors)


static func _validate_transition_table(
	chapter_id: String,
	table_name: String,
	transitions: Dictionary,
	errors: Array[String]
) -> void:
	for transition_id: Variant in transitions.keys():
		var transition: Variant = transitions[transition_id]
		if not (transition is RefCounted) or not transition.handled:
			errors.append("%s %s transition is not handled." % [chapter_id, String(transition_id)])
			continue
		_validate_effects(chapter_id, "%s:%s" % [table_name, String(transition_id)], transition.immediate_effects, errors)
		_validate_effects(chapter_id, "%s:%s after_dialogue" % [table_name, String(transition_id)], transition.after_dialogue_effects, errors)


static func _validate_effects(chapter_id: String, source_id: String, effects: Array, errors: Array[String]) -> void:
	for index: int in range(effects.size()):
		var effect: Variant = effects[index]
		if not (effect is RefCounted):
			errors.append("%s %s effect %d is not a RefCounted effect." % [chapter_id, source_id, index])
			continue
		_validate_effect(chapter_id, source_id, index, effect, errors)


static func _validate_effect(
	chapter_id: String,
	source_id: String,
	index: int,
	effect: RefCounted,
	errors: Array[String]
) -> void:
	var prefix: String = "%s %s effect %d" % [chapter_id, source_id, index]
	match effect.type:
		FlowEffect.Type.SET_STATE:
			if effect.chapter_id.is_empty() or effect.step_id.is_empty():
				errors.append("%s SET_STATE requires chapter_id and step_id." % prefix)
		FlowEffect.Type.SET_STEP:
			if effect.step_id.is_empty():
				errors.append("%s SET_STEP requires step_id." % prefix)
		FlowEffect.Type.REQUEST_SCENE:
			_validate_scene_path(prefix, effect.scene_path, errors)
		FlowEffect.Type.REQUEST_DIALOGUE:
			if effect.timeline_name.is_empty():
				errors.append("%s REQUEST_DIALOGUE requires timeline_name." % prefix)
		FlowEffect.Type.SET_DIALOGIC_VAR, FlowEffect.Type.SET_PRIVATE_CHAT_TARGET_FROM_DIALOGIC, FlowEffect.Type.REQUEST_SCENE_IF_DIALOGIC_BOOL:
			if effect.dialogic_path.is_empty():
				errors.append("%s requires dialogic_path." % prefix)
			if effect.type == FlowEffect.Type.REQUEST_SCENE_IF_DIALOGIC_BOOL:
				_validate_scene_path(prefix, effect.scene_path, errors)
		FlowEffect.Type.SET_NPC_LOCATION:
			if effect.npc_id.is_empty():
				errors.append("%s SET_NPC_LOCATION requires npc_id." % prefix)
			if not effect.room_id.is_empty() and effect.spawn_name.is_empty():
				errors.append("%s SET_NPC_LOCATION with a room requires spawn_name." % prefix)
		FlowEffect.Type.SHOW_TOAST:
			if effect.title.is_empty():
				errors.append("%s SHOW_TOAST requires title." % prefix)
		FlowEffect.Type.ADD_SUSPICION_IF_MISSING, FlowEffect.Type.REQUEST_LOCKED_SUSPICION:
			if effect.suspicion_id.is_empty():
				errors.append("%s requires suspicion_id." % prefix)


static func _validate_scene_path(prefix: String, scene_path: String, errors: Array[String]) -> void:
	if scene_path.is_empty():
		return
	if not ResourceLoader.exists(scene_path):
		errors.append("%s scene does not exist: %s" % [prefix, scene_path])


static func _validate_npc_locations(chapter_id: String, locations_by_step: Dictionary, errors: Array[String]) -> void:
	for step_id: Variant in locations_by_step.keys():
		var locations: Variant = locations_by_step[step_id]
		if not (locations is Dictionary):
			errors.append("%s NPC locations for step %s must be a Dictionary." % [chapter_id, String(step_id)])
			continue
		for npc_id: Variant in (locations as Dictionary).keys():
			var location: Variant = locations[npc_id]
			if not (location is Dictionary):
				errors.append("%s NPC location %s/%s must be a Dictionary." % [chapter_id, String(step_id), String(npc_id)])
				continue
			if String(location.get("room_id", "")).is_empty():
				errors.append("%s NPC location %s/%s missing room_id." % [chapter_id, String(step_id), String(npc_id)])
			if String(location.get("spawn", "")).is_empty():
				errors.append("%s NPC location %s/%s missing spawn." % [chapter_id, String(step_id), String(npc_id)])


static func _validate_follow_rules(chapter_id: String, rules_by_step: Dictionary, errors: Array[String]) -> void:
	for step_id: Variant in rules_by_step.keys():
		var rules: Variant = rules_by_step[step_id]
		if not (rules is Array):
			errors.append("%s follow rules for step %s must be an Array." % [chapter_id, String(step_id)])
			continue
		for index: int in range((rules as Array).size()):
			var rule: Variant = (rules as Array)[index]
			if not (rule is Dictionary):
				errors.append("%s follow rule %s/%d must be a Dictionary." % [chapter_id, String(step_id), index])
				continue
			if String(rule.get("npc_id", "")).is_empty():
				errors.append("%s follow rule %s/%d missing npc_id." % [chapter_id, String(step_id), index])
			if String(rule.get("spawn", "")).is_empty():
				errors.append("%s follow rule %s/%d missing spawn." % [chapter_id, String(step_id), index])
			var rooms: Variant = rule.get("rooms", [])
			if not (rooms is Array) or (rooms as Array).is_empty():
				errors.append("%s follow rule %s/%d requires rooms." % [chapter_id, String(step_id), index])


static func _validate_bgm(chapter_id: String, bgm_by_step: Dictionary, errors: Array[String]) -> void:
	for step_id: Variant in bgm_by_step.keys():
		var config: Variant = bgm_by_step[step_id]
		if not (config is Dictionary):
			errors.append("%s BGM config for step %s must be a Dictionary." % [chapter_id, String(step_id)])
			continue
		if String(config.get("track_id", "")).is_empty():
			errors.append("%s BGM config for step %s missing track_id." % [chapter_id, String(step_id)])
