extends Resource
class_name ItemData

@export var id: String = ""            # 物品唯一ID
@export var name: String = "未命名物品"  # 用于显示的名称
@export var icon: Texture2D            # UI显示的图标
@export var max_stack: int = 99        # 最大堆叠数量
@export var description: String = ""   # 物品描述
