extends SceneTree

const FlowConfigValidator = preload("res://scripts/flow/tools/flow_config_validator.gd")
const FlowRegistry = preload("res://scripts/flow/flow_registry.gd")
const ContentRegistry = preload("res://scripts/data/content_registry.gd")

const REQUIRED_PLAN_SUSPICIONS: Dictionary = {
	"1_suspicion_ability": "以柔克刚？",
	"1_suspicion_meta_in_lin_room": "无人的案发现场",
	"1_suspicion_locked_room": "密室杀人",
	"1_suspicion_missing_weapon": "消失的凶器",
	"1_suspicion_butler_request": "管家的委托",
	"1_suspicion_missing_body": "消失的尸体",
	"1_suspicion_lighthouse_story": "灯塔木雕的故事",
	"1_suspicion_lin_custom": "林玖的习俗",
	"2_suspicion_parallel_worlds": "平行世界",
	"2_suspicion_dream_space": "梦境空间",
	"3_suspicion_god_weapon": "弑神的武器",
}


func _init() -> void:
	var errors: Array[String] = FlowConfigValidator.validate(FlowRegistry.new())
	var content_registry: ContentRegistry = ContentRegistry.new()
	errors.append_array(content_registry.load_all())
	_validate_required_plan_suspicions(content_registry, errors)
	if errors.is_empty():
		print("Flow and content config validation passed.")
		quit(0)
		return

	for error: String in errors:
		push_error(error)
	quit(1)


func _validate_required_plan_suspicions(content_registry: ContentRegistry, errors: Array[String]) -> void:
	for suspicion_id: String in REQUIRED_PLAN_SUSPICIONS:
		var suspicion_def: SuspicionData = content_registry.get_suspicion_def(suspicion_id)
		if suspicion_def == null:
			errors.append("Missing required plan suspicion: %s" % suspicion_id)
			continue
		var expected_title: String = String(REQUIRED_PLAN_SUSPICIONS[suspicion_id])
		if suspicion_def.title != expected_title:
			errors.append(
				"Plan suspicion '%s' title mismatch: expected '%s', got '%s'." % [
					suspicion_id,
					expected_title,
					suspicion_def.title,
				]
			)
