extends Node
## 批量自动对局平衡工具：RUN_COUNT 局贪心 bot 对局，统计胜率与资金分布。
## 运行：godot --headless --path . res://tests/simulate.tscn
## bot 策略：买入最便宜的花 → 高价值花优先铺满展示位 → 营业 → 结算。

const RUN_COUNT := 200
const RUN_DAYS := 10
const MAX_INVENTORY := 15

var _wins := 0
var _bankrupt := 0
var _debt_fails := 0
var _total_money := 0
var _total_days := 0


func _ready() -> void:
	MetaManager.reset_meta()
	EventBus.run_ended.connect(_on_run_ended)
	print("[sim] 开始 %d 局自动对局（目标 %d 天还清债务）" % [RUN_COUNT, RUN_DAYS])
	for i in RUN_COUNT:
		RunManager.start_run(i + 1, RUN_DAYS)
		while RunManager.run_active:
			_bot_day()
			RunManager.advance_day()
			if RunManager.run_active:
				RunManager.check_defeat()
	var win_rate := float(_wins) / float(RUN_COUNT) * 100.0
	print("[sim] 对局完成：")
	print("[sim]   还清债务（胜利）: %d 局（%.1f%%）" % [_wins, win_rate])
	print("[sim]   中途破产: %d 局" % _bankrupt)
	print("[sim]   到期未还清: %d 局" % _debt_fails)
	print("[sim]   平均结束资金: %.0f 元" % (float(_total_money) / float(RUN_COUNT)))
	print("[sim]   平均经营天数: %.1f 天" % (float(_total_days) / float(RUN_COUNT)))
	get_tree().quit(0)


func _bot_day() -> void:
	# 进货：能买就买最便宜的
	while RunManager.inventory_total() < MAX_INVENTORY:
		var cheapest_id := ""
		var cheapest_cost := 0
		for id in RunManager.flower_pool:
			var c := RunManager.get_flower_cost(id)
			if cheapest_id == "" or c < cheapest_cost:
				cheapest_id = id
				cheapest_cost = c
		if cheapest_id == "" or not RunManager.economy.can_afford(cheapest_cost):
			break
		RunManager.buy_flower(cheapest_id)
	# 铺满展示位：高价值花优先
	for slot_i in RunManager.display_slots.size():
		var slot = RunManager.display_slots[slot_i]
		if slot.result != null:
			continue
		RunManager.current_slot_index = slot_i
		RunManager.clear_bouquet()
		while RunManager.current_bouquet.size() < 5:
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
	RunManager.run_business_day()
	RunManager.finish_day()


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	_total_money += int(stats.money)
	_total_days += int(stats.day)
	if victory:
		_wins += 1
	elif int(stats.day) < RUN_DAYS:
		_bankrupt += 1
	else:
		_debt_fails += 1
