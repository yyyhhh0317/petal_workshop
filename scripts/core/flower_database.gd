class_name FlowerDatabase
## 花材与组合规则数据注册表：扫描 data/ 下的 .tres，懒加载 + 缓存。

const FLOWER_DIR := "res://data/flowers"
const COMBO_DIR := "res://data/combos"

static var _flowers: Dictionary = {}
static var _combo_rules: Array[ComboRule] = []
static var _loaded := false


static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	_flowers.clear()
	_combo_rules.clear()
	for path in _list_tres(FLOWER_DIR):
		var res: FlowerData = load(path)
		if res:
			_flowers[res.id] = res
	for path in _list_tres(COMBO_DIR):
		var res: ComboRule = load(path)
		if res:
			_combo_rules.append(res)


static func get_flower(id: String) -> FlowerData:
	load_all()
	return _flowers.get(id)


static func get_all_flowers() -> Array[FlowerData]:
	load_all()
	var result: Array[FlowerData] = []
	result.assign(_flowers.values())
	return result


static func get_combo_rules() -> Array[ComboRule]:
	load_all()
	return _combo_rules


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
