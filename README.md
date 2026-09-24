# 异数（Abismo）

基于 Godot 4 的 2D 像素俯视角推理 AVG。项目以场景探索、Dialogic 对话、线索收集与疑点推理为核心，当前主入口为 `scenes/UI/main_menu.tscn`。

## 前置要求

- Godot 4.6.x（项目配置目标为 4.6；开发文档基线为 4.6.1）
- Git
- Windows 10 或更高版本为主要目标平台

Dialogic 2 与 Godot MCP 插件已包含在 `addons/` 中，无需单独安装。首次打开项目时需等待 Godot 完成资源导入。

## 启动与验证

1. 克隆仓库。
2. 在 Godot 项目管理器中导入根目录下的 `project.godot`。
3. 使用 `F6` 运行当前场景进行局部调试，或使用 `F5` 从主菜单启动完整流程。

提交前建议执行流程与内容配置校验：

```bash
godot --headless --path . --script res://scripts/flow/tools/run_flow_config_validation.gd
```

校验会检查章节流程配置，以及线索、疑点等资源之间的引用。成功时输出 `Flow and content config validation passed.`。

## 目录结构

```text
Abismo/
├── addons/                 # 随仓库提交的第三方/编辑器插件
├── assets/                 # 美术、音频及数据资源
│   ├── characters/         # 角色图片与 Dialogic 角色定义（*.dch）
│   ├── dialogues/          # 按章节组织的 Dialogic 时间线（*.dtl）
│   ├── objects/            # 线索、摆放配置、疑点等数据资源（*.tres）
│   ├── audio/              # 音乐与音效
│   ├── interior/           # 室内场景美术
│   └── UI/                 # UI 图片、字体与样式资源
├── scenes/                 # Godot 场景（*.tscn）
│   ├── characters/         # 玩家与 NPC 预制体
│   ├── objects/            # 可交互物体预制体
│   ├── rooms/              # 通用房间场景
│   ├── UI/                 # 菜单、线索、疑点、暂停等界面
│   └── ch*/                # 章节专用场景
├── scripts/                # GDScript 源码（*.gd）
│   ├── data/               # 内容注册、运行时状态及领域服务
│   ├── flow/               # 章节流程配置、控制器与执行服务
│   ├── objects/            # 交互对象逻辑
│   ├── scenes/             # 房间与场景切换逻辑
│   ├── UI/                 # UI 展示与输入响应
│   └── ch*/                # 章节专用行为
├── docs/                   # 需求、架构及内容配置文档
├── export/                 # 本地导出产物（不提交）
└── project.godot           # 项目、输入映射与 Autoload 配置
```

`.godot/` 是本地导入缓存，不应提交。新增内容应放入对应领域目录；仅某一章节使用的场景或脚本放入相应的 `ch*_.../` 目录，通用实现放入共享目录。

## 代码组织

- `GameManager` 管理游戏状态与暂停；`SceneManager` 管理房间加载和过渡。
- `FlowManager` 驱动章节步骤、场景效果和 NPC 布置；章节配置位于 `scripts/flow/configs/`，章节分支逻辑位于 `scripts/flow/chapters/`。
- `DialogueManager` 是业务代码启动 Dialogic 时间线的统一入口。
- `DataManager` 是线索、疑点、好感度和世界标记的统一读写入口；数据变更后由信号通知 UI。
- `EventBus` 用于跨模块的一对多事件。不要通过跨层级 `get_node("../../...")` 耦合模块。
- 线索、疑点等静态内容使用 `Resource` 配置，运行时状态与显示逻辑分离。

主要 Autoload 定义在 `project.godot` 中，包括 `EventBus`、`DataManager`、`SceneManager`、`GameManager`、`DialogueManager`、`FlowManager`、`CluePlacementManager`、`AudioManager` 和 `ToastManager`。

## 内容放置约定

| 内容 | 放置位置 |
| --- | --- |
| Dialogic 时间线 | `assets/dialogues/<chapter>/` |
| Dialogic 角色 | `assets/characters/` 或 `assets/characters/npcs/` |
| 线索定义 | `assets/objects/clues/<chapter>/` |
| 场景线索摆放 | `assets/objects/clue_placements/<chapter>/` |
| 疑点定义 | `assets/objects/suspicions/<chapter>/` |
| 通用场景/脚本 | `scenes/<domain>/`、`scripts/<domain>/` |
| 章节专用场景/脚本 | `scenes/<chapter>/`、`scripts/<chapter>/` |

线索和疑点 ID 必须全局唯一，资源文件名应与 ID 保持一致。房间内只保留 `ClueSpawnPoints` 挂点；实际线索由 `CluePlacementManager` 根据当前流程动态生成到 `DynamicClues`。

## 开发约定

- 使用 GDScript 2.0，并为变量、参数和返回值显式声明类型。
- 类名和节点名使用 `PascalCase`；变量、函数、文件和目录使用 `snake_case`。
- 可复用自定义类型使用 `class_name` 注册。
- 跨模块的一对一操作调用对应 Autoload；一对多通知通过 `EventBus`。
- 业务数据只能通过 `DataManager` 修改；UI 只负责展示和输入响应。
- 不直接修改 `addons/` 中的第三方插件，除非变更目的就是维护插件。
- 文本文件使用 UTF-8，提交时遵循仓库的 LF 行尾配置。

## 调试与操作

- 移动：`WASD` 或方向键
- 交互：`F`
- 线索界面：`C`
- 疑点界面：`V`
- 暂停/关闭界面：`Esc`
- 推进对话：`Enter`、`Space`、`X` 或鼠标左键

房间场景继承通用房间逻辑后可直接用 `F6` 独立运行；调试章节、步骤、出生点和预置状态可通过房间根节点的 `Debug Standalone` 导出属性配置。

## 进一步阅读

- [开发架构与编码规范](docs/开发文档.md)
- [流程编排设计](docs/流程编排.md)
- [线索配置设计](docs/线索配置.md)
- [Godot 与 Dialogic 使用说明](docs/godot技术文档.md)
- [游戏流程](docs/游戏流程.md)

导出预设保存在 `export_presets.cfg` 中，可通过 Godot 的 **项目 > 导出** 生成 Web 或 Windows 构建；导出结果统一放入 `export/`。
