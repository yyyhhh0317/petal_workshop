extends Control
## 工坊手册（元进度中心）：图鉴浏览、花材解锁状态、技能点消费与永久升级。
## 支持 ESC 与顶部「返回主菜单」按钮退出。

var _stats_label: Label
var _combo_box: VBoxContainer
var _flower_box: VBoxContainer
var _upgrade_box: VBoxContainer
var _feedback_label: Label


func _ready() -> void:
	theme = ThemeFactory.create()
	_build_background()
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_back_to_menu()
		get_viewport().set_input_as_handled()


func _back_to_menu() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _build_background() -> void:
	var bg := ColorRect.new()
	bg.color = Color("#f7f0df")
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	# 顶部：标题 + 返回
	var top := HBoxContainer.new()
	root.add_child(top)
	var title := Label.new()
	title.text = "📖 工坊手册"
	title.add_theme_font_size_override("font_size", 32)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title)
	var back_btn := Button.new()
	back_btn.text = "← 返回主菜单"
	back_btn.pressed.connect(_back_to_menu)
	top.add_child(back_btn)

	_stats_label = Label.new()
	_stats_label.add_theme_font_size_override("font_size", 22)
	root.add_child(_stats_label)

	# 可滚动内容
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)

	content.add_child(_section_title("—— 组合图鉴 ——"))
	_combo_box = VBoxContainer.new()
	_combo_box.add_theme_constant_override("separation", 4)
	content.add_child(_combo_box)

	content.add_child(_section_title("—— 花材图鉴 ——"))
	_flower_box = VBoxContainer.new()
	_flower_box.add_theme_constant_override("separation", 4)
	content.add_child(_flower_box)

	content.add_child(_section_title("—— 永久升级（消耗技能点）——"))
	_upgrade_box = VBoxContainer.new()
	_upgrade_box.add_theme_constant_override("separation", 8)
	content.add_child(_upgrade_box)

	_feedback_label = Label.new()
	_feedback_label.add_theme_font_size_override("font_size", 22)
	content.add_child(_feedback_label)


func _section_title(text: String) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_size_override("font_size", 26)
	return lb


func _refresh() -> void:
	# 统计
	var m: Dictionary = MetaManager.meta
	_stats_label.text = "声望 %d · 技能点 %d · 完成周目 %d · 最佳经营 %d 天" % [m.reputation, m.skill_points, m.runs_completed, m.best_day]

	# 组合图鉴
	for child in _combo_box.get_children():
		_combo_box.remove_child(child)
		child.queue_free()
	var rules := FlowerDatabase.get_combo_rules()
	var discovered := 0
	for rule in rules:
		var lb := Label.new()
		if m.encyclopedia.has(rule.id):
			discovered += 1
			lb.text = "✔ %s" % rule.display_name
		else:
			lb.text = "？ 未发现的组合"
		_combo_box.add_child(lb)
	var combo_summary := Label.new()
	combo_summary.text = "已发现 %d / %d 条组合规则" % [discovered, rules.size()]
	_combo_box.add_child(combo_summary)

	# 花材图鉴
	for child in _flower_box.get_children():
		_flower_box.remove_child(child)
		child.queue_free()
	var rep := int(m.reputation)
	for f in FlowerDatabase.get_all_flowers():
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		_flower_box.add_child(row)
		if FlowerDatabase.is_unlocked(f, rep):
			if f.icon:
				var icon_rect := TextureRect.new()
				icon_rect.texture = f.icon
				icon_rect.custom_minimum_size = Vector2(28, 28)
				icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				row.add_child(icon_rect)
			var lb := Label.new()
			lb.text = "%s（价值 %d）" % [f.display_name, f.base_value]
			row.add_child(lb)
		else:
			var need := int(f.unlock_condition.get_slice(":", 1))
			var lb := Label.new()
			lb.text = "🔒 ？？？（声望 %d 解锁）" % need
			row.add_child(lb)

	# 升级商店
	for child in _upgrade_box.get_children():
		_upgrade_box.remove_child(child)
		child.queue_free()
	for upgrade_id in MetaManager.UPGRADE_DEFS:
		var def: Dictionary = MetaManager.UPGRADE_DEFS[upgrade_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)
		_upgrade_box.add_child(row)
		var level := MetaManager.get_upgrade_level(upgrade_id)
		var max_level := MetaManager.get_upgrade_max(upgrade_id)
		var lb := Label.new()
		lb.text = "%s：Lv.%d/%d（消耗 %d 技能点）" % [def.name, level, max_level, def.cost]
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lb)
		var btn := Button.new()
		if level >= max_level:
			btn.text = "已满级"
			btn.disabled = true
		else:
			btn.text = "升级"
			btn.disabled = not MetaManager.can_buy_upgrade(upgrade_id)
			btn.pressed.connect(func() -> void: _on_buy_upgrade(upgrade_id))
		row.add_child(btn)


func _on_buy_upgrade(upgrade_id: String) -> void:
	if MetaManager.buy_upgrade(upgrade_id):
		_feedback_label.text = "升级成功！剩余技能点 %d" % MetaManager.meta.skill_points
	else:
		_feedback_label.text = "技能点不足或已满级。"
	_refresh()
