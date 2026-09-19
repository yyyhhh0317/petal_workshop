class_name ComboRule
extends Resource
## 组合规则数据模型：规则以 .tres 定义，引擎按优先级匹配、乘法叠加。

enum RuleType { TABOO, LEGENDARY, COLOR_SYNERGY, CATEGORY_SYNERGY, TREND }

@export var id: String = ""
@export var display_name: String = ""
@export var rule_type: RuleType = RuleType.COLOR_SYNERGY
@export var priority: int = 0                 # 越大越先应用
@export var description: String = ""
@export var value_multiplier: float = 1.0
@export var required_ids: Array[String] = []  # 必须全部出现
@export var any_of_ids: Array[String] = []    # 至少出现一种
@export var required_tags: Array[String] = [] # 与 min_matches 配合：标签命中数
@export var required_category: String = ""
@export var min_matches: int = 1
@export var require_shared_tag: bool = false  # 全束共享同一标签（同色系协同）
@export var is_taboo: bool = false


func matches(flowers: Array[FlowerData]) -> bool:
	var ids := {}
	var tags: Array[String] = []
	var cats: Array[String] = []
	for f in flowers:
		ids[f.id] = true
		tags.append_array(f.color_tags)
		cats.append(f.category)

	for rid in required_ids:
		if not ids.has(rid):
			return false

	if not any_of_ids.is_empty():
		var found := false
		for rid in any_of_ids:
			if ids.has(rid):
				found = true
				break
		if not found:
			return false

	if not required_tags.is_empty():
		var match_count := 0
		for t in tags:
			if required_tags.has(t):
				match_count += 1
		if match_count < min_matches:
			return false

	if required_category != "":
		if not cats.has(required_category):
			return false

	if require_shared_tag:
		if not _all_share_a_tag(flowers):
			return false

	return true


func _all_share_a_tag(flowers: Array[FlowerData]) -> bool:
	if flowers.size() < 2:
		return false
	for t in flowers[0].color_tags:
		var all_have := true
		for f in flowers:
			if not f.color_tags.has(t):
				all_have = false
				break
		if all_have:
			return true
	return false
