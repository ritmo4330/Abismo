extends CharacterBody2D
class_name Player

# 可在编辑器调整的参数
@export var move_speed: float = 200.0
# 出生点名称（与场景内 Marker2D 对应）
var spawn_point_name: String = "door_spawn"

func _ready():
	# 场景加载后自动还原玩家状态
	load_player_state()

func _physics_process(delta):
	# 基础上下左右移动
	var input_dir = Input.get_vector("left", "right", "up", "down")
	velocity = input_dir.normalized() * move_speed  # normalized 防止斜向加速
	move_and_slide()

# 从全局单例还原玩家状态
func load_player_state():
	# 还原速度、血量等属性
	move_speed = PlayerState.move_speed
	# PlayerState.hp  # 如需还原血量可在这里赋值
	
	# 优先用场景内出生点，无则用全局保存的位置
	var spawn_point = get_parent().get_node_or_null(spawn_point_name)
	if spawn_point:
		global_position = spawn_point.global_position
	elif PlayerState.global_position != Vector2.ZERO:
		global_position = PlayerState.global_position

# 供外部调用：手动保存玩家状态（门触发时会自动调用）
func save_current_state():
	PlayerState.global_position = global_position
	PlayerState.move_speed = move_speed
	# PlayerState.hp = self.hp  # 如需保存血量可在这里赋值
