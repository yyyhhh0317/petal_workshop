# 🌸 花间工坊（Petal Workshop）—— 花店 Roguelite 策略经营游戏

**项目名**：Petal Workshop（英文）/ 花间工坊（中文，原代号 Bloom & Bust）
**引擎**：Godot 4.7.2（GDScript，GL Compatibility 渲染管线）
**目标平台**：Steam（Windows / macOS / Linux）
**项目状态**：✅ M2 Roguelite 系统完成（v0.4）：元进度闭环 + 债务周目目标 + 讨价还价 + 每日挑战

> 一款以「买花 → 组合花束 → 展示 → 营业结算」为核心循环的花店经营 Roguelite。
> 花材搭配会增值或贬值；每日随机事件打破固定最优解；每一局失败都能积累元进度。
> 目标体验：**再搭配一束就睡觉**——可计算、可验证、一局接一局的策略乐趣。

## 核心循环

```
[元进度中心] → [开始新一周目] → [每日循环 × N 天]
    ↑                                    │
    │                              ┌─────┴─────┐
    │                              │ ① 买花阶段 │
    │                              │ ② 组合阶段 │
    │                              │ ③ 展示阶段 │
    │                              │ ④ 营业结算 │
    │                              └─────┬─────┘
    │                                    │
    └──── [结算 / 失败] ←── [达成目标？] ──┘
```

## 快速开始

### 引擎位置（本机）

- 图形版：`C:\Users\17801\AppData\Local\Programs\Godot\godot.exe`
- 控制台版（命令行 / 无头验证用）：`C:\Users\17801\AppData\Local\Programs\Godot\godot_console.exe`

打开项目（编辑器）：`godot.exe --path D:\yyy\petal_workshop`

### 运行游戏（M1 核心原型）

```powershell
& "C:\Users\17801\AppData\Local\Programs\Godot\godot.exe" --path "D:\yyy\petal_workshop"
```

主菜单可选「开始新周目」（随机种子）或「每日挑战」（日期固定种子）：**买花 → 组合花束放入展示位（橱窗位 ×1.5）→ 开始营业 → 结算**，目标 10 天内还清 600 元债务；「工坊手册」可浏览图鉴、查看花材解锁进度，并消费技能点购买永久升级。

### 骨架验证（命令行）

```powershell
$godot = "$env:LOCALAPPDATA\Programs\Godot\godot_console.exe"

# 1. 导入项目资源（生成 .godot 缓存与脚本 UID）
& $godot --headless --path "D:\yyy\petal_workshop" --import

# 2. 跑冒烟测试（数据 → 组合 → 种子 → 经济 → 整日循环 → 元进度 → 债务目标 → 耐心阈值）
& $godot --headless --path "D:\yyy\petal_workshop" "res://tests/smoke_test.tscn"

# 3. 批量自动对局（200 局贪心 bot 平衡验证）
& $godot --headless --path "D:\yyy\petal_workshop" "res://tests/simulate.tscn"
```

输出末尾出现 `[smoke] 全部通过 ✔` 即骨架正常。

## 文档导航

| 文档 | 内容 |
|------|------|
| [docs/01-开发计划.md](docs/01-开发计划.md) | 里程碑、任务分解、验收标准、开发流程规范 |
| [docs/02-游戏设计说明.md](docs/02-游戏设计说明.md) | GDD：组合系统规格、Roguelite 结构、元进度、内容与数值规格 |
| [docs/03-技术架构.md](docs/03-技术架构.md) | 架构原则、系统模块、数据流、编码规范、测试策略、Steam 集成 |

## 目录结构

```
D:\yyy\petal_workshop\
├── project.godot              # Godot 项目配置（Autoload、显示、渲染）
├── icon.svg                   # 项目图标（占位花朵）
├── autoload/                  # 全局单例：EventBus / SaveSystem / MetaManager / RunManager
├── scripts/core/              # 核心系统：组合引擎、经济、事件、顾客、种子、数据模型
├── data/                      # 数据驱动资源（.tres）
│   ├── flowers/               #   花材定义（骨架含 4 种示例）
│   ├── combos/                #   组合规则（骨架含 3 条示例）
│   └── events/                #   每日事件模板（骨架含 1 个示例）
├── scenes/                    # 场景：main_menu（主菜单）/ shop（每日循环 UI）/ meta_hub（工坊手册）
├── tests/                     # 冒烟测试 + 批量对局平衡工具
├── assets/                    # sprites / audio / fonts（占位）
├── steam/                     # Steam 集成（阶段四引入 GodotSteam）
└── docs/                      # 开发文档
```

## 已确认决策（v0.2）

| 决策项 | 结论 |
|--------|------|
| 引擎版本 | 锁定 **Godot 4.7.2**（本机已安装并验证） |
| 脚本语言 | GDScript 为主，C# 仅作性能敏感模块备选 |
| 本轮交付 | 骨架 + M1 原型 + **M2 Roguelite 系统**（v0.4）：元进度 / 债务目标 / 讨价还价 / 每日挑战 / 平衡工具 |
| 版本控制 | Git 仓库，文档与骨架已提交为初始 commit |
| Steam 集成 | 阶段四引入 GodotSteam 4.22（官方确认兼容 Godot 4.7.2） |

## 灵感来源与设计演进

- `ideas/idea1.md`：原始创意（买花→组合→营业循环）与市场分析
- `ideas/idea2.md`：Roguelite 化改造思路（周目结构、元进度、每日挑战、组合深度）
