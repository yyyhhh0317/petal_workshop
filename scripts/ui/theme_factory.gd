class_name ThemeFactory
## 全局 UI 主题工厂：花店暖色主题、圆角控件、加大字号，代码构建避免资源依赖。

static func create() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 20

	# —— 调色板 ——
	var bg_color := Color("#f7f0df")        # 米白背景
	var panel_color := Color("#fffaf0")     # 面板
	var accent := Color("#3f7d54")          # 花店绿
	var accent_hover := Color("#55996b")
	var accent_pressed := Color("#2f5f40")
	var text_color := Color("#26352b")      # 深绿文字
	var subtle := Color("#6b7d70")

	theme.set_color("font_color", "Label", text_color)
	theme.set_color("font_color", "Button", Color("#ffffff"))
	theme.set_color("font_color", "RichTextLabel", text_color)
	theme.set_color("font_shadow_color", "Label", Color(1, 1, 1, 0.5))

	# —— 按钮 ——
	var btn := _stylebox(accent, 10)
	var btn_hover := _stylebox(accent_hover, 10)
	var btn_pressed := _stylebox(accent_pressed, 10)
	var btn_disabled := _stylebox(Color("#b9c4bc"), 10)
	theme.set_stylebox("normal", "Button", btn)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	theme.set_color("font_disabled_color", "Button", Color("#5c6a60"))
	theme.set_color("font_hover_color", "Button", Color("#ffffff"))

	# —— 面板 ——
	var panel := _stylebox(panel_color, 14)
	panel.content_margin_left = 16
	panel.content_margin_right = 16
	panel.content_margin_top = 12
	panel.content_margin_bottom = 12
	theme.set_stylebox("panel", "PanelContainer", panel)

	return theme


static func _stylebox(color: Color, radius: int) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_border_width_all(1)
	sb.border_color = Color(0, 0, 0, 0.08)
	return sb
