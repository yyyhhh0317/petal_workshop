class_name DayCycle
extends RefCounted
## 每日循环控制器：阶段状态机、库存、花束编辑、展示位、营业与结算。
## 由 RunManager 创建并持有；通过 run 引用访问周目级系统，保持职责边界。

const BOUQUET_MAX := 5
const DAILY_RENT := 20   # 摊位租金：每日固定成本，防止囤现金的保守打法无代价

var run                        # RunManager 周目级上下文（避免循环依赖，无类型引用）
var current_phase: DayPhase.Phase = DayPhase.Phase.BUY
var inventory: Dictionary = {}           # flower_id -> 数量
var current_bouquet: Array[String] = []  # 正在编辑的花束
var current_slot_index: int = 0
var display_slots: Array = []            # [{bouquet: Array[String], result: ComboResult}]
var day_log: Array[String] = []          # 营业与凋谢日志
var daily_event: DailyEvent
var rerolls_left: int = 0                # 当日剩余事件重roll次数（升级加成）


func _init(p_run) -> void:
	run = p_run
	rerolls_left = MetaManager.get_upgrade_level("up_reroll")
	for i in run.slot_count():
		display_slots.append({"bouquet": [], "result": null})


func reset_for_new_day() -> void:
	## 次日开始：回到买花阶段，恢复重roll次数，抽取新事件。
	current_phase = DayPhase.Phase.BUY
	rerolls_left = MetaManager.get_upgrade_level("up_reroll")
	daily_event = run.event_system.roll_daily_event(run.seed_generator.get_rng(), EventSystem.load_event_pool())


func set_phase(phase: DayPhase.Phase) -> void:
	current_phase = phase
	EventBus.phase_changed.emit(phase)


func reroll_daily_event() -> bool:
	## 消耗一次重roll机会刷新当日事件。
	if rerolls_left <= 0:
		return false
	rerolls_left -= 1
	daily_event = run.event_system.roll_daily_event(run.seed_generator.get_rng(), EventSystem.load_event_pool())
	return true


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
	return run.event_system.apply_cost_multiplier(int(round(base_cost)))


func buy_flower(id: String, count: int = 1) -> bool:
	var f := FlowerDatabase.get_flower(id)
	if f == null:
		return false
	var total := get_flower_cost(id) * count
	if not run.economy.spend(total):
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
	ctx.trend_tags = run.event_system.trend_tags
	ctx.day_number = run.current_day
	return run.combo_engine.calculate_value(current_bouquet.duplicate(), ctx)


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
	var rng: RandomNumberGenerator = run.seed_generator.get_rng()
	var customer_count: int = rng.randi_range(2, 4)
	for i in customer_count:
		var profile: CustomerProfile = run.seed_generator.pick_from(CustomerSystem.get_profiles())
		if profile == null:
			continue
		var customer: Dictionary = run.customer_system.generate_customer(profile, rng)
		var slot_idx: int = run.customer_system.pick_bouquet(customer, display_slots)
		if slot_idx < 0:
			day_log.append("%s 逛了一圈，没有满意的花束，离开了。" % profile.display_name)
			continue
		var slot: Dictionary = display_slots[slot_idx]
		var result: ComboResult = slot.result
		var flowers: Array[FlowerData] = _resolve_flowers(slot.bouquet)
		var score: float = run.customer_system.score_bouquet(customer, flowers)
		var pay: int = int(round(result.final_value * (0.6 + 0.8 * score)))
		pay = run.event_system.apply_value_multiplier(pay)
		var budget: int = customer.budget
		var haggle := false
		if score >= 0.5:
			pay = mini(pay, budget)
		elif pay > budget:
			pay = int(round(float(budget) * 0.7))
			haggle = true
		run.economy.earn(pay)
		run.run_reputation += 1
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
	## 结算当日收支（含摊位租金）；未售出花束凋谢；当日事件失效。
	var rent: int = run.economy.pay_fixed(DAILY_RENT)
	var settle: Dictionary = run.economy.end_day()
	day_log.append("摊位租金 %d 元。" % rent)
	var wilted := 0
	for i in display_slots.size():
		var slot: Dictionary = display_slots[i]
		if slot.result != null:
			wilted += slot.bouquet.size()
			slot.bouquet.clear()
			slot.result = null
	if wilted > 0:
		day_log.append("%d 支未售出的花在夜里凋谢了。" % wilted)
	run.event_system.active_events.clear()
	run.event_system.trend_tags.clear()
	daily_event = null
	EventBus.display_changed.emit()
	return settle


func check_defeat() -> bool:
	## 资金不足以买最便宜的花且没有可售库存时破产。
	var cheapest := 0
	for id in run.flower_pool:
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
	if cheapest > 0 and run.economy.money < cheapest and not has_stock:
		run.end_run(false)
		return true
	return false


func _resolve_flowers(ids: Array[String]) -> Array[FlowerData]:
	var result: Array[FlowerData] = []
	for id in ids:
		var f := FlowerDatabase.get_flower(id)
		if f:
			result.append(f)
	return result
