# 🌸 花间工坊（Petal Workshop）—— 花店 Roguelite 策略经营游戏

**项目名**：Petal Workshop（英文）/ 花间工坊（中文，原代号 Bloom & Bust）
**引擎**：Godot 4.7.2（GDScript，GL Compatibility 渲染管线）
**目标平台**：Steam（Windows / macOS / Linux）
**项目状态**：✅ M3 内容填充完成（v0.5）：30 种花材 · 61 条组合规则 · 13 事件 · 11 顾客 · 全位置效果

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

### 引擎要求

Godot **4.7.2**（`godot` / `godot_console` 需在 PATH 中；若本机引擎未加入 PATH，先执行）：

```powershell
$env:Path += ";$env:LOCALAPPDATA\Programs\Godot"
```

### 运行游戏

```powershell
godot --path .
```

主菜单可选「开始新周目」（随机种子）或「每日挑战」（日期固定种子）：**买花 → 组合花束放入展示位（橱窗 ×1.5 / 中央 ≥3支 ×1.15 / 角落 流行×1.4）→ 开始营业 → 结算**，目标 10 天内还清 800 元债务（每日摊位租金 20 元）；「工坊手册」可浏览图鉴（升级后可看未发现组合的线索）、查看花材解锁进度，并消费技能点购买永久升级。

### 骨架验证（命令行）

```powershell
# 1. 导入项目资源（生成 .godot 缓存与脚本 UID）
godot_console --headless --path . --import

# 2. 冒烟测试（成功 = 退出码 0 且输出末尾「全部通过 ✔」）
godot_console --headless --path . res://tests/smoke_test.tscn

# 3. 批量自动对局（3 种 bot 策略分组统计；可用 SIM_RUNS / SIM_DAYS 环境变量调整规模）
godot_console --headless --path . res://tests/simulate.tscn
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
| 本轮交付 | 骨架 + M1/M2/M3 + **评审整改**：DayCycle 拆分 / 数据 schema 校验 / 多策略模拟 / 租金与债务重校（债务 800、租金 20/天） |
| 版本控制 | Git 仓库，文档与骨架已提交为初始 commit |
| Steam 集成 | 阶段四引入 GodotSteam 4.22（官方确认兼容 Godot 4.7.2） |

## 灵感来源与设计演进

- `ideas/idea1.md`：原始创意（买花→组合→营业循环）与市场分析
- `ideas/idea2.md`：Roguelite 化改造思路（周目结构、元进度、每日挑战、组合深度）
