class_name FlowerDatabase
## 花材与组合规则数据注册表：扫描 data/ 下的 .tres，懒加载 + 缓存 + schema 校验。
## 花材解锁：unlock_condition 为 "always" 或 "reputation:N"（声望达到 N 解锁）。

const FLOWER_DIR := "res://data/flowers"
const COMBO_DIR := "res://data/combos"

static var _flowers: Dictionary = {}
static var _combo_rules: Array[ComboRule] = []
static var _loaded := false
static var load_warnings: Array[String] = []


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_flowers.clear()
	_combo_rules.clear()
	load_warnings.clear()
	for path in _list_tres(FLOWER_DIR):
		var res: FlowerData = load(path)
		if res:
			_validate_flower(res, path)
			_flowers[res.id] = res
		else:
			_load_warn("花材资源加载失败：" + path)
	for path in _list_tres(COMBO_DIR):
		var res: ComboRule = load(path)
		if res:
			_validate_combo(res, path)
			_combo_rules.append(res)
		else:
			_load_warn("规则资源加载失败：" + path)
	if not load_warnings.is_empty():
		push_warning("FlowerDatabase: %d 条数据校验警告（详见 load_warnings）" % load_warnings.size())


static func has_flower(id: String) -> bool:
	load_all()
	return _flowers.has(id)


static func get_flower(id: String) -> FlowerData:
	load_all()
	return _flowers.get(id)


static func get_all_flowers() -> Array[FlowerData]:
	load_all()
	var result: Array[FlowerData] = []
	result.assign(_flowers.values())
	return result


static func get_unlocked_flowers(reputation: int) -> Array[FlowerData]:
	## 按当前声望返回已解锁花材。
	load_all()
	var result: Array[FlowerData] = []
	for f in _flowers.values():
		if _is_unlocked(f, reputation):
			result.append(f)
	return result


static func is_unlocked(f: FlowerData, reputation: int) -> bool:
	load_all()
	return _is_unlocked(f, reputation)


static func get_combo_rules() -> Array[ComboRule]:
	load_all()
	return _combo_rules


# ---------- 校验 ----------

static func _validate_flower(f: FlowerData, path: String) -> void:
	if f.id == "":
		_load_warn(path + "：id 为空")
	if f.display_name == "":
		_load_warn(path + "：display_name 为空")
	if f.base_value <= 0:
		_load_warn(path + "：base_value 非正数（%d）" % f.base_value)
	if f.cost <= 0:
		_load_warn(path + "：cost 非正数（%d）" % f.cost)
	if f.color_tags.is_empty():
		_load_warn(path + "：color_tags 为空")
	if f.category == "":
		_load_warn(path + "：category 为空")
	if f.rarity < 1 or f.rarity > 5:
		_load_warn(path + "：rarity 越界（%d）" % f.rarity)


static func _validate_combo(rule: ComboRule, path: String) -> void:
	if rule.id == "":
		_load_warn(path + "：id 为空")
	if rule.value_multiplier == 0.0:
		_load_warn(path + "：value_multiplier 为 0")
	if rule.priority < 0:
		_load_warn(path + "：priority 为负")
	var has_condition := false
	if not rule.required_ids.is_empty() or not rule.any_of_ids.is_empty():
		has_condition = true
	if not rule.required_tags.is_empty() or not rule.required_tags_all.is_empty():
		has_condition = true
	if not rule.required_categories.is_empty() or not rule.any_of_tags.is_empty():
		has_condition = true
	if rule.required_category != "" or rule.require_shared_tag or rule.require_shared_category:
		has_condition = true
	if rule.require_min_rarity > 0 or rule.any_min_rarity > 0:
		has_condition = true
	if rule.require_min_size > 0 or rule.require_exact_size > 0 or rule.require_max_size > 0:
		has_condition = true
	if not has_condition:
		_load_warn(path + "：规则没有任何匹配条件（恒真）")


static func _load_warn(msg: String) -> void:
	load_warnings.append(msg)
	push_warning("FlowerDatabase: " + msg)


# ---------- 内部 ----------

static func _is_unlocked(f: FlowerData, reputation: int) -> bool:
	var cond := f.unlock_condition
	if cond == "always" or cond == "":
		return true
	if cond.begins_with("reputation:"):
		var need := int(cond.get_slice(":", 1))
		return reputation >= need
	return false


static func _list_tres(dir_path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			result.append(dir_path + "/" + file_name)
		file_name = dir.get_next()
	dir.list_dir_end()
	return result
