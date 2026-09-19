class_name FlowerData
extends Resource
## 花材数据模型：每种花对应一个 .tres 资源文件。

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""          # 花语 / 背景故事
@export var base_value: int = 0               # 出售基础价值
@export var cost: int = 0                     # 进货成本
@export var color_tags: Array[String] = []    # ["red", "warm", ...]
@export var category: String = ""             # "rose", "lily", ...
@export_range(1, 5) var rarity: int = 1
@export var icon: Texture2D
@export var unlock_condition: String = "always"
