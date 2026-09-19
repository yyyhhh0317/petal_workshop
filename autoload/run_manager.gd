extends Node
## 单局生命周期管理器（Autoload）：开始新周目、每日状态机、胜负判定。

const MAX_DAYS := 30

var run_active := false
var seed_value: int = 0
var current_day: int = 0
var current_phase: DayPhase.Phase = DayPhase.Phase.BUY
var economy: EconomySystem
var event_system: EventSystem
var customer_system: CustomerSystem
var seed_generator: SeedGenerator


func start_run(p_seed: int = 0, start_money: int = 500) -> void:
	## 开始新周目：初始化种子与各系统，进入第 1 天买花阶段。
	seed_generator = SeedGenerator.new()
	seed_generator.initialize(p_seed)
	seed_value = seed_generator.seed_value
	economy = EconomySystem.new(start_money)
	event_system = EventSystem.new()
	customer_system = CustomerSystem.new()
	run_active = true
	current_day = 1
	current_phase = DayPhase.Phase.BUY
	FlowerDatabase.load_all()
	EventBus.run_started.emit(seed_value)


func end_run(victory: bool) -> void:
	if not run_active:
		return
	run_active = false
	MetaManager.record_run_end(current_day, victory)
	EventBus.run_ended.emit(victory, {
		"day": current_day,
		"money": economy.money,
		"seed": seed_value,
	})


func advance_day() -> void:
	## 进入次日：超过目标天数即胜利。
	if current_day >= MAX_DAYS:
		end_run(true)
		return
	current_day += 1
	current_phase = DayPhase.Phase.BUY
	EventBus.day_started.emit(current_day)


func set_phase(phase: DayPhase.Phase) -> void:
	current_phase = phase
	EventBus.phase_changed.emit(phase)
