extends Node
## 存档系统（Autoload）：JSON 存档读写，Meta 与 Run 严格分离。

const META_SAVE_PATH := "user://meta_save.json"
const RUN_SAVE_PATH := "user://run_save.json"


func save_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: 无法写入 " + path)
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return true


func load_json(path: String, default_data: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		return default_data
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return default_data
	var text := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(text) != OK:
		push_error("SaveSystem: JSON 解析失败 " + path)
		return default_data
	var data = json.data
	return data if data is Dictionary else default_data


func save_meta(data: Dictionary) -> bool:
	return save_json(META_SAVE_PATH, data)


func load_meta() -> Dictionary:
	return load_json(META_SAVE_PATH, {})


func save_run(data: Dictionary) -> bool:
	# 仅调试用，正式版删除
	return save_json(RUN_SAVE_PATH, data)


func delete_run_save() -> void:
	if FileAccess.file_exists(RUN_SAVE_PATH):
		DirAccess.remove_absolute(RUN_SAVE_PATH)
