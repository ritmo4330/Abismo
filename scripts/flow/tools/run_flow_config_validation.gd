extends SceneTree

const FlowConfigValidator = preload("res://scripts/flow/tools/flow_config_validator.gd")
const FlowRegistry = preload("res://scripts/flow/flow_registry.gd")
const ContentRegistry = preload("res://scripts/data/content_registry.gd")


func _init() -> void:
	var errors: Array[String] = FlowConfigValidator.validate(FlowRegistry.new())
	var content_registry: ContentRegistry = ContentRegistry.new()
	errors.append_array(content_registry.load_all())
	if errors.is_empty():
		print("Flow and content config validation passed.")
		quit(0)
		return

	for error: String in errors:
		push_error(error)
	quit(1)
