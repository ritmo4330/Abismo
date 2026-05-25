# Demo 开发计划

本文档以 `demo流程.md` 为准，目标是在不拆除既有第一章长流程的前提下，新增一条 demo 专用启动链路。旧版 `游戏流程.md` 中已经开发的“大厅自由询问、第一次搜证、最初推理、私聊、第二轮搜证”等内容暂不进入 demo，只保留资源和系统能力供复用。

## 1. Demo 范围

### 1.1 目标游玩内容

Demo 从新游戏开始，到林玖房间内展示尸体 CG 后黑屏结束，覆盖以下段落：

1. `0.1 为入梦的人类命名`
   - 选择主角性别。
   - 输入主角姓名，写入 `PlayerName`。
   - 旁白确认后进入故事。

2. `0.2 谜语人环节`
   - 黑屏旁白讲述“灯塔水母”寓言。
   - 穿插三段雪地可操作场景：火堆醒来、暴风雪前行、抵达别墅大门。
   - 进入山庄大厅，梅塔登场，触发不属于主角的战争记忆。
   - 主角昏倒，黑屏旁白收束，显示“异数”Logo。

3. `1.1 入局`
   - 切到书房，管家与主角对话。
   - 主角可在书房内自由调查。
   - 调查完毕后坐到椅子上，阅读推理题合集。
   - 展示谜题、挑战读者、推理过程，记录对应疑点。
   - 谜题结束后，管家告知梅塔被杀，请求主角参与调查。

4. `1.2 案发现场`
   - 切换到林玖房间，五名嫌疑人已在场。
   - 依次展示五名角色立绘和短记忆闪回。
   - 主角被钟歧拉住，看到衣柜内尸体。
   - 展示尸体 CG，钟声音效，黑屏，demo 结束。

### 1.2 明确不进入 demo 的旧流程

以下既有内容本次不接入 demo 主线：

- 大厅自由询问五名嫌疑人。
- 第一次搜证与尸体消失。
- 最初推理、多角色口供收录。
- 最初私聊。
- 第二轮搜证与地下研究所。
- 现有 `1_1_*` 至 `1_5_*` 旧章节流程的自动推进。

这些内容不删除、不回退，只通过 demo 专用入口绕开。

## 2. 当前已实现能力盘点

### 2.1 可直接复用

- Godot 4.6.1 + Dialogic 2 对话系统。
- `GameManager`：主菜单、游戏中、暂停、对话状态管理。
- `SceneManager`：房间切换、玩家常驻、淡入淡出、出生点定位。
- `DialogueManager`：统一启动 Dialogic timeline，处理对话暂停和结束回调。
- `FlowManager`：可处理 Dialogic 信号、推进流程、自动切场景和自动播放 timeline。
- `Interactable` + 玩家 `InteractionArea`：靠近对象显示 F 键提示并交互。
- `NpcDialogue`：NPC 交互后请求对应 timeline。
- `ClueItem` + `CluePlacementManager`：线索资源、场景调查、重复调查、线索详情。
- `DataManager`：线索、疑点、world_flags、运行时状态注册。
- `CluePanel` / `SuspicionPanel`：线索手册与推理手册。
- 已有室内场景：大厅、书房、林玖房间、二楼、走廊等。
- 已有角色资源：管家、周崇安、穆执、林玖、乌停湘、钟歧等 Dialogic 角色文件和部分立绘资源。

### 2.2 主要缺口

- 游戏入口仍从 `hall.tscn` 开始，不符合 demo 从命名/序章开始的流程。
- 没有 demo 专用流程节点和信号，现有 `FlowManager` 默认进入旧第一章大厅流程。
- 没有雪地序章场景、火堆交互、暴风雪推进、别墅外大门场景。
- 没有统一 BGM/SFX 播放管理；`调律`、`冬之旋律`、`暗雾谎言`、钟声、敲门声等音频资源也未确认存在。
- 没有全屏黑屏旁白/Logo/CG 演出组件的明确封装。
- 没有任务系统；demo 中“获得任务：寻找温暖”需要最小提示方案或任务 UI。
- 书房谜题需要新的全屏阅读/谜题交互方案。
- demo 结尾尸体 CG、异数 Logo、雪地与门口美术资源需要补齐或临时占位。

## 3. 技术路线

### 3.1 总原则

1. 新增 demo 专用入口，不破坏旧流程。
2. 复用现有底层系统：对话、场景切换、交互、线索/疑点记录、暂停。
3. 对 demo 特有演出新增轻量组件，避免把雪地序章硬塞进旧第一章流程。
4. 旧章节资源继续保留，但 demo 只注册和使用 demo flow step。

### 3.2 建议新增命名

建议使用以下命名，避免与旧第一章混淆：

- demo 章节 ID：`demo`
- Dialogic 目录：`assets/dialogues/demo/`
- demo 场景目录：`scenes/demo/`
- demo 线索/疑点目录：
  - `assets/objects/clues/demo/`
  - `assets/objects/suspicions/demo/`
- demo flow step：
  - `demo_0_1_identity`
  - `demo_0_2_prologue_story`
  - `demo_0_2_snow_camp`
  - `demo_0_2_snow_path`
  - `demo_0_2_villa_gate`
  - `demo_0_2_hall_arrival`
  - `demo_1_1_study_wake`
  - `demo_1_1_study_free_investigation`
  - `demo_1_1_puzzle`
  - `demo_1_1_murder_request`
  - `demo_1_2_crime_scene`
  - `demo_end`

## 4. 分阶段开发计划

### Phase A：入口与流程骨架

目标：让“开始游戏”进入 demo，而不是旧大厅流程。

任务：

- 调整 `game_root.gd` 或 `SceneManager.initialize()` 的首场景配置，使 demo 首次加载进入一个空/黑屏演出场景，而不是 `hall.tscn`。
- 扩展 `FlowManager`，加入 demo step 常量、demo 场景路径、demo flow signal。
- 扩展 `DialogueManager.LEGACY_FLOW_SIGNALS` 或统一使用 `flow:` 前缀，让 demo timeline 可以触发流程推进。
- 增加运行时重置入口：开始新游戏时清理 `DataManager.clue_states`、`DataManager.suspicions`、`DataManager.world_flags`，并初始化 demo 变量。
- 保留旧流程入口作为测试入口，避免后续开发旧第一章时被阻断。

涉及文件：

- `scripts/game_root.gd`
- `scripts/flow/flow_manager.gd`
- `scripts/dialogue/dialogue_manager.gd`
- `scripts/data_manager.gd`
- `scripts/UI/main_menu.gd`

验收标准：

- 点击主菜单“开始游戏”后进入 demo 命名/序章。
- 旧 `hall.tscn` 不再作为正式新游戏首场景。
- 现有旧章节 timeline 文件不被删除、不被重写为 demo 内容。

### Phase B：主角命名与黑屏旁白演出

目标：完成 `0.1` 和黑屏寓言叙事的基础体验。

任务：

- 新建 `demo_0_1_identity.dtl`：
  - 使用 Dialogic 选项记录 `PlayerGender`。
  - 使用 Dialogic `text_input` 记录 `PlayerName`。
  - 结束后发出 `flow:demo_start_prologue_story`。
- 新建 `demo_0_2_story.dtl` ，是一个分 label timeline：
  - 黑屏显示灯塔水母寓言文本。
  - 在指定节点发出信号切换到序章场景，以及当切换场景或走到场景特定位置时触发播放相应 label 处的文本。
- 建立黑屏演出场景或演出层：
  - 最小方案：使用一个纯黑 `Control`/`CanvasLayer` 背景，Dialogic 文本框显示旁白。
  - 后续可扩展为无文本框、居中文本的视觉小说演出层。
- 设置开场 BGM `调律` 的播放接口；若音频未到位，先接入接口并用占位资源。

涉及文件：

- `assets/dialogues/demo/demo_0_1_identity.dtl`
- `assets/dialogues/demo/demo_0_2_prologue.dtl`
- `scenes/demo/demo_black_screen.tscn` 或 `scenes/demo/demo_cinematic.tscn`
- `scripts/flow/flow_manager.gd`
- 新增 `scripts/audio/audio_manager.gd`

验收标准：

- 玩家可选择性别、输入姓名。
- 后续台词可显示 `{PlayerName}`。
- 黑屏旁白能按点击推进，并在指定位置切入可操作雪地场景。
- 开场 BGM 接口可用，能在后续场景切换时调用。

### Phase C：雪地序章三段可操作场景

目标：完成图 1、图 2、图 3 的核心交互。

任务：

- 新建三个 demo 场景：
  - `demo_snow_camp.tscn`：石头、火堆、出生点、右侧出口。
  - `demo_snow_path.tscn`：线性雪路、暴风雪触发区、远处光亮。
  - `demo_villa_gate.tscn`：别墅门口、大门交互、进入别墅入口。
- 新建火堆交互对象：
  - 初始燃烧或将熄状态。
  - 暴风雪吹过后熄灭。
  - 玩家靠近按 F，火堆复燃后再次熄灭。
  - 写入 `DataManager.world_flags["demo/find_warmth_started"] = true`。
- 实现最小任务提示：
  - MVP 使用 UI Toast：`获得任务：寻找温暖`；当前尚未实现，需要新增 `scripts/UI/toast_manager.gd`。
  - 任务显示在屏幕右侧偏上三分之一处，持续 3 秒后自动消失。
  - 暂不做完整任务系统，除非后续明确需要。
- 实现暴风雪触发：
  - 进入指定 Area2D 时播放风雪遮罩/屏幕抖动/音效。
  - 图 2 每移动一段距离触发一次。
- 实现别墅大门交互：
  - 按 F 后播放开门文本/音效。
  - 切到大厅到达演出。

涉及文件：

- `scenes/demo/demo_snow_camp.tscn`
- `scenes/demo/demo_snow_path.tscn`
- `scenes/demo/demo_villa_gate.tscn`
- `scripts/objects/interactable/demo_campfire.gd`
- `scripts/UI/toast_manager.gd`
- `scripts/demo/demo_blizzard_trigger.gd`
- `assets/dialogues/demo/demo_0_2_snow_*.dtl`

验收标准：

- 玩家能在雪地移动、与火堆和大门交互。
- 火堆交互后才能合理推进到“寻找温暖”。
- 三段雪地场景之间能稳定切换。
- 走到别墅门口并交互后进入山庄。

### Phase D：山庄门口到昏倒演出

目标：完成进入大厅、梅塔初见、战争记忆、昏倒、Logo 的线性演出。

当前实现：

- 已将 `demo_villa_gate.tscn` 的大门交互接到正式 `demo_0_2_hall_arrival` 时间线。
- 已新增梅塔 Dialogic 角色占位资源 `assets/characters/npcs/meta.dch`，正式立绘到位后只需替换 portrait。
- 已新增大厅到达、梅塔记忆、书房醒来占位时间线，并注册到 `project.godot`。
- 已新增 `scenes/demo/demo_logo.tscn`，大厅演出结束后显示“异数”Logo，并自动切到 `shu_fang.tscn` 的书房醒来时间线。
- 已扩展 `FlowManager` 的 demo step/action，Phase D 流程不会进入旧大厅自由调查。

任务：

- 复用 `hall.tscn`，新增 demo 专用 step 下的 NPC 布置：
  - 梅塔需要角色资源，如不存在需新增 Dialogic character。
  - 管家可复用现有资源。
- 新建 `demo_0_2_hall_arrival.dtl`：
  - 主角敲门。
  - 管家开门。
  - 梅塔发现主角并吩咐管家。
  - 触发黑屏战争记忆。
  - 主角昏倒。
- 新建 Logo 演出：
  - 黑屏旁白收束。
  - 切 BGM 或停止 BGM。
  - 显示“异数”Logo。
  - 进入书房醒来。

涉及文件：

- `assets/dialogues/demo/demo_0_2_hall_arrival.dtl`
- `assets/dialogues/demo/demo_0_2_memory_meta.dtl`
- `assets/characters/npcs/meta.dch` 或对应角色资源
- `scenes/demo/demo_logo.tscn` 或演出层资源

验收标准：

- 从别墅门口进入后，不进入旧大厅自由调查。
- 演出结束自动切到书房。
- 梅塔记忆闪回不会误触发旧第一章流程。

### Phase E：书房醒来、调查与谜题

目标：完成 `1.1 入局`。

当前实现：

- 已新增 `scenes/demo/demo_study.tscn`，从原书房继承并使用 demo 专用 `room_id`，不会污染旧第二轮搜证书房。
- 已将 Logo 后续流程改为进入 demo 书房，并播放正式 `demo_1_1_study_wake`。
- 已新增书房三处调查点与椅子交互；未完成书房必要调查时，椅子不会进入谜题。
- 已新增谜题正文线索、挑战读者子线索、整理后的谜题线索、结论线索，以及 6 个 demo 疑点资源。
- 已扩展推理手册，线索槽位数会根据当前疑点 `required_clue_ids` 动态生成，不再固定 3 个。
- 已接入疑点解决后的结论线索、解锁新疑点、结论旁白 timeline；最终结论会触发命案请求时间线。

任务：

- 复用或复制 `shu_fang.tscn` 为 demo 书房场景：
  - 推荐复制为 `scenes/demo/demo_study.tscn`，避免影响旧流程第二轮搜证中复用的书房。
- 新建 `demo_1_1_study_wake.dtl`：
  - 管家解释主角倒在门口。
  - 询问姓名时直接使用 `{PlayerName}`，不重复输入。
  - 管家离开，开放书房调查。
- 书房自由调查：
  - 配置各交互点，参考已有的书房线索文件。
  - 调查项用 `world_flags` 记录，达到条件后高亮/开放椅子。
- 新建谜题展示：
  - 将谜题创建为线索资源，并按照线索的方式展示谜题正文。
  - 将挑战读者创建为线索资源，作为谜题的子线索。
  - `demo_1_1_puzzle_reasoning.dtl`：利用对话展示推理过程并记录疑点和线索；记录疑点的信息不展示到对话中，而是作为右上角的toast弹出，格式为“已记录疑点【xxxxx】”；记录线索的信息同理
- 新增 demo 疑点资源：
  - `demo_suspicion_impossible_crime`：不可能犯罪。
  - `demo_suspicion_x_disability`：X 的残疾。
  - `demo_suspicion_crime_info`：案发现场的基本信息。
  - `demo_suspicion_strange_description`：奇怪的描述。
  - `demo_suspicion_nonexistent_service`：不存在的服务。
  - `demo_suspicion_hidden_chars`：被隐藏的人物。
- 谜题解决方式：
  - 采用现有的疑点解决方式，玩家需要打开推理手册查看疑点详情，并选择相应的线索组合进行推理
  - 疑点解决需要的线索数目不定，当前推理手册选择线索固定为3，需要修改成当前疑点解决需要的线索的数目
  - 某疑点解决后可能会有结论，应当作为线索被添加到线索栏；也能能解决后得到新的疑点，则相应地添加到疑点栏。
  - 某些疑点要解决可能需要前置疑点解决后的线索。
  - 疑点解决请看demo流程文档中的image。疑点解决后会有旁白，请创建相应的`demo_1_1_conclusion_*.dtl`并按逻辑正常播放。

涉及文件：

- `scenes/demo/demo_study.tscn`
- `assets/dialogues/demo/demo_1_1_study_wake.dtl`
- `assets/dialogues/demo/demo_1_1_puzzle_*.dtl`
- `assets/dialogues/demo/demo_1_1_conclusion_*.dtl`
- `assets/objects/suspicions/demo/*.tres`
- `scenes\UI\suspicion_panel.tscn` 等疑点推理系统相关文件（需要支持动态线索数目的推理选项）

验收标准：

- 管家离开后玩家能在书房移动并调查。
- 未完成必要调查时不能直接进入谜题。
- 谜题文本、线索文本、疑点文本可完整阅读。
- 疑点可正常被解决并添加相应的结论线索或疑点。
- 谜题结束后触发管家急促敲门和命案请求。

### Phase F：命案请求与抉择

目标：完成从谜题结束到前往案发现场的衔接。

当前实现：

- 已补全 `demo_1_1_murder_request.dtl` 的抉择 1：
  - 选择“同意”后继续流程。
  - 选择“不同意”后记录 `demo/murder_request_refused`，显示“有人记住了你的选择”，随后再次要求玩家同意。
- 已新增 `flow:demo_murder_request_accepted`，由 `FlowManager` 切换到 demo 专用林玖房间案发现场。
- 已新增 `scenes/demo/demo_crime_scene_lin_room.tscn`，继承原林玖房间并禁用旧门，使用 `demo_crime_scene_lin_room` 房间 ID，配置管家与五名嫌疑人站位。
- 已新增 `demo_1_2_crime_scene.dtl` 的最小开场承接文本；完整案发现场演出留到 Phase G 扩写。

任务：

- 新建 `demo_1_1_murder_request.dtl`：
  - 管家急忙进入书房，告知梅塔被杀。
  - 说明主角无嫌疑，请求参与调查。
  - 展示“暴风雪山庄吗……”内心旁白。
  - 提供抉择 1。

涉及文件：

- `assets/dialogues/demo/demo_1_1_murder_request.dtl`
- `scripts/flow/flow_manager.gd`

验收标准：

- 谜题结束后自动触发命案请求。
- 玩家确认后切换到林玖房间案发现场。

### Phase G：案发现场与 demo 结尾

目标：完成 `1.2 案发现场` 并在尸体 CG 后结束 demo。

当前实现：

- 已扩写 `demo_1_2_crime_scene.dtl`：
  - 管家带主角进入案发现场。
  - 依次展示周崇安、穆执、林玖、乌停湘、钟歧。
  - 通过 Dialogic `[background]` 事件和 demo 专用透明色背景场景控制黑屏记忆。
  - 主角被钟歧拉住后看到衣柜内尸体，并发出 `flow:demo_crime_scene_finished`。
- 各角色记忆文本已内联在主时间线中，不再保留独立记忆 DTL 文件。
- 已移除案发现场自定义黑屏 overlay，避免外部 `CanvasLayer` 遮挡 Dialogic 对话层。
- 已新增 `scenes/demo/demo_end.tscn` 与 `scripts/demo/demo_end.gd`：
  - 运行时读取 `assets/cg/demo_body_cg.png` 并创建贴图，避免未导入 PNG 导致场景解析失败。
  - 调用 `AudioManager.play_sfx("clock_bell")`。
  - 随后黑屏显示 `Demo End`。
- 已扩展 `AudioManager` 的 `audio:play_sfx:*` 接口，钟声音效路径暂为空，待 Phase H 填资源。

任务：

- 复用或复制 `room_lin_jiu.tscn` 为 demo 案发现场：
  - 推荐复制为 `scenes/demo/demo_crime_scene_lin_room.tscn`。
  - 配置五名嫌疑人站位和管家站位。
  - 衣柜处配置尸体 CG 触发位。
- 新建 `demo_1_2_crime_scene.dtl`：
  - 管家带主角进入案发现场。
  - 描述空气、血腥味、五名嫌疑人。
  - 依次展示周崇安、穆执、林玖、乌停湘、钟歧立绘。
  - 除乌停湘外，每名角色触发一段黑屏记忆闪回。
- 展示尸体 CG：
  - CG 图片资源位于`assets\cg\demo_body_cg.png`，是一个3840*2160的图片。
  - 黑屏。
  - 显示 `Demo End`。

涉及文件：

- `scenes/demo/demo_crime_scene_lin_room.tscn`
- `assets/dialogues/demo/demo_1_2_crime_scene.dtl`
- `assets/cg/demo_body_cg.png`
- `assets/audio/sfx/clock_bell.*`

验收标准：

- 进入案发现场后流程全线性推进，不进入旧搜证。
- 五名角色和对应记忆按 `demo流程.md` 顺序展示。
- 尸体 CG 后 demo 正常结束，不继续旧 `1.2 最初的搜证`。

### Phase H：音频、视觉与体验收尾

目标：让 demo 达到可演示状态。

任务：

- 补齐或占位以下音频：
  - BGM：《调律》《冬之旋律》《暗雾谎言》。
  - SFX：暴风雪、火堆、敲门、开门、钟声、昏倒/冲击。
- 新增轻量 AudioManager：
  - `play_bgm(id, fade)`。
  - `stop_bgm(fade)`。
  - `play_sfx(id)`。
- 补齐视觉：
  - 雪地风雪遮罩。
  - 黑屏旁白转场。
  - 异数 Logo。
  - 尸体 CG。
  - 必要的临时占位图统一标注，避免误以为最终资源。
- 联调暂停、对话、场景切换：
  - 对话中禁止打开手册。
  - 切场景中禁止重复触发交互。
  - demo 结束后 Esc 暂停仍正常。

验收标准：

- Demo 可从主菜单一口气跑到结尾。
- 没有旧流程串入。
- 没有明显卡死、重复触发、对话重入、场景切换重入问题。

## 5. 建议开发顺序

1. 先做 Phase A，确保 demo 入口独立。
2. 做 Phase B 的命名与黑屏旁白，形成最短可运行链路。
3. 做 Phase E 的书房与谜题，因为这是 demo 文本量最大、交互判断最多的段落。
4. 做 Phase G 的案发现场结尾，先用现有室内资源和占位 CG 打通终点。
5. 回头补 Phase C/D 的雪地序章演出。
6. 最后做 Phase H 的音频、风雪、Logo、CG 和体验修正。

这样能尽早拿到一条“主菜单 -> 书房 -> 案发现场 -> 结束”的可跑版本，再逐步把序章雪地演出补完整。

## 6. 资源与内容待确认

以下内容会影响实现质量或工作量，需要在开发前或开发中确认：

- 主角性别是否只写入变量，还是需要影响称谓、头像、行走 sprite。
- 梅塔是否已有正式立绘与 Dialogic 角色资源。
- 乌停湘记忆闪回文本目前为“占位”，是否在 demo 中继续占位。
- 谜题是否需要玩家真实解谜，还是展示推理过程后自动推进。
- 谜题标准答案、错误选项、失败反馈文本。
- 尸体 CG、异数 Logo、雪地场景美术是否已有正式资源。
- 三首 BGM 和关键音效是否已有文件；如果没有，需要先使用占位音频或静音接口。

## 7. 最小可演示版本定义

如果需要优先做一个最短 demo，可按以下范围收缩：

- 必做：
  - 性别选择、姓名输入。
  - 黑屏寓言文字。
  - 书房醒来、书房调查、谜题展示。
  - 管家告知命案。
  - 林玖房间角色介绍、记忆闪回、尸体 CG、黑屏结束。
- 可先简化：
  - 雪地三段场景可先用黑屏旁白 + 一张占位图替代。
  - BGM/SFX 可先接接口，资源到位后替换。
  - 谜题可先做“阅读后继续”，不做完整答题。
  - 任务系统只做 Toast/旁白提示，不做任务手册。

## 8. 回归测试清单

每个阶段完成后至少验证：

- 新游戏能从 demo 起点开始。
- `{PlayerName}` 在后续文本中正确显示。
- 对话结束后玩家移动状态恢复。
- 场景切换期间不会重复触发对话或交互。
- 雪地火堆、大门、书房椅子等关键交互只在正确条件下推进。
- 书房谜题长文本可完整阅读。
- demo 结束后不会进入旧搜证流程。
- 旧第一章测试入口仍能进入原有大厅流程。
- 线索/疑点手册在非对话状态可打开，在对话状态不会打断流程。
