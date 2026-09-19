extends Control
## 主菜单：显示项目名与版本，提供「开始新周目」入口。

@onready var title_label: Label = $Title
@onready var version_label: Label = $Version
@onready var start_button: Button = $StartButton


func _ready() -> void:
	title_label.text = "花间工坊"
	version_label.text = "Petal Workshop —— 原型 v0.3\nGodot 4.7.2 · M1 核心原型"
	start_button.pressed.connect(_on_start_pressed)


func _on_start_pressed() -> void:
	RunManager.start_run(0, 500, 5)
	get_tree().change_scene_to_file("res://scenes/shop/shop.tscn")
