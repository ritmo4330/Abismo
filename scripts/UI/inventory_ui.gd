extends CanvasLayer

@export var slot_size: int = 48 # ▲新暴露的变量：可在右侧面板随时调节格子大小

# 如果你更换了节点(比如TextureRect)，由于层级可能变化，可以直接导出变量拖拽，防止节点找不到
@export var grid_container: GridContainer 

var slot_nodes: Array = []
var max_slots: int = 20

func _ready():
	# 初始时隐藏背包 UI
	hide()
	
	# 如果忘了通过检查器连接节点，这里仍做一个备用的防御寻找
	if not grid_container:
		grid_container = find_child("GridContainer", true)
	
	# 关键：设置背包 UI 在游戏暂停时依然可以接收输入事件
	#（否则一旦游戏暂停，按键就不起作用，背包永远关不掉了）
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# 从全局单例获取最大槽位数
	if PlayerState.get("max_slots") != null:
		max_slots = PlayerState.max_slots
		
	# 初始化空的格子 UI
	_init_slots()

func _input(event):
	# 监听键盘事件，这里以按 'B' 键开关背包为例
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_B:
			visible = not visible
			
			if visible:
				update_ui()
				# 打开背包时，暂停游戏
				get_tree().paused = true
			else:
				# 关闭背包时，恢复游戏
				get_tree().paused = false

# 生成空的插槽框
func _init_slots():
	for i in range(max_slots):
		var slot_panel = Panel.new()
		# 使用暴露的变量统一设定格子大小
		slot_panel.custom_minimum_size = Vector2(slot_size, slot_size)
		
		# 添加图片节点用于显示图标
		var icon_rect = TextureRect.new()
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		# 设置拉伸模式，保证图标比例不变且居中
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		slot_panel.add_child(icon_rect)
		
		# 注意：Godot 4 中，必须先 add_child 再设置 anchor 才有效
		icon_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
		
		# 添加文字节点用于显示数量 (堆叠数)
		var amount_label = Label.new()
		# 设置文字靠右下对齐
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		amount_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		
		# ================= 缩放逻辑核心 =================
		# 根据 slot_size 动态计算字体大小（最小不低于8号字，以防看不清）
		var dynamic_font_size = max(8, int(slot_size * 0.35))
		
		# 设置字体大小和描边方便看清
		amount_label.add_theme_font_size_override("font_size", dynamic_font_size)
		amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
		# 描边粗细也成比例缩放
		amount_label.add_theme_constant_override("outline_size", max(2, int(slot_size * 0.08)))
		
		slot_panel.add_child(amount_label)
		
		# 先 add_child 再设置 anchor 到右下角
		amount_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		
		# 相对边距自适应：高度给格子的60%，宽度给整个格子，留出一点点比例内边距(padding)
		var padding = max(1, int(slot_size * 0.05))
		amount_label.offset_left = -slot_size
		amount_label.offset_top = -slot_size * 0.6
		amount_label.offset_right = -padding
		amount_label.offset_bottom = -padding
		
		slot_nodes.append(slot_panel)
		grid_container.add_child(slot_panel)

# 根据 PlayerState 里的数据刷新背包
func update_ui():
	var current_inventory = PlayerState.inventory
	var items = current_inventory.values() # 因为 inventory 现在是字典，所以提取它所有的值作为数组
	
	for i in range(max_slots):
		var slot_panel = slot_nodes[i]
		var icon_rect = slot_panel.get_child(0) as TextureRect
		var amount_label = slot_panel.get_child(1) as Label
		
		if i < items.size():
			# 如果该位置有物品，就更新UI图案和数量
			var item_dict = items[i]
			var item_data = item_dict["item"]
			var amount = item_dict["amount"]
			
			icon_rect.texture = item_data.icon
			if amount > 1:
				amount_label.text = str(amount)
			else:
				amount_label.text = "1" # 只有一个时通常不显示数字
		
		else:
			# 此格为空，清理显示
			icon_rect.texture = null
			amount_label.text = ""
