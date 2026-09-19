extends Control
## 商店场景骨架：每日循环（买花 -> 组合 -> 展示 -> 营业 -> 结算）将在此场景展开。
## 当前仅验证 EventBus 通信链路。

@onready var phase_label: Label = $PhaseLabel

var _phase_names := ["买花", "组合", "展示", "营业", "结算"]


func _ready() -> void:
	EventBus.phase_changed.connect(_on_phase_changed)
	phase_label.text = "商店骨架 —— 每日循环尚未实现"


func _on_phase_changed(phase: DayPhase.Phase) -> void:
	phase_label.text = "第 %d 天 · 阶段：%s" % [RunManager.current_day, _phase_names[phase]]
