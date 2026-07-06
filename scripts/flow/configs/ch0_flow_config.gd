extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")

const MANUAL_UNLOCKED_STEPS: Array[String] = []

const STEP_BGM_CONFIGS: Dictionary = {
	FlowIds.STEP_CH0_IDENTITY: {"track_id": "cassandra_memory", "fade_seconds": 2.0},
	FlowIds.STEP_CH0_PROLOGUE_STORY: {"track_id": "role_exit", "fade_seconds": 2.0},
	FlowIds.STEP_CH0_SNOW_CAMP: {"track_id": "role_exit", "fade_seconds": 2.0},
	FlowIds.STEP_CH0_SNOW_PATH: {"track_id": "role_exit", "fade_seconds": 2.0},
	FlowIds.STEP_CH0_VILLA_GATE: {"track_id": "role_exit", "fade_seconds": 2.0},
	FlowIds.STEP_CH0_HALL_ARRIVAL: {"track_id": "role_exit", "fade_seconds": 2.0},
}

const BASE_NPC_LOCATIONS_BY_STEP: Dictionary = {
	FlowIds.STEP_CH0_HALL_ARRIVAL: {
		"meta": {"room_id": FlowIds.ROOM_HALL, "spawn": "Meta"},
	},
}
