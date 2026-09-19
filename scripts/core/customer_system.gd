class_name CustomerSystem
extends RefCounted
## 顾客系统：顾客档案加载、顾客生成、偏好评分与挑选花束。
## 耐心规则：耐心 ≥ 4 的顾客购买阈值降到 0.2，其余为 0.3。

const CUSTOMER_DIR := "res://data/customers"
const MIN_SCORE_TO_BUY := 0.3
const PATIENT_MIN_SCORE := 0.2

static var _profiles: Array[CustomerProfile] = []


static func get_profiles() -> Array[CustomerProfile]:
	if _profiles.is_empty():
		_load_profiles()
	return _profiles


static func _load_profiles() -> void:
	var dir := DirAccess.open(CUSTOMER_DIR)
	if dir == null:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res: CustomerProfile = load(CUSTOMER_DIR + "/" + file_name)
			if res:
				_profiles.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()


func generate_customer(profile: CustomerProfile, rng: RandomNumberGenerator) -> Dictionary:
	return {
		"profile": profile,
		"budget": rng.randi_range(profile.budget_min, maxi(profile.budget_min, profile.budget_max)),
		"patience_left": profile.patience,
	}


func score_bouquet(customer: Dictionary, flowers: Array[FlowerData]) -> float:
	## 满意度 0.0-1.0：命中偏好标签加分，命中厌恶标签扣分。
	var profile: CustomerProfile = customer.profile
	if flowers.is_empty():
		return 0.0
	var score := 0.0
	for f in flowers:
		for tag in f.color_tags:
			if profile.preferred_tags.has(tag):
				score += 1.0
			if profile.disliked_tags.has(tag):
				score -= 1.0
	return clampf(score / flowers.size(), 0.0, 1.0)


func pick_bouquet(customer: Dictionary, slots: Array) -> int:
	## 返回得分最高且达到购买阈值的展示位索引；没有满意的返回 -1。
	var profile: CustomerProfile = customer.profile
	var threshold := PATIENT_MIN_SCORE if profile.patience >= 4 else MIN_SCORE_TO_BUY
	var best_index := -1
	var best_score := threshold
	for i in slots.size():
		var slot = slots[i]
		if slot.result == null:
			continue
		var flowers := _resolve_flowers(slot.bouquet)
		var s := score_bouquet(customer, flowers)
		if s > best_score:
			best_score = s
			best_index = i
	return best_index


func _resolve_flowers(ids: Array[String]) -> Array[FlowerData]:
	var result: Array[FlowerData] = []
	for id in ids:
		var f := FlowerDatabase.get_flower(id)
		if f:
			result.append(f)
	return result
