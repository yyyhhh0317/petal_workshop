class_name ComboRule
extends Resource
## 组合规则数据模型：规则以 .tres 定义，引擎按优先级匹配、乘法叠加。
## 匹配维度：花材 id / 颜色标签 / 类别 / 稀有度 / 花束结构 / 全束共享属性。

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
@export var required_category: String = ""    # 至少一支属于该类别
@export var min_matches: int = 1
@export var require_shared_tag: bool = false  # 全束共享同一标签（同色系协同）
@export var required_tags_all: Array[String] = [] # 全束每支都含其中至少一个标签（纯色束）
@export var required_categories: Array[String] = []  # 每个类别至少出现一支
@export var any_of_tags: Array[String] = []   # 每个标签至少命中一次
@export var require_shared_category: bool = false    # 全束同一类别
@export var require_min_rarity: int = 0       # 全束稀有度 ≥ N
@export var any_min_rarity: int = 0           # 至少一支稀有度 ≥ N
@export var require_min_size: int = 0         # 花束 ≥ N 支
@export var require_exact_size: int = 0       # 花束恰好 N 支
@export var require_max_size: int = 0         # 花束 ≤ N 支
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

	if not required_categories.is_empty():
		for cat in required_categories:
			if not cats.has(cat):
				return false

	if not any_of_tags.is_empty():
		for t in any_of_tags:
			if not tags.has(t):
				return false

	if require_shared_tag:
		if not _all_share_a_tag(flowers):
			return false

	if not required_tags_all.is_empty():
		for f in flowers:
			var has_any := false
			for t in required_tags_all:
				if f.color_tags.has(t):
					has_any = true
					break
			if not has_any:
				return false

	if require_shared_category:
		if flowers.size() < 2:
			return false
		for f in flowers:
			if f.category != flowers[0].category:
				return false

	if require_min_rarity > 0:
		for f in flowers:
			if f.rarity < require_min_rarity:
				return false

	if any_min_rarity > 0:
		var found_rare := false
		for f in flowers:
			if f.rarity >= any_min_rarity:
				found_rare = true
				break
		if not found_rare:
			return false

	if require_min_size > 0 and flowers.size() < require_min_size:
		return false

	if require_exact_size > 0 and flowers.size() != require_exact_size:
		return false

	if require_max_size > 0 and flowers.size() > require_max_size:
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
