class_name CustomerProfile
extends Resource
## 顾客类型定义：偏好、预算、耐心与故事提示。

@export var id: String = ""
@export var display_name: String = ""
@export var preferred_tags: Array[String] = []
@export var disliked_tags: Array[String] = []
@export var budget_min: int = 0
@export var budget_max: int = 0
@export var patience: int = 3
@export var story_hint: String = ""
