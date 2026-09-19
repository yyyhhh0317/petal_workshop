class_name EventSystem
extends RefCounted
## 每日事件系统：ShuffleBag 加权抽取事件，聚合当日流行趋势。

var active_events: Array[DailyEvent] = []
var trend_tags: Array[String] = []


func roll_daily_event(rng: RandomNumberGenerator, pool: Array[DailyEvent]) -> DailyEvent:
	var bag := ShuffleBag.new(rng)
	for e in pool:
		bag.add(e, e.weight)
	var rolled: DailyEvent = bag.next()
	active_events.append(rolled)
	_refresh_trends()
	EventBus.day_event_rolled.emit(rolled)
	return rolled


func apply_cost_multiplier(base_cost: int) -> int:
	var m := 1.0
	for e in active_events:
		m *= e.cost_multiplier
	return int(round(base_cost * m))


func apply_value_multiplier(base_value: int) -> int:
	var m := 1.0
	for e in active_events:
		m *= e.value_multiplier
	return int(round(base_value * m))


func _refresh_trends() -> void:
	trend_tags.clear()
	for e in active_events:
		trend_tags.append_array(e.affected_tags)
