extends Control
## 主菜单骨架：显示项目名与版本，后续接入正式 UI 与"开始新周目"入口。

@onready var title_label: Label = $Title
@onready var version_label: Label = $Version


func _ready() -> void:
	title_label.text = "Bloom & Bust"
	version_label.text = "花店 Roguelite —— 骨架版 v0.2\nGodot 4.7.2 · 主菜单占位"
