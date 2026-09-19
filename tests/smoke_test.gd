extends Node
## 冒烟测试：数据加载 -> 组合计算 -> 种子确定性 -> 经济流转 -> 整日循环
## -> 债务周目目标 -> 元进度与升级 -> 顾客耐心阈值。
## 运行：godot --headless --path . res://tests/smoke_test.tscn
## 退出码：0 = 全部通过；1 = 存在失败项。

var _failures := 0


func _ready() -> void:
	_test_database()
	_test_combo_engine()
	_test_seed_determinism()
	_test_economy()
	_test_event_system()
	_test_day_loop()
	_test_run_goal()
	_test_meta_progression()
	_test_patience()
	if _failures == 0:
		print("[smoke] 全部通过 ✔")
		get_tree().quit(0)
	else:
		printerr("[smoke] %d 项失败 ✘" % _failures)
		get_tree().quit(1)


func _check(condition: bool, label: String) -> void:
	if condition:
		print("[smoke] ✔ " + label)
	else:
		_failures += 1
		printerr("[smoke] ✘ " + label)


func _test_database() -> void:
	FlowerDatabase.load_all()
	var flowers := FlowerDatabase.get_all_flowers()
	var rules := FlowerDatabase.get_combo_rules()
	print("[smoke] 花材 %d 种，组合规则 %d 条" % [flowers.size(), rules.size()])
	_check(flowers.size() >= 8, "花材数据加载（≥8 种）")
	_check(rules.size() >= 5, "组合规则加载（≥5 条）")
	_check(FlowerDatabase.get_flower("orchid") != null, "兰花数据可查询")
	_check(FlowerDatabase.get_unlocked_flowers(0).size() == 6, "声望 0 锁定稀有花材")
	_check(FlowerDatabase.get_unlocked_flowers(3).size() == 7, "声望 3 解锁兰花")
	_check(FlowerDatabase.get_unlocked_flowers(6).size() == 8, "声望 6 解锁芍药")
	_check(CustomerSystem.get_profiles().size() >= 4, "顾客档案加载（≥4 种）")
	_check(EventSystem.load_event_pool().size() >= 2, "事件池加载（≥2 个）")


func _test_combo_engine() -> void:
	var engine := ComboEngine.new()
	var ctx := ComboContext.new()
	var classic := engine.calculate_value(["rose", "babys_breath"], ctx)
	print("[smoke] 玫瑰+满天星: base=%d mult=%.2f final=%d" % [classic.base_value, classic.multiplier, classic.final_value])
	_check(classic.final_value > classic.base_value, "传说组合（玫瑰+满天星）应增值")
	_check(classic.matched_rule_ids.has("legendary_rose_babys_breath"), "命中规则 id 已记录")
	var taboo := engine.calculate_value(["lily", "chrysanthemum"], ctx)
	print("[smoke] 百合+菊花: base=%d mult=%.2f final=%d" % [taboo.base_value, taboo.multiplier, taboo.final_value])
	_check(taboo.final_value < taboo.base_value, "禁忌组合（百合+菊花）应贬值")
	var orchid_combo := engine.calculate_value(["rose", "orchid"], ctx)
	_check(orchid_combo.final_value == 90, "雅俗共赏（玫瑰+兰花）x1.8 生效")
	var spring_combo := engine.calculate_value(["sunflower", "tulip"], ctx)
	# 向日葵与郁金香共享 warm 标签：传说 x1.6 × 同色系 x1.1 = 34 → 60
	_check(spring_combo.final_value == 60, "春日礼赞 x1.6 + 同色系 x1.1（34→60）")
	var window_ctx := ComboContext.new()
	window_ctx.slot_type = ComboContext.SlotType.WINDOW
	var windowed := engine.calculate_value(["rose"], window_ctx)
	_check(windowed.final_value > 20, "橱窗位加成生效")
	var trend_ctx := ComboContext.new()
	trend_ctx.trend_tags = ["warm"]
	var trended := engine.calculate_value(["rose", "tulip"], trend_ctx)
	_check(trended.final_value > 20 + 18, "流行趋势加成生效")


func _test_seed_determinism() -> void:
	var sg1 := SeedGenerator.new()
	sg1.initialize(42)
	var pool1 := sg1.roll_flower_pool(3)
	var sg2 := SeedGenerator.new()
	sg2.initialize(42)
	var pool2 := sg2.roll_flower_pool(3)
	_check(pool1 == pool2, "同种子产生相同花材池")
	_check(sg1.roll_int_range(1, 100) == sg2.roll_int_range(1, 100), "同种子随机数序列一致")


func _test_economy() -> void:
	var eco := EconomySystem.new(100)
	_check(eco.spend(40) and eco.money == 60, "进货扣款")
	_check(not eco.spend(999), "资金不足无法购买")
	eco.earn(200)
	var settle := eco.end_day()
	_check(settle.profit == 160, "日结算利润正确")
	_check(settle.money == 260, "日结算余额正确")


func _test_event_system() -> void:
	var ev := load("res://data/events/white_sale.tres") as DailyEvent
	_check(ev != null, "事件模板加载")
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var es := EventSystem.new()
	var rolled := es.roll_daily_event(rng, [ev])
	_check(rolled.id == "white_sale", "事件抽取")
	_check(es.trend_tags.has("white"), "流行趋势聚合")
	_check(es.apply_cost_multiplier(10) == 5, "成本倍率生效")


func _test_day_loop() -> void:
	## 集成测试：完整跑一天（买花 → 组合 → 营业 → 结算 → 次日）。
	MetaManager.reset_meta()
	RunManager.start_run(42, 5)
	_check(RunManager.run_active, "周目开始")
	_check(RunManager.flower_pool.size() >= 3, "花材池随机生成")
	_check(RunManager.daily_event != null, "首日事件已抽取")

	var first_id: String = RunManager.flower_pool[0]
	var cost := RunManager.get_flower_cost(first_id)
	_check(RunManager.buy_flower(first_id, 2), "买花成功")
	_check(RunManager.economy.money == 500 - cost * 2, "买入扣款正确")
	_check(int(RunManager.inventory.get(first_id, 0)) == 2, "库存增加正确")

	_check(RunManager.add_to_bouquet(first_id), "花材加入花束")
	_check(RunManager.add_to_bouquet(first_id), "第二支加入花束")
	_check(int(RunManager.inventory.get(first_id, 0)) == 0, "花束占用库存")
	_check(RunManager.compute_bouquet_value().base_value > 0, "组合价值实时预览")
	_check(RunManager.place_bouquet_to_current_slot(), "花束放入展示位")
	_check(RunManager.current_bouquet.is_empty(), "放入后编辑花束清空")

	var log := RunManager.run_business_day()
	print("[smoke] 营业日志示例：%s" % log[0])
	_check(log.size() >= 1, "营业模拟产生日志")
	var bought := false
	for line in log:
		if line.contains("买走了"):
			bought = true
	var cleared := RunManager.display_slots[0].result == null
	_check(cleared == bought, "营业后展示位状态与成交一致")

	var settle := RunManager.finish_day()
	_check(settle.profit == settle.revenue - settle.cost, "日结算利润一致")
	_check(RunManager.daily_event == null, "当日事件已失效")

	RunManager.advance_day()
	_check(RunManager.current_day == 2, "次日推进")
	_check(RunManager.current_phase == DayPhase.Phase.BUY, "次日回到买花阶段")
	_check(RunManager.daily_event != null, "次日事件已刷新")

	RunManager.end_run(false)
	_check(not RunManager.run_active, "周目结束")


func _test_run_goal() -> void:
	## 债务周目目标：第 10 天按资金是否 ≥ 债务判定胜负。
	MetaManager.reset_meta()
	RunManager.start_run(5, 10)
	_check(RunManager.debt == 600, "周目债务 600")
	_check(RunManager.debt_remaining() == 100, "初始债务差额 100")
	for i in 10:
		RunManager.advance_day()
	_check(not RunManager.run_active, "第 10 天结算后周目结束")
	_check(MetaManager.meta.last_run.victory == false, "资金不足（500<600）判负")

	MetaManager.reset_meta()
	RunManager.start_run(6, 10)
	RunManager.economy.earn(200)
	for i in 10:
		RunManager.advance_day()
	_check(MetaManager.meta.last_run.victory == true, "资金足够（700≥600）判胜")


func _test_meta_progression() -> void:
	## 元进度：技能点/声望折算、三种永久升级与效果、花材解锁入池。
	MetaManager.reset_meta()
	RunManager.start_run(1, 3)
	RunManager.advance_day()
	RunManager.advance_day()
	RunManager.end_run(false)
	_check(int(MetaManager.meta.skill_points) == 3, "技能点 = 经营天数（3 天）")
	_check(int(MetaManager.meta.reputation) == 3, "声望 = 经营天数（3 天）")

	_check(MetaManager.buy_upgrade("up_start_money"), "购买初始资金升级")
	_check(int(MetaManager.meta.skill_points) == 1, "升级扣技能点（3-2）")
	_check(not MetaManager.buy_upgrade("up_slot"), "技能点不足无法购买展示位")
	MetaManager.add_skill_points(10)
	_check(MetaManager.buy_upgrade("up_discount"), "购买进货折扣 Lv.1")
	_check(MetaManager.buy_upgrade("up_discount"), "购买进货折扣 Lv.2")
	MetaManager.add_skill_points(5)
	_check(MetaManager.buy_upgrade("up_slot"), "购买展示位升级")
	_check(MetaManager.get_upgrade_level("up_slot") == 1, "展示位等级 1")
	_check(not MetaManager.buy_upgrade("up_slot"), "展示位已满级")

	RunManager.start_run(2, 3)
	_check(RunManager.economy.money == 550, "初始资金升级生效（500+50）")
	_check(RunManager.display_slots.size() == 4, "展示位升级生效（3+1）")
	_check(RunManager.get_slot_name(3) == "普通位", "第 4 展示位为普通位")
	_check(RunManager.get_slot_type(3) == ComboContext.SlotType.NORMAL, "第 4 展示位无加成")
	var expected_cost := RunManager.event_system.apply_cost_multiplier(int(round(8.0 * 0.9)))
	_check(RunManager.get_flower_cost("lily") == expected_cost, "进货折扣 Lv.2（10%）生效")
	var pool := RunManager.flower_pool
	var unlocked_ok := true
	for id in pool:
		var f := FlowerDatabase.get_flower(id)
		if f.unlock_condition.begins_with("reputation:"):
			unlocked_ok = false
	_check(unlocked_ok, "花材池只含当前声望已解锁花材")
	RunManager.end_run(false)


func _test_patience() -> void:
	## 顾客耐心：耐心 ≥ 4 购买阈值 0.2，否则 0.3。
	var bargain := load("res://data/customers/bargain.tres") as CustomerProfile
	var minimalist := load("res://data/customers/minimalist.tres") as CustomerProfile
	var cs := CustomerSystem.new()
	var bouquet: Array[String] = ["babys_breath", "chrysanthemum", "rose", "lily"]
	var slot := {"bouquet": bouquet, "result": ComboResult.new(100, 1.0, [], [])}
	var slots := [slot]
	var c_patient := {"profile": bargain, "budget": 100, "patience_left": 4}
	var c_impatient := {"profile": minimalist, "budget": 100, "patience_left": 2}
	_check(cs.pick_bouquet(c_patient, slots) == 0, "高耐心顾客接受 0.25 满意度")
	_check(cs.pick_bouquet(c_impatient, slots) == -1, "低耐心顾客拒绝 0.25 满意度")
