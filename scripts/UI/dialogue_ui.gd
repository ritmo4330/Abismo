extends CanvasLayer # 如果你包了一层 CanvasLayer，这里就挂在 CanvasLayer 上（对应 extends CanvasLayer）

@onready var npc_name_label: Label = $Background/NPCName
@onready var dialogue_label: RichTextLabel = $Background/Dialogue
# 如果你听从建议把头像改成了 TextureRect 叫 Avatar，这里就是：
@onready var avatar_rect: TextureRect = $Background/Avatar


func _ready() -> void:
	# 游戏运行初始时，隐藏对话框
	hide()

# 提供给 NPC 调用的接口：显示一条对话
func show_dialogue(npc_name: String, text: String, avatar_texture: Texture2D = null) -> void:
	npc_name_label.text = npc_name
	dialogue_label.text = text
	
	if avatar_texture:
		avatar_rect.texture = avatar_texture
		
	# 显示对话界面
	show()

# 对话结束时隐藏自己
func hide_dialogue() -> void:
	hide()
	dialogue_label.text = ""
