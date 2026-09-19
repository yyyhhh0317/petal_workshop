class_name ComboResult
extends RefCounted
## 组合计算结果：基础价值、总倍率、最终价值与命中的修正说明。

var base_value: int = 0
var multiplier: float = 1.0
var final_value: int = 0
var modifiers: Array[String] = []


func _init(p_base: int = 0, p_multiplier: float = 1.0, p_modifiers: Array[String] = []) -> void:
	base_value = p_base
	multiplier = p_multiplier
	final_value = int(round(p_base * p_multiplier))
	modifiers = p_modifiers
