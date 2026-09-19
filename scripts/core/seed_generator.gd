class_name SeedGenerator
extends RefCounted
## 种子与随机数管理：所有关键随机必须经由本类持有的局部 RNG，
## 禁止使用全局 randi() 保证同种子完全可复现。

var seed_value: int = 0
var _rng := RandomNumberGenerator.new()


func initialize(p_seed: int = 0) -> void:
	if p_seed == 0:
		seed_value = int(Time.get_unix_time_from_system()) & 0x7FFFFFFF
	else:
		seed_value = p_seed
	_rng.seed = seed_value


func roll_flower_pool(pool_size: int) -> Array[String]:
	## 从全部花材中随机抽取 pool_size 种作为本局花材池。
	var shuffled := _shuffle_array(FlowerDatabase.get_all_flowers())
	var ids: Array[String] = []
	var limit := mini(pool_size, shuffled.size())
	for i in limit:
		var f: FlowerData = shuffled[i]
		ids.append(f.id)
	return ids


func roll_int_range(min_value: int, max_value: int) -> int:
	return _rng.randi_range(min_value, max_value)


func pick_from(pool: Array) -> Variant:
	if pool.is_empty():
		return null
	return pool[_rng.randi_range(0, pool.size() - 1)]


func _shuffle_array(arr: Array) -> Array:
	var result := arr.duplicate()
	for i in range(result.size() - 1, 0, -1):
		var j := _rng.randi_range(0, i)
		var tmp = result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
