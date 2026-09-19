extends Node
## 全局事件总线（Autoload）：跨系统信号通信，系统间零硬引用。
## 规范：只发信号，不写业务逻辑；发射方不需要知道监听方是谁。

signal run_started(seed_value: int)
signal run_ended(victory: bool, stats: Dictionary)
signal day_started(day_number: int)
signal day_ended(revenue: int, costs: int)
signal phase_changed(phase: DayPhase.Phase)
signal combo_calculated(result: ComboResult)
signal customer_served(satisfaction: float, payment: int)
signal meta_unlocked(unlock_id: String)
signal money_changed(money: int)
signal day_event_rolled(event: DailyEvent)
signal inventory_changed
signal bouquet_changed
signal display_changed
