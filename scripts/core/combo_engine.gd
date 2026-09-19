class_name ComboEngine
extends RefCounted
## 组合规则计算引擎（核心策略系统）：
## 基础价值之和 × Π(命中规则倍率) × 位置加成 × 流行加成。
## 位置效果：橱窗位 ×1.5；中央位 ≥3 支 ×1.15；角落位流行加成 ×1.4（其余 ×1.2）。

const WINDOW_MULTIPLIER := 1.5
const CENTER_MULTIPLIER := 1.15
const CENTER_MIN_FLOWERS := 3
const TREND_MULTIPLIER := 1.2
const CORNER_TREND_MULTIPLIER := 1.4


func calculate_value(flower_ids: Array[String], context: ComboContext = null) -> ComboResult:
	var flowers: Array[FlowerData] = []
	var warnings: Array[String] = []
	for id in flower_ids:
		var f := FlowerDatabase.get_flower(id)
		if f:
			flowers.append(f)
		else:
			warnings.append("未知花材 id：" + id)
			push_warning("ComboEngine: 未知花材 id '%s'（数据缺失或拼写错误）" % id)

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
		match context.slot_type:
			ComboContext.SlotType.WINDOW:
				multiplier *= WINDOW_MULTIPLIER
				modifiers.append("橱窗位加成 x%.1f" % WINDOW_MULTIPLIER)
			ComboContext.SlotType.CENTER:
				if flowers.size() >= CENTER_MIN_FLOWERS:
					multiplier *= CENTER_MULTIPLIER
					modifiers.append("中央展台加成 x%.2f" % CENTER_MULTIPLIER)
			ComboContext.SlotType.CORNER:
				pass
		if not context.trend_tags.is_empty() and _all_have_any_tag(flowers, context.trend_tags):
			var trend_mult := CORNER_TREND_MULTIPLIER if context.slot_type == ComboContext.SlotType.CORNER else TREND_MULTIPLIER
			multiplier *= trend_mult
			modifiers.append("流行趋势加成 x%.1f" % trend_mult)

	return ComboResult.new(base, multiplier, modifiers, rule_ids, warnings)


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
