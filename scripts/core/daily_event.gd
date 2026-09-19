class_name DailyEvent
extends Resource
## 每日事件模板：流行趋势、价格扰动等，以 .tres 定义。

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var weight: int = 10
@export var cost_multiplier: float = 1.0    # 进货成本倍率
@export var value_multiplier: float = 1.0   # 花束价值倍率
@export var affected_tags: Array[String] = []  # 受影响的流行标签
@export var duration_days: int = 1
