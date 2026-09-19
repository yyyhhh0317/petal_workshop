extends Node
## 单局生命周期管理器（Autoload）：只负责周目级状态与生命周期——
## 种子 / 债务 / 目标天数 / 资金 / 花材池 / 胜负判定。
## 每日循环（阶段状态机、库存、花束、展示位、营业、结算）已下沉至 DayCycle，
## 本类保留门面方法委托给 day，保证既有调用方（UI / 测试）无需改动。

const BASE_START_MONEY := 500
const DEFAULT_TARGET_DAYS := 10
const DEFAULT_DEBT := 800
const BASE_POOL_SIZE := 8

var run_active := false
var seed_value: int = 0
var current_day: int = 0
var target_days: int = DEFAULT_TARGET_DAYS
var debt: int = DEFAULT_DEBT
var economy: EconomySystem
var event_system: EventSystem
var customer_system: CustomerSystem
var seed_generator: SeedGenerator
var combo_engine: ComboEngine
var flower_pool: Array[String] = []      # 本局可进货的花材 id（周目级，开局随机）
var run_reputation: int = 0              # 本局售花累计声望
var day: DayCycle

# —— 门面属性：委托 DayCycle，保持调用方兼容 ——

var current_phase: DayPhase.Phase:
	get: return day.current_phase if day else DayPhase.Phase.BUY

var inventory: Dictionary:
	get: return day.inventory if day else {}

var current_bouquet: Array[String]:
	get: return day.current_bouquet if day else []

var current_slot_index: int:
	get: return day.current_slot_index if day else 0
	set(value): if day: day.current_slot_index = value

var display_slots: Array:
	get: return day.display_slots if day else []

var day_log: Array[String]:
	get: return day.day_log if day else []

var daily_event: DailyEvent:
	get: return day.daily_event if day else null


# ---------- 周目生命周期 ----------

func start_run(p_seed: int = 0, p_target_days: int = DEFAULT_TARGET_DAYS) -> void:
	## 开始新周目：应用元进度升级（初始资金/折扣/展示位/花材池），
	## 花材池按声望解锁过滤，创建每日循环控制器。
	seed_generator = SeedGenerator.new()
	seed_generator.initialize(p_seed)
	seed_value = seed_generator.seed_value
	var start_money := BASE_START_MONEY + 50 * MetaManager.get_upgrade_level("up_start_money")
	economy = EconomySystem.new(start_money)
	event_system = EventSystem.new()
	customer_system = CustomerSystem.new()
	combo_engine = ComboEngine.new()
	run_active = true
	current_day = 1
	target_days = p_target_days
	debt = DEFAULT_DEBT
	run_reputation = 0
	FlowerDatabase.load_all()
	var unlocked := FlowerDatabase.get_unlocked_flowers(int(MetaManager.meta.reputation))
	flower_pool = seed_generator.roll_flower_pool(pool_size(), unlocked)
	day = DayCycle.new(self)
	day.daily_event = event_system.roll_daily_event(seed_generator.get_rng(), EventSystem.load_event_pool())
	EventBus.run_started.emit(seed_value)


func end_run(victory: bool) -> void:
	if not run_active:
		return
	run_active = false
	MetaManager.record_run_end(current_day, victory, run_reputation)
	EventBus.run_ended.emit(victory, {
		"day": current_day,
		"money": economy.money,
		"debt": debt,
		"seed": seed_value,
	})


func advance_day() -> void:
	## 进入次日：达到目标天数时按资金是否够还债判定胜负。
	if current_day >= target_days:
		end_run(economy.money >= debt)
		return
	current_day += 1
	day.reset_for_new_day()
	EventBus.day_started.emit(current_day)
	EventBus.phase_changed.emit(day.current_phase)


func abandon_run() -> void:
	## 中途放弃当前周目：不折算元进度，仅置为非活动。
	run_active = false


func slot_count() -> int:
	return 3 + MetaManager.get_upgrade_level("up_slot")


func pool_size() -> int:
	return BASE_POOL_SIZE + MetaManager.get_upgrade_level("up_pool")


func debt_remaining() -> int:
	return maxi(debt - economy.money, 0)


# ---------- 门面委托（每日逻辑在 DayCycle） ----------

func set_phase(phase: DayPhase.Phase) -> void:
	day.set_phase(phase)


func reroll_daily_event() -> bool:
	return day.reroll_daily_event()


func get_slot_name(index: int) -> String:
	return day.get_slot_name(index)


func get_slot_type(index: int) -> ComboContext.SlotType:
	return day.get_slot_type(index)


func get_flower_cost(id: String) -> int:
	return day.get_flower_cost(id)


func buy_flower(id: String, count: int = 1) -> bool:
	return day.buy_flower(id, count)


func inventory_total() -> int:
	return day.inventory_total()


func add_to_bouquet(id: String) -> bool:
	return day.add_to_bouquet(id)


func remove_from_bouquet(id: String) -> void:
	day.remove_from_bouquet(id)


func clear_bouquet() -> void:
	day.clear_bouquet()


func compute_bouquet_value() -> ComboResult:
	return day.compute_bouquet_value()


func place_bouquet_to_current_slot() -> bool:
	return day.place_bouquet_to_current_slot()


func run_business_day() -> Array[String]:
	return day.run_business_day()


func finish_day() -> Dictionary:
	return day.finish_day()


func check_defeat() -> bool:
	return day.check_defeat()
