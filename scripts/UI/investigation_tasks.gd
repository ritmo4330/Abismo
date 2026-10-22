extends RefCounted

const FIRST := ["1_lin_1", "1_lin_2", "1_lin_3", "1_lin_5", "1_lin_6", "1_lin_6_key", "1_mei_1", "1_mei_2", "1_mu_1", "1_wu_1", "1_zhong_1", "1_zhou_1", "1_zhou_2"]
const SECOND := ["1_zhongyue_1", "1_zhongyue_2", "1_zhongyue_3"]
const THIRD := ["2_missing_body", "1_lin_7", "2_lin_1", "2_mu_1", "2_mu_2", "2_mu_3", "2_zhou_1", "2_zhou_2", "2_zhou_3", "2_lin_2", "2_lin_3", "2_lin_4", "2_wu_1", "2_wu_2", "2_zhong_1", "2_zhong_2", "2_mei_1", "2_mei_2"]

static func current() -> Dictionary:
	var step: String = FlowManager.get_current_step_id()
	var task := {"title": "当前目标", "body": "继续剧情", "found": 0, "total": 0}
	match step:
		"ch1_1_study_free_investigation":
			task = _collection("午夜凶铃", "调查书房", ["1_study_1", "1_study_2", "1_study_3", "1_study_4", "1_study_5"])
		"ch1_1_puzzle", "ch1_5_initial_reasoning", "ch2_1_second_reasoning", "ch2_4_third_reasoning":
			task = {"title": "推理", "body": "完成推理", "found": 0, "total": 0}
		"ch1_3_intro_hall":
			var completed := 0
			for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
				var complete := true
				for index: int in range(1, 4):
					complete = complete and bool(FlowManager.get_dialogic_var("Ch1.NPCIntro.%s.Selected%d" % [npc, index], false))
				completed += int(complete)
			task = {"title": "初来乍到", "body": "与管家交谈" if completed == 5 else "了解五位客人", "found": completed, "total": 5}
		"ch1_4_first_search":
			task = _collection("初显身手", "调查二楼", FIRST)
			if task.found == task.total: task.body = "与二楼的管家交谈"
		"ch1_6_private_chat":
			task = _private_task("悄悄话", "Ch1.PrivateChat")
			if bool(FlowManager.get_dialogic_var("Ch1.PrivateChat.Zhong.Asked.Lighthouse", false)):
				task.body = "与管家交谈"
				task.total = 0
		"ch1_7_second_search":
			task = _collection("再展身手", "调查钟岳研究所", SECOND)
			if task.found == task.total: task.body = "离开调查现场"
		"ch2_2_second_private_chat":
			task = _private_task("悄悄悄话", "Ch2.SecondPrivate")
		"ch2_3_third_search":
			task = _collection("大显身手", "分别调查别墅与潜意识房间；可找管家结束本轮", THIRD)
		"ch2_5_third_private_chat":
			task = _private_task("悄悄悄悄话", "Ch2.ThirdPrivate")
		"ch2_6_memory_fragments":
			task.title = "场景复现"
			task.body = "复现记忆碎片"
		"ch3_4_route":
			task.title = "超越"
			task.body = "完成最终推理"
	return task

static func _collection(title: String, body: String, ids: Array) -> Dictionary:
	var count := 0
	for id: String in ids:
		count += int(DataManager.has_clue(id))
	return {"title": title, "body": body, "found": count, "total": ids.size()}

static func _private_task(title: String, prefix: String) -> Dictionary:
	var count := 0
	for npc: String in ["Mu", "Zhou", "Lin", "Wu", "Zhong"]:
		count += int(bool(FlowManager.get_dialogic_var(prefix + "." + npc + ".Finished", false)))
	return {"title": title, "body": "与管家交谈" if count == 5 else "与众人私下交谈", "found": count, "total": 5}

