extends Control

const AudioLabScene := preload("res://scripts/audio_lab.gd")

var audio_lab: AudioLab
var pulse: float = 0.0
var start_button: Button


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	audio_lab = AudioLabScene.new()
	add_child(audio_lab)
	_build_ui()
	queue_redraw()


func _process(delta: float) -> void:
	pulse += delta
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.06, 0.08))
	draw_rect(Rect2(0.0, 0.0, size.x * 0.56, size.y), Color(0.07, 0.08, 0.11))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, 0.0),
		Vector2(size.x * 0.42, 0.0),
		Vector2(size.x * 0.58, size.y),
		Vector2(0.0, size.y),
	]), Color(0.08, 0.09, 0.12, 0.92))

	var glow_alpha: float = 0.06 + sin(pulse * 1.2) * 0.015
	draw_circle(Vector2(220.0, 160.0), 190.0, Color(1.0, 0.39, 0.23, glow_alpha))
	draw_circle(Vector2(560.0, 850.0), 260.0, Color(0.22, 0.78, 0.62, 0.055))
	draw_circle(Vector2(size.x * 0.84, 170.0), 150.0, Color(1.0, 0.43, 0.29, 0.05))

	var road_rect := Rect2(size.x * 0.68, -32.0, size.x * 0.18, size.y + 64.0)
	draw_rect(road_rect, Color(0.2, 0.22, 0.27))
	draw_rect(Rect2(road_rect.position.x - 24.0, road_rect.position.y, 24.0, road_rect.size.y), Color(0.53, 0.5, 0.46))
	draw_rect(Rect2(road_rect.end.x, road_rect.position.y, 24.0, road_rect.size.y), Color(0.53, 0.5, 0.46))

	for index in range(12):
		var y_pos: float = fmod(float(index) * 124.0 + pulse * 240.0, size.y + 210.0) - 105.0
		draw_rect(Rect2(road_rect.position.x + road_rect.size.x * 0.5 - 7.0, y_pos, 14.0, 72.0), Color(0.99, 0.96, 0.82))

	for index in range(6):
		var tail_y := fmod(float(index) * 182.0 + pulse * 360.0, size.y + 140.0) - 70.0
		draw_rect(Rect2(road_rect.position.x + 42.0, tail_y, 12.0, 38.0), Color(1.0, 0.46, 0.31, 0.75))
		draw_rect(Rect2(road_rect.end.x - 54.0, size.y - tail_y - 38.0, 12.0, 38.0), Color(0.46, 0.78, 1.0, 0.72))


func _build_ui() -> void:
	var kicker := _make_label(Vector2(124.0, 96.0), Vector2(460.0, 24.0), 20, "URBAN PRESSURE / RELIEF MODE", Color(1.0, 0.63, 0.48))
	add_child(kicker)

	var title := _make_label(Vector2(118.0, 124.0), Vector2(760.0, 210.0), 96, "Road Rage\nRelief", Color(0.97, 0.97, 0.97))
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_child(title)

	var subtitle := _make_label(Vector2(126.0, 336.0), Vector2(620.0, 118.0), 30, "穿过高压拥堵路段，在秩序与失控之间自己选一种通关方式。", Color(0.87, 0.89, 0.92))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(subtitle)

	var pill_rules := _make_pill(Vector2(126.0, 474.0), Vector2(150.0, 40.0), "守规则", Color(0.12, 0.28, 0.22), Color(0.33, 0.88, 0.6))
	add_child(pill_rules)
	var pill_chaos := _make_pill(Vector2(292.0, 474.0), Vector2(166.0, 40.0), "混乱释放", Color(0.32, 0.15, 0.13), Color(1.0, 0.56, 0.38))
	add_child(pill_chaos)

	var summary_panel := Panel.new()
	summary_panel.position = Vector2(126.0, 568.0)
	summary_panel.size = Vector2(520.0, 170.0)
	summary_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.11, 0.15, 0.88), Color(0.27, 0.33, 0.4), 30))
	add_child(summary_panel)

	summary_panel.add_child(_make_label(Vector2(34.0, 28.0), Vector2(220.0, 20.0), 16, "游戏体验", Color(0.46, 0.74, 1.0)))
	var summary_body := _make_label(Vector2(34.0, 58.0), Vector2(430.0, 84.0), 24, "更像穿越一段糟糕通勤，而不是一场单纯竞速。", Color(0.96, 0.97, 0.98))
	summary_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_panel.add_child(summary_body)
	summary_panel.add_child(_make_label(Vector2(34.0, 132.0), Vector2(420.0, 20.0), 18, "绿灯通行，红灯止步，情绪失控也会被系统记录。", Color(0.74, 0.79, 0.85)))

	var panel := Panel.new()
	panel.position = Vector2(1118.0, 122.0)
	panel.size = Vector2(598.0, 826.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.09, 0.11, 0.15, 0.95), Color(0.33, 0.39, 0.47), 30))
	add_child(panel)

	panel.add_child(_make_label(Vector2(42.0, 34.0), Vector2(220.0, 18.0), 16, "READY TO DRIVE", Color(1.0, 0.63, 0.48)))
	panel.add_child(_make_label(Vector2(42.0, 60.0), Vector2(260.0, 38.0), 38, "准备上路", Color(0.98, 0.98, 0.98)))

	var panel_subtitle := _make_label(Vector2(42.0, 112.0), Vector2(500.0, 64.0), 22, "保住秩序分，或者把怒气直接撞成夸张反馈。", Color(0.74, 0.79, 0.85))
	panel_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(panel_subtitle)

	panel.add_child(_make_feature_row(Vector2(36.0, 208.0), Vector2(526.0, 92.0), "01", "穿过拥堵主路", "AI 车流、行人、电动车和违停会持续压缩走位空间。", Color(0.33, 0.88, 0.62)))
	panel.add_child(_make_feature_row(Vector2(36.0, 318.0), Vector2(526.0, 92.0), "02", "双分数并行", "守规则拿稳态评价，冲撞障碍把整段路变成失控秀。", Color(1.0, 0.57, 0.38)))
	panel.add_child(_make_feature_row(Vector2(36.0, 428.0), Vector2(526.0, 92.0), "03", "反馈更狠", "程序化音效、粒子和镜头震动会把每次碰撞都拉满。", Color(0.46, 0.74, 1.0)))

	start_button = Button.new()
	start_button.position = Vector2(36.0, 572.0)
	start_button.size = Vector2(526.0, 70.0)
	start_button.text = "开始上路"
	start_button.add_theme_font_size_override("font_size", 32)
	start_button.add_theme_stylebox_override("normal", _button_style(Color(0.96, 0.34, 0.21), Color(1.0, 0.88, 0.7), 24))
	start_button.add_theme_stylebox_override("hover", _button_style(Color(1.0, 0.43, 0.24), Color(1.0, 0.94, 0.78), 24))
	start_button.add_theme_stylebox_override("pressed", _button_style(Color(0.82, 0.22, 0.14), Color(1.0, 0.8, 0.54), 24))
	start_button.pressed.connect(_on_start_pressed)
	panel.add_child(start_button)

	var quit_button := Button.new()
	quit_button.position = Vector2(36.0, 658.0)
	quit_button.size = Vector2(526.0, 58.0)
	quit_button.text = "退出"
	quit_button.add_theme_font_size_override("font_size", 28)
	quit_button.add_theme_stylebox_override("normal", _button_style(Color(0.15, 0.18, 0.23), Color(0.37, 0.43, 0.51), 22))
	quit_button.add_theme_stylebox_override("hover", _button_style(Color(0.2, 0.24, 0.29), Color(0.45, 0.51, 0.59), 22))
	quit_button.add_theme_stylebox_override("pressed", _button_style(Color(0.11, 0.14, 0.18), Color(0.33, 0.38, 0.46), 22))
	quit_button.pressed.connect(_on_quit_pressed)
	panel.add_child(quit_button)

	var hint_panel := Panel.new()
	hint_panel.position = Vector2(36.0, 728.0)
	hint_panel.size = Vector2(526.0, 86.0)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.11, 0.13, 0.17, 0.9), Color(0.24, 0.29, 0.36), 22))
	panel.add_child(hint_panel)
	hint_panel.add_child(_make_label(Vector2(22.0, 16.0), Vector2(200.0, 18.0), 15, "控制方式", Color(0.46, 0.74, 1.0)))
	hint_panel.add_child(_make_label(Vector2(22.0, 38.0), Vector2(244.0, 24.0), 20, "方向键 / WASD", Color(0.96, 0.97, 0.98)))
	hint_panel.add_child(_make_label(Vector2(288.0, 40.0), Vector2(210.0, 22.0), 18, "R 重开   Esc 菜单", Color(0.74, 0.79, 0.85)))

	start_button.grab_focus()


func _panel_style(fill: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.content_margin_left = 16.0
	style.content_margin_top = 14.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 14.0
	return style


func _button_style(fill: Color, border: Color, radius: int = 18) -> StyleBoxFlat:
	var style := _panel_style(fill, border, radius)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.24)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	return style


func _make_label(pos: Vector2, label_size: Vector2, font_size: int, text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.text = text_value
	return label


func _make_pill(pos: Vector2, pill_size: Vector2, text_value: String, fill: Color, border: Color) -> Panel:
	var pill := Panel.new()
	pill.position = pos
	pill.size = pill_size
	pill.add_theme_stylebox_override("panel", _panel_style(fill, border, 17))
	var label := _make_label(Vector2(16.0, 5.0), Vector2(pill_size.x - 32.0, 24.0), 18, text_value, Color(0.97, 0.97, 0.97))
	pill.add_child(label)
	return pill


func _make_feature_row(pos: Vector2, card_size: Vector2, index_text: String, title_text: String, body_text: String, accent: Color) -> Panel:
	var card := Panel.new()
	card.position = pos
	card.size = card_size
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.13, 0.15, 0.2, 0.96), Color(0.27, 0.33, 0.41), 18))

	var accent_bar := ColorRect.new()
	accent_bar.position = Vector2(18.0, 16.0)
	accent_bar.size = Vector2(5.0, card_size.y - 32.0)
	accent_bar.color = accent
	card.add_child(accent_bar)

	card.add_child(_make_label(Vector2(42.0, 12.0), Vector2(44.0, 24.0), 18, index_text, accent))
	card.add_child(_make_label(Vector2(94.0, 10.0), Vector2(240.0, 26.0), 24, title_text, Color(0.97, 0.97, 0.97)))

	var body := _make_label(Vector2(94.0, 40.0), Vector2(card_size.x - 126.0, 36.0), 17, body_text, Color(0.74, 0.79, 0.85))
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(body)
	return card


func _on_start_pressed() -> void:
	audio_lab.play_menu_confirm()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	audio_lab.play_menu_confirm()
	get_tree().quit()
