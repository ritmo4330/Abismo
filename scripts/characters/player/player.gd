extends CharacterBody2D
class_name Player

# 可在编辑器调整的参数
#@export var move_speed: float = 400.0
# 去Walk节点调整

# 玩家物理与动作向的本地状态（因为玩家节点已常驻，不再需要依赖外部单例在切换地图时来回存取）
var player_direction: Vector2 = Vector2.DOWN
