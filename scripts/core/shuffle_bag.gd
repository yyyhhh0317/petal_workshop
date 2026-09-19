class_name ShuffleBag
extends RefCounted
## 洗牌袋：加权公平随机。袋中取尽才重新装袋，
## 避免 pick_random 带来的统计上不公平的连续重复。

var _items: Array = []
var _bag: Array = []
var _rng := RandomNumberGenerator.new()


func _init(p_rng: RandomNumberGenerator = null) -> void:
	if p_rng:
		_rng = p_rng
	else:
		_rng.randomize()


func add(item: Variant, weight: int) -> void:
	if weight <= 0:
		return
	_items.append({"item": item, "weight": weight})


func next() -> Variant:
	if _bag.is_empty():
		_refill()
	var idx := _rng.randi_range(0, _bag.size() - 1)
	var item = _bag[idx]
	_bag.remove_at(idx)
	return item


func _refill() -> void:
	_bag.clear()
	for entry in _items:
		for i in entry.weight:
			_bag.append(entry.item)
