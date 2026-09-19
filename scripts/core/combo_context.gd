class_name ComboContext
extends RefCounted
## 组合计算上下文：摆放位置、当日流行趋势等影响价值的外部条件。

enum SlotType { NORMAL, WINDOW, CENTER, CORNER }

var slot_type: SlotType = SlotType.NORMAL
var trend_tags: Array[String] = []
var day_number: int = 1
