extends Node
## 元进度管理器（Autoload）：跨局持久化的解锁、图鉴、技能点、声望。
## 铁律：Run State 只能通过本类提供的结算接口折算进来。

const DEFAULT_META := {
	"version": 1,
	"encyclopedia": {},
	"unlocked_flowers": [],
	"skill_points": 0,
	"upgrades": {},
	"reputation": 0,
	"runs_completed": 0,
	"best_day": 0,
}

var meta: Dictionary = {}


func _ready() -> void:
	load_meta()


func load_meta() -> void:
	meta = SaveSystem.load_meta()
	for key in DEFAULT_META:
		if not meta.has(key):
			var default_value = DEFAULT_META[key]
			if default_value is Dictionary or default_value is Array:
				meta[key] = default_value.duplicate(true)
			else:
				meta[key] = default_value


func save_meta() -> void:
	SaveSystem.save_meta(meta)


func record_combo(combo_id: String) -> bool:
	## 首次发现组合规则时记录进图鉴，返回是否为新发现。
	if meta.encyclopedia.has(combo_id):
		return false
	meta.encyclopedia[combo_id] = true
	EventBus.meta_unlocked.emit(combo_id)
	return true


func add_skill_points(amount: int) -> void:
	meta.skill_points += amount


func gain_reputation(amount: int) -> void:
	meta.reputation += amount


func record_run_end(day_reached: int, victory: bool) -> void:
	meta.runs_completed += 1
	meta.best_day = maxi(meta.best_day, day_reached)
	save_meta()
