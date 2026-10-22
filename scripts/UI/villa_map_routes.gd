extends RefCounted

# Build the atlas from actual scene exits. Plot-signal doors are deliberately
# excluded: the map must never bypass a butler conversation or a chapter gate.
const ROOM_IDS := ["hall", "floor2", "zou_lang", "can_ting", "flower_sea", "hui_ke_ting", "shu_fang", "room_lin_jiu", "room_mu_zhi", "room_zhou_chong_an", "room_wu_ting_xiang", "room_zhong_qi", "room_meta"]
static var _graph: Dictionary = {}

static func canonical(id: String) -> String:
	return {"ch1_study": "shu_fang", "ch1_crime_scene_lin_room": "room_lin_jiu"}.get(id, id)

static func _resolve(path: String) -> String:
	return ResourceUID.get_id_path(ResourceUID.text_to_id(path)) if path.begins_with("uid://") else path

static func graph() -> Dictionary:
	if not _graph.is_empty(): return _graph
	for id: String in ROOM_IDS:
		var path := "res://scenes/rooms/%s.tscn" % id
		var packed: PackedScene = load(path)
		var edges: Array[Dictionary] = []
		if packed == null: continue
		var state: SceneState = packed.get_state()
		for index: int in state.get_node_count():
			var props: Dictionary = {}
			for property: int in state.get_node_property_count(index):
				props[String(state.get_node_property_name(index, property))] = state.get_node_property_value(index, property)
			var target := _resolve(String(props.get("target_scene_path", "")))
			var destination := target.get_file().get_basename()
			if not ROOM_IDS.has(destination) or destination == id: continue
			if not String(props.get("flow_signal_name", "")).is_empty(): continue
			edges.append({"id": destination, "path": target, "spawn": String(props.get("target_spawn_point", "InitialSpawn")), "flag": String(props.get("required_flag", ""))})
		_graph[id] = edges
	return _graph

static func reachable(origin: String) -> Dictionary:
	origin = canonical(origin)
	var routes: Dictionary = {}
	if not ROOM_IDS.has(origin): return routes
	var queue: Array[String] = [origin]
	var visited: Dictionary = {origin: []}
	while not queue.is_empty():
		var id: String = queue.pop_front()
		for edge: Dictionary in graph().get(id, []):
			if edge.id == "flower_sea" and not preload("res://scripts/clues/dining_backdoor_rules.gd").can_enter(): continue
			if not edge.flag.is_empty() and not DataManager.has_flag(edge.flag): continue
			if visited.has(edge.id): continue
			var route: Array = visited[id].duplicate()
			route.append(edge)
			visited[edge.id] = route
			queue.append(edge.id)
			var destination: Dictionary = edge.duplicate()
			destination["route"] = route
			routes[edge.id] = destination
	return routes

static func travel(destination: String) -> bool:
	if not FlowManager.is_free_investigation_active(): return false
	if FlowManager.is_current_room_exit_blocked(): return false
	var room: Node = SceneManager.current_room
	if not is_instance_valid(room): return false
	var options: Dictionary = reachable(String(room.get("room_id")))
	if not options.has(destination): return false
	var selected: Dictionary = options[destination]
	return FlowManager.request_scene(selected.path, selected.spawn)

