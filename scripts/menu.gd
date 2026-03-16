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
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.07, 0.08, 0.11))

	var road_rect := Rect2(size.x * 0.54, -40.0, size.x * 0.28, size.y + 80.0)
	draw_rect(road_rect, Color(0.17, 0.18, 0.22))
	draw_rect(Rect2(road_rect.position.x - 24.0, road_rect.position.y, 24.0, road_rect.size.y), Color(0.48, 0.45, 0.42))
	draw_rect(Rect2(road_rect.end.x, road_rect.position.y, 24.0, road_rect.size.y), Color(0.48, 0.45, 0.42))

	for index in range(12):
		var y_pos: float = fmod(float(index) * 96.0 + pulse * 140.0, size.y + 120.0) - 60.0
		draw_rect(Rect2(road_rect.position.x + road_rect.size.x * 0.5 - 6.0, y_pos, 12.0, 54.0), Color(0.96, 0.93, 0.78))

	draw_circle(Vector2(size.x * 0.82, 120.0), 110.0, Color(0.96, 0.44, 0.27, 0.08))
	draw_circle(Vector2(size.x * 0.88, 560.0), 150.0, Color(0.24, 0.82, 0.63, 0.06))


func _build_ui() -> void:
	var title := Label.new()
	title.position = Vector2(86.0, 84.0)
	title.size = Vector2(520.0, 80.0)
	title.add_theme_font_size_override("font_size", 54)
	title.text = "Road Rage Relief"
	add_child(title)

	var subtitle := Label.new()
	subtitle.position = Vector2(92.0, 150.0)
	subtitle.size = Vector2(520.0, 90.0)
	subtitle.add_theme_font_size_override("font_size", 24)
	subtitle.text = "在拥堵城市道路里守规则，或者把怒气直接撞成混乱。"
	add_child(subtitle)

	var panel := Panel.new()
	panel.position = Vector2(82.0, 242.0)
	panel.size = Vector2(470.0, 292.0)
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.1, 0.12, 0.16, 0.88), Color(0.35, 0.38, 0.44)))
	add_child(panel)

	var panel_text := Label.new()
	panel_text.position = Vector2(28.0, 24.0)
	panel_text.size = Vector2(414.0, 210.0)
	panel_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel_text.add_theme_font_size_override("font_size", 20)
	panel_text.text = "玩法内容\n\n1. 驾驶车辆穿过红绿灯、违停带、穿行电动车和散漫行人。\n2. 守规则分奖励稳健驾驶，混乱分奖励夸张冲撞。\n3. 新增 AI 机动车流、碰撞粒子、程序化音效与更强碰撞反馈。"
	panel.add_child(panel_text)

	start_button = Button.new()
	start_button.position = Vector2(28.0, 222.0)
	start_button.size = Vector2(180.0, 42.0)
	start_button.text = "开始上路"
	start_button.add_theme_font_size_override("font_size", 22)
	start_button.add_theme_stylebox_override("normal", _panel_style(Color(0.95, 0.31, 0.2), Color(1.0, 0.84, 0.62)))
	start_button.add_theme_stylebox_override("hover", _panel_style(Color(1.0, 0.42, 0.24), Color(1.0, 0.9, 0.7)))
	start_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.82, 0.22, 0.15), Color(1.0, 0.82, 0.55)))
	start_button.pressed.connect(_on_start_pressed)
	panel.add_child(start_button)

	var quit_button := Button.new()
	quit_button.position = Vector2(226.0, 222.0)
	quit_button.size = Vector2(130.0, 42.0)
	quit_button.text = "退出"
	quit_button.add_theme_font_size_override("font_size", 22)
	quit_button.add_theme_stylebox_override("normal", _panel_style(Color(0.18, 0.21, 0.26), Color(0.4, 0.44, 0.5)))
	quit_button.add_theme_stylebox_override("hover", _panel_style(Color(0.24, 0.28, 0.33), Color(0.48, 0.54, 0.6)))
	quit_button.add_theme_stylebox_override("pressed", _panel_style(Color(0.13, 0.15, 0.19), Color(0.34, 0.38, 0.44)))
	quit_button.pressed.connect(_on_quit_pressed)
	panel.add_child(quit_button)

	var hint := Label.new()
	hint.position = Vector2(92.0, 570.0)
	hint.size = Vector2(540.0, 60.0)
	hint.add_theme_font_size_override("font_size", 18)
	hint.text = "方向键 / WASD 驾驶   R 重开   Esc 回菜单"
	add_child(hint)

	start_button.grab_focus()


func _panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_right = 18
	style.corner_radius_bottom_left = 18
	style.content_margin_left = 16.0
	style.content_margin_top = 14.0
	style.content_margin_right = 16.0
	style.content_margin_bottom = 14.0
	return style


func _on_start_pressed() -> void:
	audio_lab.play_menu_confirm()
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_quit_pressed() -> void:
	audio_lab.play_menu_confirm()
	get_tree().quit()
