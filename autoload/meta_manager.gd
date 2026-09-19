extends Node
## 元进度管理器（Autoload）：跨局持久化的解锁、图鉴、技能点、声望与永久升级。
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
	"last_run": {},
}

const UPGRADE_DEFS := {
	"up_start_money": {"name": "初始资金 +50", "max_level": 3, "cost": 2, "effect": 50},
	"up_discount": {"name": "进货折扣 5%/级", "max_level": 3, "cost": 3, "effect": 5},
	"up_slot": {"name": "展示位 +1", "max_level": 1, "cost": 8, "effect": 1},
	"up_pool": {"name": "花材池 +1/级", "max_level": 2, "cost": 4, "effect": 1},
	"up_reroll": {"name": "每日事件重roll +1/级", "max_level": 2, "cost": 5, "effect": 1},
	"up_hint": {"name": "图鉴线索提示", "max_level": 2, "cost": 4, "effect": 1},
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


func reset_meta() -> void:
	## 重置为默认进度并落盘（供测试与调试）。
	meta = {}
	for key in DEFAULT_META:
		var default_value = DEFAULT_META[key]
		if default_value is Dictionary or default_value is Array:
			meta[key] = default_value.duplicate(true)
		else:
			meta[key] = default_value
	save_meta()


# ---------- 图鉴 ----------

func record_combo(combo_id: String) -> bool:
	## 首次发现组合规则时记录进图鉴，返回是否为新发现。
	if meta.encyclopedia.has(combo_id):
		return false
	meta.encyclopedia[combo_id] = true
	EventBus.meta_unlocked.emit(combo_id)
	return true


# ---------- 技能点与升级 ----------

func add_skill_points(amount: int) -> void:
	meta.skill_points += amount


func get_upgrade_level(upgrade_id: String) -> int:
	return int(meta.upgrades.get(upgrade_id, 0))


func get_upgrade_max(upgrade_id: String) -> int:
	return int(UPGRADE_DEFS[upgrade_id].max_level)


func can_buy_upgrade(upgrade_id: String) -> bool:
	if not UPGRADE_DEFS.has(upgrade_id):
		return false
	if get_upgrade_level(upgrade_id) >= get_upgrade_max(upgrade_id):
		return false
	return int(meta.skill_points) >= int(UPGRADE_DEFS[upgrade_id].cost)


func buy_upgrade(upgrade_id: String) -> bool:
	if not can_buy_upgrade(upgrade_id):
		return false
	meta.skill_points = int(meta.skill_points) - int(UPGRADE_DEFS[upgrade_id].cost)
	meta.upgrades[upgrade_id] = get_upgrade_level(upgrade_id) + 1
	save_meta()
	return true


# ---------- 周目结算折算 ----------

func gain_reputation(amount: int) -> void:
	meta.reputation += amount


func record_run_end(day_reached: int, victory: bool, run_reputation: int = 0) -> void:
	## 无论胜负都折算元进度（非线性）：
	## 技能点 = 经营天数 + 胜利奖励；胜利奖励仅在突破最佳纪录时为 +3，否则 +1，
	## 避免"两局点满升级树"，让元进度在更长的周目跨度上保持牵引力。
	var is_new_best := day_reached > int(meta.best_day)
	var victory_bonus := 0
	if victory:
		victory_bonus = 3 if is_new_best else 1
	meta.runs_completed += 1
	meta.best_day = maxi(meta.best_day, day_reached)
	meta.skill_points = int(meta.skill_points) + day_reached + victory_bonus
	meta.reputation = int(meta.reputation) + day_reached + run_reputation
	meta.last_run = {"day": day_reached, "victory": victory}
	save_meta()
