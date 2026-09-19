class_name ComboResult
extends RefCounted
## 组合计算结果：基础价值、总倍率、最终价值、命中的修正说明与规则 id。

var base_value: int = 0
var multiplier: float = 1.0
var final_value: int = 0
var modifiers: Array[String] = []
var matched_rule_ids: Array[String] = []


func _init(p_base: int = 0, p_multiplier: float = 1.0, p_modifiers: Array[String] = [], p_rule_ids: Array[String] = []) -> void:
	base_value = p_base
	multiplier = p_multiplier
	final_value = int(round(p_base * p_multiplier))
	modifiers = p_modifiers
	matched_rule_ids = p_rule_ids
