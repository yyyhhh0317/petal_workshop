extends Node
## 单局生命周期管理器（Autoload）：周目开始、每日状态机、库存与展示位状态、
## 进货/组合/营业/结算全流程，以及胜负判定。
## M2：周目目标 = 在 target_days 天内攒够 debt 还清债务；元进度升级影响开局。

const BASE_START_MONEY := 500
const DEFAULT_TARGET_DAYS := 10
const DEFAULT_DEBT := 900
const BOUQUET_MAX := 5

var run_active := false
var seed_value: int = 0
var current_day: int = 0
var target_days: int = DEFAULT_TARGET_DAYS
var debt: int = DEFAULT_DEBT
var current_phase: DayPhase.Phase = DayPhase.Phase.BUY
var economy: EconomySystem
var event_system: EventSystem
var customer_system: CustomerSystem
var seed_generator: SeedGenerator
var combo_engine: ComboEngine

var flower_pool: Array[String] = []      # 本局可进货的花材 id
var inventory: Dictionary = {}           # flower_id -> 数量
var current_bouquet: Array[String] = []  # 正在编辑的花束
var current_slot_index: int = 0
var display_slots: Array = []            # [{bouquet: Array[String], result: ComboResult}]
var day_log: Array[String] = []          # 营业与凋谢日志
var daily_event: DailyEvent
var run_reputation: int = 0              # 本局售花累计声望


func start_run(p_seed: int = 0, p_target_days: int = DEFAULT_TARGET_DAYS) -> void:
	## 开始新周目：应用元进度升级（初始资金/折扣/展示位），花材池按声望解锁过滤。
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
	current_phase = DayPhase.Phase.BUY
	inventory.clear()
	current_bouquet.clear()
	current_slot_index = 0
	display_slots.clear()
	var slot_count := 3 + MetaManager.get_upgrade_level("up_slot")
	for i in slot_count:
		display_slots.append({"bouquet": [], "result": null})
	FlowerDatabase.load_all()
	var unlocked := FlowerDatabase.get_unlocked_flowers(int(MetaManager.meta.reputation))
	flower_pool = seed_generator.roll_flower_pool(8, unlocked)
	daily_event = event_system.roll_daily_event(seed_generator.get_rng(), EventSystem.load_event_pool())
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
	current_phase = DayPhase.Phase.BUY
	daily_event = event_system.roll_daily_event(seed_generator.get_rng(), EventSystem.load_event_pool())
	EventBus.day_started.emit(current_day)
	EventBus.phase_changed.emit(current_phase)


func set_phase(phase: DayPhase.Phase) -> void:
	current_phase = phase
	EventBus.phase_changed.emit(phase)


func abandon_run() -> void:
	## 中途放弃当前周目：不折算元进度，仅置为非活动。
	run_active = false


func debt_remaining() -> int:
	return maxi(debt - economy.money, 0)


# ---------- 展示位 ----------

func get_slot_name(index: int) -> String:
	match index:
		0: return "橱窗位"
		1: return "中央位"
		2: return "角落位"
	return "普通位"


func get_slot_type(index: int) -> ComboContext.SlotType:
	match index:
		0: return ComboContext.SlotType.WINDOW
		1: return ComboContext.SlotType.CENTER
		2: return ComboContext.SlotType.CORNER
	return ComboContext.SlotType.NORMAL


# ---------- 买花 ----------

func get_flower_cost(id: String) -> int:
	var f := FlowerDatabase.get_flower(id)
	if f == null:
		return 0
	var base_cost := f.cost * (1.0 - 0.05 * MetaManager.get_upgrade_level("up_discount"))
	return event_system.apply_cost_multiplier(int(round(base_cost)))


func buy_flower(id: String, count: int = 1) -> bool:
	var f := FlowerDatabase.get_flower(id)
	if f == null:
		return false
	var total := get_flower_cost(id) * count
	if not economy.spend(total):
		return false
	inventory[id] = int(inventory.get(id, 0)) + count
	EventBus.inventory_changed.emit()
	return true


func inventory_total() -> int:
	var total := 0
	for id in inventory:
		total += int(inventory[id])
	return total


# ---------- 组合 ----------

func add_to_bouquet(id: String) -> bool:
	if current_bouquet.size() >= BOUQUET_MAX:
		return false
	if int(inventory.get(id, 0)) <= 0:
		return false
	inventory[id] = int(inventory[id]) - 1
	current_bouquet.append(id)
	EventBus.bouquet_changed.emit()
	EventBus.inventory_changed.emit()
	return true


func remove_from_bouquet(id: String) -> void:
	var idx := current_bouquet.find(id)
	if idx < 0:
		return
	current_bouquet.remove_at(idx)
	inventory[id] = int(inventory.get(id, 0)) + 1
	EventBus.bouquet_changed.emit()
	EventBus.inventory_changed.emit()


func clear_bouquet() -> void:
	for id in current_bouquet:
		inventory[id] = int(inventory.get(id, 0)) + 1
	current_bouquet.clear()
	EventBus.bouquet_changed.emit()
	EventBus.inventory_changed.emit()


func compute_bouquet_value() -> ComboResult:
	## 按当前选中展示位的上下文实时计算花束价值。
	if current_bouquet.is_empty():
		return ComboResult.new()
	var ctx := ComboContext.new()
	ctx.slot_type = get_slot_type(current_slot_index)
	ctx.trend_tags = event_system.trend_tags
	ctx.day_number = current_day
	return combo_engine.calculate_value(current_bouquet.duplicate(), ctx)


func place_bouquet_to_current_slot() -> bool:
	if current_bouquet.is_empty():
		return false
	var result := compute_bouquet_value()
	display_slots[current_slot_index] = {"bouquet": current_bouquet.duplicate(), "result": result}
	current_bouquet.clear()
	EventBus.bouquet_changed.emit()
	EventBus.display_changed.emit()
	for rule_id in result.matched_rule_ids:
		MetaManager.record_combo(rule_id)
	return true


# ---------- 营业 ----------

func run_business_day() -> Array[String]:
	## 生成当日顾客，按偏好挑选花束并付款；满意度低且超预算时顾客会砍价。
	clear_bouquet()
	day_log.clear()
	var rng := seed_generator.get_rng()
	var customer_count := rng.randi_range(2, 4)
	for i in customer_count:
		var profile: CustomerProfile = seed_generator.pick_from(CustomerSystem.get_profiles())
		if profile == null:
			continue
		var customer := customer_system.generate_customer(profile, rng)
		var slot_idx := customer_system.pick_bouquet(customer, display_slots)
		if slot_idx < 0:
			day_log.append("%s 逛了一圈，没有满意的花束，离开了。" % profile.display_name)
			continue
		var slot = display_slots[slot_idx]
		var result: ComboResult = slot.result
		var flowers := _resolve_flowers(slot.bouquet)
		var score := customer_system.score_bouquet(customer, flowers)
		var pay := int(round(result.final_value * (0.6 + 0.8 * score)))
		pay = event_system.apply_value_multiplier(pay)
		var budget: int = customer.budget
		var haggle := false
		if score >= 0.5:
			pay = mini(pay, budget)
		elif pay > budget:
			pay = int(round(float(budget) * 0.7))
			haggle = true
		economy.earn(pay)
		run_reputation += 1
		if haggle:
			day_log.append("%s 买走了「%s」，讨价还价后支付 %d 元（满意度 %d%%）" % [profile.display_name, get_slot_name(slot_idx), pay, int(score * 100.0)])
		else:
			day_log.append("%s 买走了「%s」，支付 %d 元（满意度 %d%%）" % [profile.display_name, get_slot_name(slot_idx), pay, int(score * 100.0)])
		EventBus.customer_served.emit(score, pay)
		slot.bouquet.clear()
		slot.result = null
		EventBus.display_changed.emit()
	return day_log


func finish_day() -> Dictionary:
	## 结算当日收支；未售出花束凋谢；当日事件失效。
	var settle := economy.end_day()
	var wilted := 0
	for i in display_slots.size():
		var slot = display_slots[i]
		if slot.result != null:
			wilted += slot.bouquet.size()
			slot.bouquet.clear()
			slot.result = null
	if wilted > 0:
		day_log.append("%d 支未售出的花在夜里凋谢了。" % wilted)
	event_system.active_events.clear()
	event_system.trend_tags.clear()
	daily_event = null
	EventBus.display_changed.emit()
	return settle


func check_defeat() -> bool:
	## 资金不足以买最便宜的花且没有可售库存时破产。
	var cheapest := 0
	for id in flower_pool:
		var c := get_flower_cost(id)
		if cheapest == 0 or c < cheapest:
			cheapest = c
	var has_stock := false
	for id in inventory:
		if int(inventory[id]) > 0:
			has_stock = true
			break
	for slot in display_slots:
		if slot.result != null:
			has_stock = true
			break
	if cheapest > 0 and economy.money < cheapest and not has_stock:
		end_run(false)
		return true
	return false


func _resolve_flowers(ids: Array[String]) -> Array[FlowerData]:
	var result: Array[FlowerData] = []
	for id in ids:
		var f := FlowerDatabase.get_flower(id)
		if f:
			result.append(f)
	return result
