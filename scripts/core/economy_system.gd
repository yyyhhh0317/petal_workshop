class_name EconomySystem
extends RefCounted
## 资金流转：进货成本、营业收入与每日结算。

var money: int = 0
var daily_cost: int = 0
var daily_revenue: int = 0


func _init(start_money: int = 0) -> void:
	money = start_money


func can_afford(amount: int) -> bool:
	return money >= amount


func spend(amount: int) -> bool:
	if amount < 0 or not can_afford(amount):
		return false
	money -= amount
	daily_cost += amount
	EventBus.money_changed.emit(money)
	return true


func earn(amount: int) -> void:
	if amount <= 0:
		return
	money += amount
	daily_revenue += amount
	EventBus.money_changed.emit(money)


func end_day() -> Dictionary:
	## 结算当日收支并清零，返回明细。
	var profit := daily_revenue - daily_cost
	var result := {
		"revenue": daily_revenue,
		"cost": daily_cost,
		"profit": profit,
		"money": money,
	}
	daily_revenue = 0
	daily_cost = 0
	return result
