class_name ComboEngine
extends RefCounted
## 组合规则计算引擎（核心策略系统）：
## 基础价值之和 × Π(命中规则倍率) × 位置加成 × 流行加成。

const WINDOW_MULTIPLIER := 1.5
const TREND_MULTIPLIER := 1.2


func calculate_value(flower_ids: Array[String], context: ComboContext = null) -> ComboResult:
	var flowers: Array[FlowerData] = []
	for id in flower_ids:
		var f := FlowerDatabase.get_flower(id)
		if f:
			flowers.append(f)

	var base := 0
	for f in flowers:
		base += f.base_value

	var multiplier := 1.0
	var modifiers: Array[String] = []
	var rule_ids: Array[String] = []
	for rule in _get_matching_rules(flowers):
		multiplier *= rule.value_multiplier
		modifiers.append(rule.display_name if rule.display_name != "" else rule.id)
		rule_ids.append(rule.id)

	if context:
		if context.slot_type == ComboContext.SlotType.WINDOW:
			multiplier *= WINDOW_MULTIPLIER
			modifiers.append("橱窗位加成 x%.1f" % WINDOW_MULTIPLIER)
		if not context.trend_tags.is_empty() and _all_have_any_tag(flowers, context.trend_tags):
			multiplier *= TREND_MULTIPLIER
			modifiers.append("流行趋势加成 x%.1f" % TREND_MULTIPLIER)

	return ComboResult.new(base, multiplier, modifiers, rule_ids)


func _get_matching_rules(flowers: Array[FlowerData]) -> Array[ComboRule]:
	var matched: Array[ComboRule] = []
	for rule in FlowerDatabase.get_combo_rules():
		if rule.matches(flowers):
			matched.append(rule)
	matched.sort_custom(func(a: ComboRule, b: ComboRule) -> bool: return a.priority > b.priority)
	return matched


func _all_have_any_tag(flowers: Array[FlowerData], tags: Array[String]) -> bool:
	if flowers.is_empty():
		return false
	for f in flowers:
		var has := false
		for t in tags:
			if f.color_tags.has(t):
				has = true
				break
		if not has:
			return false
	return true
