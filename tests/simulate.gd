extends Node
## 批量自动对局平衡工具：三种 bot 策略分组统计胜率与资金分布。
## 运行：godot --headless --path . res://tests/simulate.tscn
## 可选环境变量：SIM_RUNS（每策略局数，默认 200）、SIM_DAYS（周目天数，默认 10）
## 策略：greedy 贪心进货；combo_hunter 锁定传说组合；conservative 保守低消费。

const DEFAULT_RUNS := 100
const DEFAULT_DAYS := 10
const MAX_INVENTORY := 15

var _run_count: int = DEFAULT_RUNS
var _run_days: int = DEFAULT_DAYS
var _strategies := ["greedy", "combo_hunter", "conservative"]
var _stats: Dictionary = {}
var _current_strategy := ""
var _combo_target_ids: Array[String] = []


func _ready() -> void:
	var env_runs := int(OS.get_environment("SIM_RUNS"))
	if env_runs > 0:
		_run_count = env_runs
	var env_days := int(OS.get_environment("SIM_DAYS"))
	if env_days > 0:
		_run_days = env_days
	MetaManager.reset_meta()
	EventBus.run_ended.connect(_on_run_ended)
	print("[sim] 对局配置：每策略 %d 局 × %d 策略（目标 %d 天还清债务）" % [_run_count, _strategies.size(), _run_days])
	for strategy in _strategies:
		_stats[strategy] = {"wins": 0, "bankrupt": 0, "debt_fails": 0, "money": 0, "days": 0}
		_current_strategy = strategy
		for i in _run_count:
			_combo_target_ids.clear()
			RunManager.start_run(i + 1, _run_days)
			while RunManager.run_active:
				_bot_day(strategy)
				RunManager.advance_day()
				if RunManager.run_active:
					RunManager.check_defeat()
		_report(strategy)
	print("[sim] 全部完成")
	get_tree().quit(0)


func _report(strategy: String) -> void:
	var s: Dictionary = _stats[strategy]
	var total: int = _run_count
	print("[sim] 策略 %-14s 胜利 %5.1f%%（%d/%d）· 破产 %d · 到期未还 %d · 平均资金 %6.0f · 平均天数 %.1f" % [
		strategy, float(s.wins) / float(total) * 100.0, s.wins, total, s.bankrupt, s.debt_fails,
		float(s.money) / float(total), float(s.days) / float(total)])


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	var s: Dictionary = _stats[_current_strategy]
	s.money += int(stats.money)
	s.days += int(stats.day)
	if victory:
		s.wins += 1
	elif int(stats.day) < _run_days:
		s.bankrupt += 1
	else:
		s.debt_fails += 1


func _bot_day(strategy: String) -> void:
	match strategy:
		"combo_hunter":
			_bot_buy_combo()
		"conservative":
			_bot_buy_conservative()
		_:
			_bot_buy_greedy()
	_bot_arrange(strategy)
	RunManager.run_business_day()
	RunManager.finish_day()


func _bot_buy_greedy() -> void:
	while RunManager.inventory_total() < MAX_INVENTORY:
		var cheapest := _cheapest_id()
		if cheapest == "" or not RunManager.economy.can_afford(RunManager.get_flower_cost(cheapest)):
			break
		RunManager.buy_flower(cheapest)


func _bot_buy_combo() -> void:
	## 随机锁定一条传说组合，池内可凑齐则专攻，否则退化为贪心。
	var legends: Array[ComboRule] = []
	for r in FlowerDatabase.get_combo_rules():
		if r.rule_type == ComboRule.RuleType.LEGENDARY and r.required_ids.size() >= 2:
			legends.append(r)
	var target: ComboRule = RunManager.seed_generator.pick_from(legends)
	if target == null:
		_bot_buy_greedy()
		return
	for id in target.required_ids:
		if not RunManager.flower_pool.has(id):
			_bot_buy_greedy()
			return
	_combo_target_ids = target.required_ids.duplicate()
	while RunManager.inventory_total() < MAX_INVENTORY:
		var bought_one := false
		for id in _combo_target_ids:
			if int(RunManager.inventory.get(id, 0)) < 3 and RunManager.buy_flower(id):
				bought_one = true
				break
		if not bought_one:
			break


func _bot_buy_conservative() -> void:
	## 保守：保持 300 元以上流动资金，少量进货。
	while RunManager.inventory_total() < 8 and RunManager.economy.money > 300:
		var cheapest := _cheapest_id()
		if cheapest == "" or not RunManager.economy.can_afford(RunManager.get_flower_cost(cheapest)):
			break
		RunManager.buy_flower(cheapest)


func _cheapest_id() -> String:
	var cheapest_id := ""
	var cheapest_cost := 0
	for id in RunManager.flower_pool:
		var c := RunManager.get_flower_cost(id)
		if cheapest_id == "" or c < cheapest_cost:
			cheapest_id = id
			cheapest_cost = c
	return cheapest_id


func _bot_arrange(strategy: String) -> void:
	for slot_i in RunManager.display_slots.size():
		var slot = RunManager.display_slots[slot_i]
		if slot.result != null:
			continue
		RunManager.current_slot_index = slot_i
		RunManager.clear_bouquet()
		var max_flowers := 5
		if strategy == "conservative":
			max_flowers = 3
		if strategy == "combo_hunter" and slot_i == 0:
			for id in _combo_target_ids:
				RunManager.add_to_bouquet(id)
		while RunManager.current_bouquet.size() < max_flowers:
			var best_id := ""
			var best_value := 0
			for id in RunManager.inventory:
				if int(RunManager.inventory[id]) <= 0:
					continue
				var v := FlowerDatabase.get_flower(id).base_value
				if v > best_value:
					best_value = v
					best_id = id
			if best_id == "" or not RunManager.add_to_bouquet(best_id):
				break
		if not RunManager.current_bouquet.is_empty():
			RunManager.place_bouquet_to_current_slot()
