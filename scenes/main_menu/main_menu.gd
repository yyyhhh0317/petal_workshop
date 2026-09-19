extends Control
## 主菜单：开始新周目（随机种子）、每日挑战（日期固定种子）、工坊手册（元进度）。

@onready var title_label: Label = $Title
@onready var version_label: Label = $Version
@onready var stats_label: Label = $MetaStats
@onready var start_button: Button = $StartButton
@onready var challenge_button: Button = $ChallengeButton
@onready var hub_button: Button = $HubButton


func _ready() -> void:
	title_label.text = "花间工坊"
	version_label.text = "Petal Workshop —— 原型 v0.4\nGodot 4.7.2 · M2 Roguelite 系统"
	_refresh_stats()
	start_button.pressed.connect(_on_start_pressed)
	challenge_button.pressed.connect(_on_challenge_pressed)
	hub_button.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://scenes/meta_hub/meta_hub.tscn"))


func _refresh_stats() -> void:
	var m: Dictionary = MetaManager.meta
	stats_label.text = "声望 %d · 技能点 %d · 已完成周目 %d" % [m.reputation, m.skill_points, m.runs_completed]
	var challenge_seed := int(Time.get_date_string_from_system().replace("-", ""))
	challenge_button.text = "每日挑战（种子 %d）" % challenge_seed


func _on_start_pressed() -> void:
	RunManager.start_run(0, 10)
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")


func _on_challenge_pressed() -> void:
	var challenge_seed := int(Time.get_date_string_from_system().replace("-", ""))
	RunManager.start_run(challenge_seed, 10)
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
