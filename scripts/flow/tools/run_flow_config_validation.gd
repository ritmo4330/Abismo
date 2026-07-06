extends SceneTree

const FlowConfigValidator = preload("res://scripts/flow/tools/flow_config_validator.gd")
const FlowRegistry = preload("res://scripts/flow/flow_registry.gd")


func _init() -> void:
	var errors: Array[String] = FlowConfigValidator.validate(FlowRegistry.new())
	if errors.is_empty():
		print("Flow config validation passed.")
		quit(0)
		return

	for error: String in errors:
		push_error(error)
	quit(1)
