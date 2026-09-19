extends Node
## 冒烟测试：验证骨架核心链路（数据加载 -> 组合计算 -> 种子确定性 -> 经济流转）。
## 运行：godot --headless --path . res://tests/smoke_test.tscn
## 退出码：0 = 全部通过；1 = 存在失败项。

var _failures := 0


func _ready() -> void:
	_test_database()
	_test_combo_engine()
	_test_seed_determinism()
	_test_economy()
	_test_event_system()
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
	_check(flowers.size() >= 4, "花材数据加载（≥4 种）")
	_check(rules.size() >= 3, "组合规则加载（≥3 条）")
	_check(FlowerDatabase.get_flower("rose") != null, "玫瑰数据可查询")
	_check(FlowerDatabase.get_flower("不存在的花") == null, "未知花材返回 null")


func _test_combo_engine() -> void:
	var engine := ComboEngine.new()
	var ctx := ComboContext.new()
	var classic := engine.calculate_value(["rose", "babys_breath"], ctx)
	print("[smoke] 玫瑰+满天星: base=%d mult=%.2f final=%d" % [classic.base_value, classic.multiplier, classic.final_value])
	_check(classic.final_value > classic.base_value, "传说组合（玫瑰+满天星）应增值")
	_check(classic.modifiers.size() >= 1, "增值组合应记录修正说明")
	var taboo := engine.calculate_value(["lily", "chrysanthemum"], ctx)
	print("[smoke] 百合+菊花: base=%d mult=%.2f final=%d" % [taboo.base_value, taboo.multiplier, taboo.final_value])
	_check(taboo.final_value < taboo.base_value, "禁忌组合（百合+菊花）应贬值")
	var window_ctx := ComboContext.new()
	window_ctx.slot_type = ComboContext.SlotType.WINDOW
	var windowed := engine.calculate_value(["rose"], window_ctx)
	_check(windowed.final_value > 20, "橱窗位加成生效")


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
