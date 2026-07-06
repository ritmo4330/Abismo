extends RefCounted

const FlowIds = preload("res://scripts/flow/flow_ids.gd")

const FIRST_SEARCH_BUTLER_FOLLOW_ROOMS: Array[String] = [
	FlowIds.ROOM_HALL,
	FlowIds.ROOM_FLOOR2,
	FlowIds.ROOM_ZOU_LANG,
	FlowIds.ROOM_CAN_TING,
	FlowIds.ROOM_HUI_KE_TING,
	FlowIds.ROOM_FIRST_SEARCH,
	FlowIds.ROOM_META,
	FlowIds.ROOM_MU_ZHI,
	FlowIds.ROOM_WU_TING_XIANG,
	FlowIds.ROOM_ZHONG_QI,
	FlowIds.ROOM_ZHOU_CHONG_AN,
	FlowIds.ROOM_SECOND_SEARCH,
]

const STEP_BGM_CONFIGS: Dictionary = {
	FlowIds.STEP_CH1_STUDY_WAKE: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_STUDY_FREE_INVESTIGATION: {"track_id": "plain_happiness", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_PUZZLE: {"track_id": "thinking_introspection_2", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_MURDER_REQUEST: {"track_id": "truth", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_CRIME_SCENE: {"track_id": "truth", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_INTRO_HALL: {"track_id": "spooky_tension", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_FIRST_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_INITIAL_REASONING: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_PRIVATE_CHAT: {"track_id": "what_is_truth", "fade_seconds": 2.0},
	FlowIds.STEP_CH1_SECOND_SEARCH: {"track_id": "what_is_truth", "fade_seconds": 2.0},
}

const FREE_INTERACTION_TIMELINES: Dictionary = {
	FlowIds.CHAPTER_CH1: {
		"butler": "1_3_butler",
		"zhou": "1_3_zhou",
		"mu": "1_3_mu",
		"lin": "1_3_lin",
		"wu": "1_3_wu",
		"zhong": "1_3_zhong",
	},
}

const INITIAL_SEARCH_REQUIRED_CLUES: Array[String] = [
	"1_lin_1",
	"1_lin_2",
	"1_lin_3",
	# "1_lin_4",
	"1_lin_5",
	# "1_lin_6",
	"1_lin_7",
	"1_mei_1",
	"1_mei_2",
	"1_mu_1",
	"1_wu_1",
	"1_zhong_1",
	"1_zhou_1",
	"1_zhou_2",
	"1_dining_1",
	"1_dining_2",
	"1_hall_1",
	"1_study_3",
	"1_study_4",
	"1_study_5",
	"1_study_6",
]

const BASE_NPC_LOCATIONS_BY_STEP: Dictionary = {
	FlowIds.STEP_CH1_INTRO_HALL: {
		"butler": {"room_id": FlowIds.ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": FlowIds.ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhong"},
	},
	FlowIds.STEP_CH1_FIRST_SEARCH: {
		"butler": {"room_id": FlowIds.ROOM_FLOOR2, "spawn": "Butler"},
		"zhou": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": FlowIds.ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhong"},
	},
	FlowIds.STEP_CH1_INITIAL_REASONING: {
		"butler": {"room_id": FlowIds.ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": FlowIds.ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhong"},
	},
	FlowIds.STEP_CH1_PRIVATE_CHAT: {
		"butler": {"room_id": FlowIds.ROOM_HALL, "spawn": "Butler"},
		"zhou": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhou"},
		"mu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Mu"},
		"lin": {"room_id": FlowIds.ROOM_HALL, "spawn": "Lin"},
		"wu": {"room_id": FlowIds.ROOM_HALL, "spawn": "Wu"},
		"zhong": {"room_id": FlowIds.ROOM_HALL, "spawn": "Zhong"},
	},
	FlowIds.STEP_CH1_SECOND_SEARCH: {
	},
	FlowIds.STEP_CH1_STUDY_WAKE: {
		"butler": {"room_id": FlowIds.ROOM_CH1_STUDY, "spawn": "Butler"},
	},
	FlowIds.STEP_CH1_CRIME_SCENE: {
		"butler": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Butler"},
		"zhou": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Zhou"},
		"mu": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Mu"},
		"lin": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Lin"},
		"wu": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Wu"},
		"zhong": {"room_id": FlowIds.ROOM_CH1_CRIME_SCENE, "spawn": "Zhong"},
	},
}
