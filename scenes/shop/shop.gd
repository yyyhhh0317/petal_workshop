extends Control
## 商店场景（M2）：每日循环 UI —— 买花 → 组合展示 → 营业 → 结算。
## 周目目标：target_days 天内攒够 debt 还清债务。UI 以代码构建（占位美术）。

var _money_label: Label
var _day_label: Label
var _phase_label: Label
var _event_label: Label
var _goal_label: Label

var _panels: Dictionary = {}           # DayPhase.Phase -> Control
var _result_overlay: Control
var _result_title: Label
var _result_stats: Label

# 买花面板
var _buy_pool_box: HBoxContainer

# 组合面板
var _slot_box: HBoxContainer
var _slot_group: ButtonGroup
var _slot_buttons: Array[Button] = []
var _inventory_box: HBoxContainer
var _bouquet_label: Label
var _preview_label: Label
var _arrange_feedback: Label

# 营业面板
var _business_log: RichTextLabel
var _business_start_btn: Button
var _business_settle_btn: Button

# 结算面板
var _settle_labels: Dictionary = {}
var _settle_log: RichTextLabel


func _ready() -> void:
	if not RunManager.run_active:
		RunManager.start_run()
	_build_ui()
	EventBus.money_changed.connect(_on_money_changed)
	EventBus.phase_changed.connect(_on_phase_changed)
	EventBus.day_started.connect(_on_day_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.inventory_changed.connect(_refresh_arrange_panel)
	EventBus.bouquet_changed.connect(_refresh_arrange_panel)
	EventBus.display_changed.connect(_refresh_arrange_panel)
	EventBus.meta_unlocked.connect(_on_meta_unlocked)
	_refresh_all()


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	root.add_child(header)
	_day_label = Label.new()
	_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_day_label)
	_phase_label = Label.new()
	_phase_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_phase_label)
	_money_label = Label.new()
	header.add_child(_money_label)
	_goal_label = Label.new()
	header.add_child(_goal_label)

	_event_label = Label.new()
	_event_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(_event_label)

	_panels[DayPhase.Phase.BUY] = _build_buy_panel()
	_panels[DayPhase.Phase.ARRANGE] = _build_arrange_panel()
	_panels[DayPhase.Phase.BUSINESS] = _build_business_panel()
	_panels[DayPhase.Phase.SETTLEMENT] = _build_settlement_panel()
	for key in _panels:
		root.add_child(_panels[key])

	_build_result_overlay()


# ---------- 买花面板 ----------

func _build_buy_panel() -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "今天的花材池（价格受当日事件与进货折扣影响）"
	vbox.add_child(title)

	_buy_pool_box = HBoxContainer.new()
	vbox.add_child(_buy_pool_box)

	var done_btn := Button.new()
	done_btn.text = "完成进货，去组合花束 →"
	done_btn.pressed.connect(func() -> void: RunManager.set_phase(DayPhase.Phase.ARRANGE))
	vbox.add_child(done_btn)
	return panel


func _refresh_buy_panel() -> void:
	for child in _buy_pool_box.get_children():
		_buy_pool_box.remove_child(child)
		child.queue_free()
	for id in RunManager.flower_pool:
		var f := FlowerDatabase.get_flower(id)
		if f == null:
			continue
		var vbox := VBoxContainer.new()
		_buy_pool_box.add_child(vbox)
		var name_label := Label.new()
		name_label.text = "%s\n价值 %d · 库存 %d" % [f.display_name, f.base_value, int(RunManager.inventory.get(id, 0))]
		vbox.add_child(name_label)
		var btn := Button.new()
		var cost := RunManager.get_flower_cost(id)
		btn.text = "买入（%d 元）" % cost
		btn.disabled = not RunManager.economy.can_afford(cost)
		btn.pressed.connect(func() -> void: _on_buy_pressed(id))
		vbox.add_child(btn)


func _on_buy_pressed(id: String) -> void:
	if RunManager.buy_flower(id):
		_refresh_all()


# ---------- 组合面板 ----------

func _build_arrange_panel() -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var slots_label := Label.new()
	slots_label.text = "展示位（点击选择，橱窗位 ×1.5 价值加成）"
	vbox.add_child(slots_label)

	_slot_group = ButtonGroup.new()
	_slot_box = HBoxContainer.new()
	vbox.add_child(_slot_box)

	var hint := Label.new()
	hint.text = "点击花材加入/移出花束（最多 5 支）"
	vbox.add_child(hint)

	_inventory_box = HBoxContainer.new()
	vbox.add_child(_inventory_box)

	_bouquet_label = Label.new()
	vbox.add_child(_bouquet_label)

	var clear_btn := Button.new()
	clear_btn.text = "清空花束"
	clear_btn.pressed.connect(func() -> void: RunManager.clear_bouquet())
	vbox.add_child(clear_btn)

	_preview_label = Label.new()
	_preview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(_preview_label)

	var place_btn := Button.new()
	place_btn.text = "放入当前展示位"
	place_btn.pressed.connect(_on_place_pressed)
	vbox.add_child(place_btn)

	_arrange_feedback = Label.new()
	vbox.add_child(_arrange_feedback)

	var business_btn := Button.new()
	business_btn.text = "开始营业 →"
	business_btn.pressed.connect(func() -> void: RunManager.set_phase(DayPhase.Phase.BUSINESS))
	vbox.add_child(business_btn)
	return panel


func _rebuild_slot_buttons() -> void:
	for child in _slot_box.get_children():
		_slot_box.remove_child(child)
		child.queue_free()
	_slot_buttons.clear()
	for i in RunManager.display_slots.size():
		var btn := Button.new()
		btn.toggle_mode = true
		btn.button_group = _slot_group
		btn.pressed.connect(func() -> void: _on_slot_selected(i))
		_slot_buttons.append(btn)
		_slot_box.add_child(btn)


func _on_slot_selected(index: int) -> void:
	RunManager.current_slot_index = index
	_refresh_arrange_panel()


func _on_flower_toggle(id: String) -> void:
	if id in RunManager.current_bouquet:
		RunManager.remove_from_bouquet(id)
	else:
		RunManager.add_to_bouquet(id)


func _on_place_pressed() -> void:
	if not RunManager.place_bouquet_to_current_slot():
		_arrange_feedback.text = "先选几支花再放入展示位。"
	else:
		_arrange_feedback.text = "已放入「%s」。" % RunManager.get_slot_name(RunManager.current_slot_index)
	_refresh_arrange_panel()


func _on_meta_unlocked(unlock_id: String) -> void:
	for rule in FlowerDatabase.get_combo_rules():
		if rule.id == unlock_id:
			_arrange_feedback.text = "✨ 新组合发现：「%s」已收录图鉴！" % rule.display_name
			return


func _refresh_arrange_panel() -> void:
	if _slot_buttons.size() != RunManager.display_slots.size():
		_rebuild_slot_buttons()
	for i in _slot_buttons.size():
		var btn := _slot_buttons[i]
		var slot = RunManager.display_slots[i]
		var text := "%s %s" % [RunManager.get_slot_name(i), "×1.5" if i == 0 else ""]
		if slot.result != null:
			var r: ComboResult = slot.result
			var names: Array[String] = []
			for id in slot.bouquet:
				names.append(FlowerDatabase.get_flower(id).display_name)
			text += "\n%s 共 %d 元" % ["+".join(names), r.final_value]
		else:
			text += "\n（空）"
		btn.text = text
		btn.button_pressed = (i == RunManager.current_slot_index)

	for child in _inventory_box.get_children():
		_inventory_box.remove_child(child)
		child.queue_free()
	for id in RunManager.flower_pool:
		var count := int(RunManager.inventory.get(id, 0))
		var in_bouquet := RunManager.current_bouquet.count(id)
		if count <= 0 and in_bouquet <= 0:
			continue
		var f := FlowerDatabase.get_flower(id)
		var btn := Button.new()
		btn.text = "%s ×%d%s" % [f.display_name, count + in_bouquet, "（在花束中）" if in_bouquet > 0 else ""]
		btn.pressed.connect(func() -> void: _on_flower_toggle(id))
		_inventory_box.add_child(btn)

	var names: Array[String] = []
	for id in RunManager.current_bouquet:
		names.append(FlowerDatabase.get_flower(id).display_name)
	_bouquet_label.text = "当前花束（%d/5）：%s" % [names.size(), "、".join(names) if not names.is_empty() else "空"]

	var result := RunManager.compute_bouquet_value()
	if RunManager.current_bouquet.is_empty():
		_preview_label.text = "选几支花，看看能卖出什么价钱。"
	else:
		var lines: Array[String] = []
		lines.append("预览：基础 %d × %.2f = %d 元" % [result.base_value, result.multiplier, result.final_value])
		for mod in result.modifiers:
			lines.append("· " + mod)
		_preview_label.text = "\n".join(lines)


# ---------- 营业面板 ----------

func _build_business_panel() -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "营业中 —— 顾客会按自己的偏好挑选花束，不满意可能会砍价"
	vbox.add_child(title)

	_business_start_btn = Button.new()
	_business_start_btn.text = "开始营业"
	_business_start_btn.pressed.connect(_on_business_start)
	vbox.add_child(_business_start_btn)

	_business_log = RichTextLabel.new()
	_business_log.custom_minimum_size = Vector2(0, 300)
	_business_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_business_log)

	_business_settle_btn = Button.new()
	_business_settle_btn.text = "查看结算 →"
	_business_settle_btn.visible = false
	_business_settle_btn.pressed.connect(_on_business_settle)
	vbox.add_child(_business_settle_btn)
	return panel


func _on_business_start() -> void:
	var log := RunManager.run_business_day()
	_business_log.clear()
	for line in log:
		_business_log.append_text(line + "\n")
	_business_start_btn.visible = false
	_business_settle_btn.visible = true


func _on_business_settle() -> void:
	_fill_settlement(RunManager.finish_day())
	RunManager.set_phase(DayPhase.Phase.SETTLEMENT)


# ---------- 结算面板 ----------

func _build_settlement_panel() -> Control:
	var panel := PanelContainer.new()
	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "今日结算"
	vbox.add_child(title)

	for key in ["revenue", "cost", "profit", "money", "debt"]:
		var lb := Label.new()
		_settle_labels[key] = lb
		vbox.add_child(lb)

	_settle_log = RichTextLabel.new()
	_settle_log.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(_settle_log)

	var next_btn := Button.new()
	next_btn.text = "下一天 →"
	next_btn.pressed.connect(_on_next_day)
	vbox.add_child(next_btn)
	return panel


func _fill_settlement(settle: Dictionary) -> void:
	_settle_labels["revenue"].text = "营业收入：%d 元" % settle.revenue
	_settle_labels["cost"].text = "进货支出：%d 元" % settle.cost
	_settle_labels["profit"].text = "当日利润：%d 元" % settle.profit
	_settle_labels["money"].text = "当前资金：%d 元" % settle.money
	var remaining := RunManager.debt_remaining()
	_settle_labels["debt"].text = "债务进度：还需 %d 元%s" % [remaining, "（已可还清！）" if remaining == 0 else ""]
	_settle_log.clear()
	for line in RunManager.day_log:
		_settle_log.append_text(line + "\n")


func _on_next_day() -> void:
	RunManager.advance_day()


# ---------- 全局刷新与结果 ----------

func _refresh_all() -> void:
	_day_label.text = "第 %d/%d 天 · 种子 %d" % [RunManager.current_day, RunManager.target_days, RunManager.seed_value]
	_phase_label.text = "阶段：%s" % _phase_name(RunManager.current_phase)
	_money_label.text = "资金：%d 元" % RunManager.economy.money
	_goal_label.text = "目标：还清 %d 元债务（还差 %d）" % [RunManager.debt, RunManager.debt_remaining()]
	var ev := RunManager.daily_event
	_event_label.text = "今日事件：%s —— %s" % [ev.display_name, ev.description] if ev != null else "今日无特殊事件。"
	for key in _panels:
		_panels[key].visible = (key == RunManager.current_phase)
	_refresh_buy_panel()
	_refresh_arrange_panel()
	_business_start_btn.visible = true
	_business_settle_btn.visible = false


func _phase_name(phase: DayPhase.Phase) -> String:
	match phase:
		DayPhase.Phase.BUY:
			return "买花"
		DayPhase.Phase.ARRANGE, DayPhase.Phase.DISPLAY:
			return "组合与展示"
		DayPhase.Phase.BUSINESS:
			return "营业"
		DayPhase.Phase.SETTLEMENT:
			return "结算"
	return ""


func _on_money_changed(money: int) -> void:
	_money_label.text = "资金：%d 元" % money
	_goal_label.text = "目标：还清 %d 元债务（还差 %d）" % [RunManager.debt, RunManager.debt_remaining()]
	_refresh_buy_panel()


func _on_phase_changed(phase: DayPhase.Phase) -> void:
	_refresh_all()


func _on_day_started(day_number: int) -> void:
	_refresh_all()
	RunManager.check_defeat()


func _build_result_overlay() -> void:
	_result_overlay = ColorRect.new()
	_result_overlay.color = Color(0, 0, 0, 0.75)
	_result_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.visible = false
	add_child(_result_overlay)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result_overlay.add_child(center)

	var vbox := VBoxContainer.new()
	center.add_child(vbox)

	_result_title = Label.new()
	_result_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result_title.add_theme_font_size_override("font_size", 40)
	vbox.add_child(_result_title)

	_result_stats = Label.new()
	_result_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_result_stats)

	var back_btn := Button.new()
	back_btn.text = "返回主菜单"
	back_btn.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))
	vbox.add_child(back_btn)


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	_result_title.text = "债务还清！" if victory else "经营失败……"
	_result_stats.text = "经营了 %d 天 · 剩余资金 %d 元（债务 %d）· 种子 %d" % [stats.day, stats.money, stats.debt, stats.seed]
	_result_overlay.visible = true
