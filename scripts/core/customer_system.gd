class_name CustomerSystem
extends RefCounted
## 顾客系统：生成带预算与耐心的顾客，按偏好对花束评分。

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
