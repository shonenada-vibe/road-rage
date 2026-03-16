extends Node2D

const PlayerCarScene := preload("res://scripts/player_car.gd")
const TrafficActorScene := preload("res://scripts/traffic_actor.gd")
const TrafficLightScene := preload("res://scripts/traffic_light.gd")
const AIVehicleScene := preload("res://scripts/ai_vehicle.gd")
const AudioLabScene := preload("res://scripts/audio_lab.gd")
const FxManagerScene := preload("res://scripts/fx_manager.gd")

const WORLD_LENGTH: float = 4200.0
const ROAD_HALF_WIDTH: float = 360.0
const SIDEWALK_HALF_WIDTH: float = 560.0
const SPEED_LIMIT: float = 680.0
const DESTINATION_Y: float = -3880.0
const ROAD_BOTTOM_Y: float = 1600.0
const TRAFFIC_LANES: Array = [-250.0, -85.0, 85.0, 250.0]
const AI_CAR_TARGET: int = 14

var player: PlayerCar
var camera: Camera2D
var speed_value_label: Label
var traffic_value_label: Label
var rule_value_label: Label
var chaos_value_label: Label
var progress_value_label: Label
var status_value_label: Label
var status_title_label: Label
var distance_value_label: Label
var progress_fill: ColorRect
var status_panel: Panel
var status_accent: ColorRect
var finish_label: Label
var finish_panel: Panel
var audio_lab: AudioLab
var fx_manager: FxManager

var rule_score: float = 100.0
var chaos_score: float = 0.0
var status_text: String = "平稳起步，保持在车道内。"
var status_timer: float = 3.0
var shake_strength: float = 0.0
var finished: bool = false
var finished_fx_played: bool = false
var traffic_spawn_timer: float = 0.0
var skid_fx_timer: float = 0.0
var total_distance_to_goal: float = 1.0

var traffic_lights: Array = []
var light_crossed: Dictionary = {}
var ai_traffic: Array = []


func _ready() -> void:
	randomize()
	audio_lab = AudioLabScene.new()
	add_child(audio_lab)
	fx_manager = FxManagerScene.new()
	add_child(fx_manager)
	_create_player()
	_create_lights()
	_create_obstacles()
	_create_camera()
	_create_hud()
	_seed_ai_traffic()
	_update_hud()
	audio_lab.start_gameplay_audio()
	queue_redraw()


func _create_player() -> void:
	player = PlayerCarScene.new()
	player.global_position = Vector2(110.0, 240.0)
	player.set_drive_bounds(ROAD_HALF_WIDTH, SIDEWALK_HALF_WIDTH)
	player.traffic_hit.connect(_on_player_traffic_hit)
	add_child(player)
	total_distance_to_goal = maxf(1.0, player.global_position.y - DESTINATION_Y)


func _create_lights() -> void:
	var light_rows := [-700.0, -1760.0, -2940.0]
	for row in light_rows:
		var left_light: TrafficLight = TrafficLightScene.new(randf_range(0.0, 5.0))
		left_light.position = Vector2(-SIDEWALK_HALF_WIDTH + 86.0, row)
		add_child(left_light)
		traffic_lights.append(left_light)
		light_crossed[left_light] = false

		var right_light: TrafficLight = TrafficLightScene.new(randf_range(0.0, 5.0))
		right_light.position = Vector2(SIDEWALK_HALF_WIDTH - 86.0, row)
		add_child(right_light)


func _create_obstacles() -> void:
	var parked_layout := [
		Vector2(-ROAD_HALF_WIDTH + 42.0, -320.0),
		Vector2(ROAD_HALF_WIDTH - 42.0, -620.0),
		Vector2(-ROAD_HALF_WIDTH + 42.0, -1140.0),
		Vector2(ROAD_HALF_WIDTH - 42.0, -1470.0),
		Vector2(-ROAD_HALF_WIDTH + 42.0, -2010.0),
		Vector2(ROAD_HALF_WIDTH - 42.0, -2480.0),
		Vector2(-ROAD_HALF_WIDTH + 42.0, -3190.0),
		Vector2(ROAD_HALF_WIDTH - 42.0, -3470.0),
	]

	for spawn in parked_layout:
		var parked := TrafficActorScene.new("parked_car")
		parked.setup_spawn(spawn, -ROAD_HALF_WIDTH, ROAD_HALF_WIDTH)
		add_child(parked)

	for index in range(11):
		var ped := TrafficActorScene.new("pedestrian")
		var y_pos := -380.0 - index * 290.0 + randf_range(-60.0, 60.0)
		var start_from_left := index % 2 == 0
		var start_x := -ROAD_HALF_WIDTH - 110.0 if start_from_left else ROAD_HALF_WIDTH + 110.0
		var dir := 1.0 if start_from_left else -1.0
		ped.setup_spawn(Vector2(start_x, y_pos), -ROAD_HALF_WIDTH - 60.0, ROAD_HALF_WIDTH + 60.0, dir)
		add_child(ped)

	for index in range(8):
		var scooter := TrafficActorScene.new("scooter")
		var lane_x := randf_range(-ROAD_HALF_WIDTH + 90.0, ROAD_HALF_WIDTH - 90.0)
		var y_pos := -620.0 - index * 410.0 + randf_range(-80.0, 80.0)
		var dir := 1.0 if index % 3 == 0 else -1.0
		scooter.setup_spawn(Vector2(lane_x, y_pos), -ROAD_HALF_WIDTH + 46.0, ROAD_HALF_WIDTH - 46.0, dir)
		add_child(scooter)


func _seed_ai_traffic() -> void:
	for index in range(8):
		_attempt_spawn_ai_vehicle(index < 5)


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	camera.zoom = Vector2(0.66, 0.66)
	player.add_child(camera)


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var speed_panel := Panel.new()
	speed_panel.position = Vector2(42.0, 34.0)
	speed_panel.size = Vector2(434.0, 140.0)
	speed_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.92), Color(0.23, 0.28, 0.34), 30))
	layer.add_child(speed_panel)

	var speed_glow := ColorRect.new()
	speed_glow.position = Vector2(20.0, 20.0)
	speed_glow.size = Vector2(6.0, 100.0)
	speed_glow.color = Color(1.0, 0.45, 0.29, 0.96)
	speed_panel.add_child(speed_glow)

	speed_panel.add_child(_make_ui_label(Vector2(42.0, 18.0), Vector2(220.0, 18.0), 15, "LIVE DRIVE", Color(1.0, 0.65, 0.49)))
	speed_panel.add_child(_make_ui_label(Vector2(42.0, 38.0), Vector2(180.0, 22.0), 18, "当前速度", Color(0.73, 0.78, 0.86)))

	speed_value_label = _make_ui_label(Vector2(42.0, 56.0), Vector2(220.0, 54.0), 44, "0 km/h", Color(0.98, 0.98, 0.98))
	speed_panel.add_child(speed_value_label)
	traffic_value_label = _make_ui_label(Vector2(42.0, 108.0), Vector2(280.0, 22.0), 18, "0 辆 AI 车流正在附近移动", Color(0.86, 0.89, 0.94))
	speed_panel.add_child(traffic_value_label)

	var route_panel := Panel.new()
	route_panel.position = Vector2(526.0, 34.0)
	route_panel.size = Vector2(842.0, 96.0)
	route_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.88), Color(0.21, 0.26, 0.32), 30))
	layer.add_child(route_panel)

	route_panel.add_child(_make_ui_label(Vector2(28.0, 18.0), Vector2(240.0, 18.0), 15, "ROUTE PROGRESS", Color(0.46, 0.76, 1.0)))
	progress_value_label = _make_ui_label(Vector2(664.0, 18.0), Vector2(140.0, 18.0), 16, "进度 0%", Color(0.85, 0.9, 0.96))
	progress_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	route_panel.add_child(progress_value_label)

	var progress_track := ColorRect.new()
	progress_track.position = Vector2(28.0, 46.0)
	progress_track.size = Vector2(786.0, 12.0)
	progress_track.color = Color(0.18, 0.22, 0.27, 1.0)
	route_panel.add_child(progress_track)

	progress_fill = ColorRect.new()
	progress_fill.position = Vector2.ZERO
	progress_fill.size = Vector2(0.0, 12.0)
	progress_fill.color = Color(1.0, 0.45, 0.29, 0.96)
	progress_track.add_child(progress_fill)

	distance_value_label = _make_ui_label(Vector2(28.0, 66.0), Vector2(460.0, 20.0), 18, "目的地还很远", Color(0.9, 0.93, 0.97))
	route_panel.add_child(distance_value_label)

	rule_value_label = _make_stat_card(layer, Vector2(1414.0, 34.0), Vector2(206.0, 96.0), "守规则", Color(0.33, 0.88, 0.62))
	chaos_value_label = _make_stat_card(layer, Vector2(1640.0, 34.0), Vector2(206.0, 96.0), "混乱值", Color(1.0, 0.57, 0.38))

	status_panel = Panel.new()
	status_panel.position = Vector2(42.0, 916.0)
	status_panel.size = Vector2(600.0, 104.0)
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.9), Color(0.21, 0.26, 0.32), 28))
	layer.add_child(status_panel)

	status_accent = ColorRect.new()
	status_accent.position = Vector2(20.0, 18.0)
	status_accent.size = Vector2(5.0, 68.0)
	status_accent.color = Color(0.46, 0.74, 1.0, 0.95)
	status_panel.add_child(status_accent)

	status_title_label = _make_ui_label(Vector2(42.0, 18.0), Vector2(180.0, 18.0), 15, "路况提示", Color(0.46, 0.74, 1.0))
	status_panel.add_child(status_title_label)
	status_value_label = _make_ui_label(Vector2(42.0, 40.0), Vector2(528.0, 42.0), 22, "", Color(0.97, 0.97, 0.98))
	status_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	status_value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_panel.add_child(status_value_label)

	var hint_panel := Panel.new()
	hint_panel.position = Vector2(1322.0, 952.0)
	hint_panel.size = Vector2(556.0, 54.0)
	hint_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.76), Color(0.19, 0.23, 0.29), 24))
	layer.add_child(hint_panel)
	var hint_label := _make_ui_label(Vector2(22.0, 14.0), Vector2(510.0, 22.0), 17, "WASD / 方向键驾驶   R 重开   Esc 菜单", Color(0.86, 0.9, 0.95))
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_panel.add_child(hint_label)

	finish_panel = Panel.new()
	finish_panel.position = Vector2(600.0, 232.0)
	finish_panel.size = Vector2(720.0, 286.0)
	finish_panel.visible = false
	finish_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.07, 0.09, 0.12, 0.95), Color(0.36, 0.41, 0.49), 34))
	layer.add_child(finish_panel)
	finish_panel.add_child(_make_ui_label(Vector2(38.0, 28.0), Vector2(220.0, 20.0), 16, "RUN COMPLETE", Color(1.0, 0.63, 0.48)))
	finish_panel.add_child(_make_ui_label(Vector2(38.0, 54.0), Vector2(280.0, 36.0), 34, "旅程完成", Color(0.98, 0.98, 0.98)))

	finish_label = _make_ui_label(Vector2(38.0, 102.0), Vector2(644.0, 150.0), 27, "", Color(0.97, 0.97, 0.97))
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	finish_panel.add_child(finish_label)


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		return
	if Input.is_key_pressed(KEY_ESCAPE):
		get_tree().change_scene_to_file("res://scenes/menu.tscn")
		return

	if finished:
		_update_finish_text()
		_update_camera(delta)
		audio_lab.stop_gameplay_audio()
		if not finished_fx_played:
			finished_fx_played = true
			fx_manager.spawn_finish(player.global_position + Vector2(0.0, -150.0))
			audio_lab.play_finish()
		return

	status_timer = maxf(0.0, status_timer - delta)
	if status_timer <= 0.0:
		status_text = "在拥堵中控住节奏，或者把怒气转成混乱分。"

	_maintain_ai_traffic(delta)
	_apply_rule_checks(delta)
	_spawn_drive_fx(delta)
	_update_hud()
	_update_camera(delta)
	audio_lab.update_engine(player.speed_ratio(), player.skid_ratio())

	if player.global_position.y <= DESTINATION_Y:
		finished = true
		player.set_finished()
		status_text = "到达终点。按 R 可以立刻再跑一趟。"
		status_timer = 999.0
		finish_panel.visible = true


func _apply_rule_checks(delta: float) -> void:
	if player.speed_units() > SPEED_LIMIT:
		rule_score = maxf(0.0, rule_score - 7.5 * delta)
		status_text = "你超速了，守规则分正在下降。"
		status_timer = 0.6

	if player.is_on_sidewalk():
		rule_score = maxf(0.0, rule_score - 13.0 * delta)
		status_text = "你压上了非机动车道/人行区域。"
		status_timer = 0.4

	for light_ref in traffic_lights:
		var light: TrafficLight = light_ref
		if light_crossed.get(light, false):
			continue

		if player.crossed_line(light.stop_line_y()):
			light_crossed[light] = true
			if light.is_red():
				rule_score = maxf(0.0, rule_score - 24.0)
				status_text = "红灯强行通过，守规则分大幅下降。"
				status_timer = 2.0
			else:
				rule_score = minf(100.0, rule_score + 4.0)
				status_text = "绿灯通过，节奏不错。"
				status_timer = 1.4


func _maintain_ai_traffic(delta: float) -> void:
	traffic_spawn_timer = maxf(0.0, traffic_spawn_timer - delta)
	var kept: Array = []

	for vehicle_ref in ai_traffic:
		if vehicle_ref == null or not is_instance_valid(vehicle_ref):
			continue

		var vehicle: AIVehicle = vehicle_ref
		if abs(vehicle.global_position.y - player.global_position.y) > 2600.0:
			vehicle.queue_free()
			continue
		kept.append(vehicle)

	ai_traffic = kept

	if ai_traffic.size() >= AI_CAR_TARGET or traffic_spawn_timer > 0.0:
		return

	if _attempt_spawn_ai_vehicle(false):
		traffic_spawn_timer = randf_range(0.14, 0.34)
	else:
		traffic_spawn_timer = 0.12


func _attempt_spawn_ai_vehicle(seed_front_only: bool) -> bool:
	var lane_x: float = float(TRAFFIC_LANES[randi() % TRAFFIC_LANES.size()])
	var direction_y: float = -1.0 if lane_x > 0.0 else 1.0
	var spawn_y: float = player.global_position.y - randf_range(650.0, 2100.0)

	if direction_y < 0.0 and not seed_front_only and randf() < 0.28:
		spawn_y = player.global_position.y + randf_range(700.0, 1400.0)

	var spawn_pos: Vector2 = Vector2(lane_x, spawn_y)

	if abs(player.global_position.x - lane_x) < 80.0 and abs(player.global_position.y - spawn_y) < 340.0:
		return false

	for vehicle_ref in ai_traffic:
		if vehicle_ref == null or not is_instance_valid(vehicle_ref):
			continue
		var vehicle: AIVehicle = vehicle_ref
		if abs(vehicle.lane_center_x - lane_x) < 8.0 and abs(vehicle.global_position.y - spawn_y) < 320.0:
			return false

	var styles: Array = ["sedan", "taxi", "blue", "delivery"]
	var style_name: String = String(styles[randi() % styles.size()])
	var vehicle: AIVehicle = AIVehicleScene.new(style_name)
	vehicle.setup_spawn(spawn_pos, lane_x, direction_y, traffic_lights, ROAD_HALF_WIDTH, SIDEWALK_HALF_WIDTH)
	add_child(vehicle)
	ai_traffic.append(vehicle)
	return true


func _spawn_drive_fx(delta: float) -> void:
	skid_fx_timer = maxf(0.0, skid_fx_timer - delta)
	if skid_fx_timer > 0.0:
		return

	if player.skid_ratio() < 0.45 and not player.is_on_sidewalk():
		return

	if player.speed_units() < 260.0:
		return

	var drift_direction := Vector2(-player.side_speed, 90.0)
	fx_manager.spawn_skid(player.global_position + Vector2(0.0, 32.0), drift_direction, 0.65 + player.skid_ratio() * 0.5)
	skid_fx_timer = 0.06


func _update_hud() -> void:
	var distance_left := maxf(0.0, player.global_position.y - DESTINATION_Y)
	var progress := clampf(1.0 - distance_left / total_distance_to_goal, 0.0, 1.0)
	speed_value_label.text = "%d km/h" % player.speed_kph()
	traffic_value_label.text = "%d 辆 AI 车流正在附近移动" % ai_traffic.size()
	rule_value_label.text = "%.0f / 100" % rule_score
	chaos_value_label.text = "%.0f" % chaos_score
	progress_value_label.text = "进度 %d%%" % int(round(progress * 100.0))
	progress_fill.size.x = 786.0 * progress
	distance_value_label.text = "距离目的地 %.0f m，稳住节奏继续推进。" % (distance_left / 7.5)

	var status_color := Color(0.46, 0.74, 1.0, 0.95)
	var status_title := "路况平稳"
	if player.speed_units() > SPEED_LIMIT:
		status_title = "超速警告"
		status_color = Color(1.0, 0.68, 0.34, 0.95)
		status_value_label.text = "你已超速，收一收节奏。"
	elif player.is_on_sidewalk():
		status_title = "路线偏离"
		status_color = Color(1.0, 0.58, 0.38, 0.95)
		status_value_label.text = "回到机动车道，别压人行区域。"
	else:
		status_value_label.text = status_text
		if finished:
			status_title = "已抵达"
			status_color = Color(0.33, 0.88, 0.62, 0.95)

	status_title_label.text = status_title
	status_title_label.modulate = status_color
	status_accent.color = status_color
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.9), Color(status_color.r, status_color.g, status_color.b, 0.36), 28))


func _update_finish_text() -> void:
	var style := "克制通关"
	if chaos_score >= 180.0 and rule_score < 45.0:
		style = "彻底路怒通关"
	elif chaos_score >= 90.0:
		style = "高压释放通关"
	elif rule_score >= 75.0:
		style = "规则模范通关"

	finish_label.text = "已抵达目的地\n守规则 %.0f / 100\n混乱 %.0f\n评价：%s\n按 R 重新开始，或 Esc 返回菜单" % [
		rule_score,
		chaos_score,
		style,
	]


func _update_camera(delta: float) -> void:
	shake_strength = maxf(0.0, shake_strength - 18.0 * delta)
	if shake_strength > 0.0:
		camera.offset = Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength))
	else:
		camera.offset = camera.offset.lerp(Vector2.ZERO, 10.0 * delta)


func _on_player_traffic_hit(kind: String, chaos_gain: float, impact_force: float, impact_position: Vector2, impact_vector: Vector2) -> void:
	chaos_score += chaos_gain
	shake_strength = minf(22.0, shake_strength + impact_force * 0.016)
	audio_lab.play_collision(impact_position, impact_force)

	var tint := Color(1.0, 0.78, 0.28)
	match kind:
		"pedestrian":
			status_text = "行人被夸张地撞飞了。"
		"scooter":
			status_text = "电动车在空中翻滚出去。"
		"parked_car":
			status_text = "违停车辆被你顶得横着滑开。"
			tint = Color(0.98, 0.78, 0.25)
		"traffic_car":
			status_text = "AI 机动车流被你撞出了连锁失控。"
			rule_score = maxf(0.0, rule_score - 8.0)
			tint = Color(1.0, 0.42, 0.26)
		_:
			status_text = "碰撞制造了新的混乱。"
	fx_manager.spawn_impact(impact_position, impact_vector, clampf(impact_force / 520.0, 0.5, 1.35), tint)
	status_timer = 1.8


func _panel_style(fill: Color, border: Color, radius: int = 22) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 3)
	return style


func _make_ui_label(pos: Vector2, label_size: Vector2, font_size: int, text_value: String, color: Color) -> Label:
	var label := Label.new()
	label.position = pos
	label.size = label_size
	label.add_theme_font_size_override("font_size", font_size)
	label.modulate = color
	label.text = text_value
	return label


func _make_stat_card(parent: Node, pos: Vector2, card_size: Vector2, title_text: String, accent: Color) -> Label:
	var card := Panel.new()
	card.position = pos
	card.size = card_size
	card.add_theme_stylebox_override("panel", _panel_style(Color(0.08, 0.1, 0.13, 0.9), Color(0.21, 0.26, 0.32), 26))
	parent.add_child(card)

	var accent_line := ColorRect.new()
	accent_line.position = Vector2(18.0, 16.0)
	accent_line.size = Vector2(4.0, card_size.y - 32.0)
	accent_line.color = accent
	card.add_child(accent_line)

	card.add_child(_make_ui_label(Vector2(34.0, 16.0), Vector2(card_size.x - 50.0, 18.0), 15, title_text, accent))
	var label := _make_ui_label(Vector2(34.0, 40.0), Vector2(card_size.x - 50.0, 38.0), 30, "--", Color(0.96, 0.97, 0.98))
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	card.add_child(label)
	return label


func _draw() -> void:
	var world_top: float = DESTINATION_Y - 320.0
	var road_top: float = DESTINATION_Y - 180.0
	var world_height: float = ROAD_BOTTOM_Y - world_top
	var road_height: float = ROAD_BOTTOM_Y - road_top

	draw_rect(Rect2(-1200.0, world_top, 2400.0, world_height), Color(0.13, 0.16, 0.19))
	draw_rect(Rect2(-SIDEWALK_HALF_WIDTH, road_top, SIDEWALK_HALF_WIDTH - ROAD_HALF_WIDTH, road_height), Color(0.48, 0.44, 0.4))
	draw_rect(Rect2(ROAD_HALF_WIDTH, road_top, SIDEWALK_HALF_WIDTH - ROAD_HALF_WIDTH, road_height), Color(0.48, 0.44, 0.4))
	draw_rect(Rect2(-ROAD_HALF_WIDTH, road_top, ROAD_HALF_WIDTH * 2.0, road_height), Color(0.2, 0.22, 0.26))

	for lane_x in [-180.0, 0.0, 180.0]:
		var segment_count: int = int(ceil((ROAD_BOTTOM_Y - (DESTINATION_Y - 100.0)) / 132.0)) + 1
		for segment in range(segment_count):
			var y_top := DESTINATION_Y - 100.0 + float(segment) * 132.0
			draw_rect(Rect2(lane_x - 5.0, y_top, 10.0, 68.0), Color(0.92, 0.9, 0.78))

	for light_ref in traffic_lights:
		var light: TrafficLight = light_ref
		var stripe_y: float = light.position.y + 90.0
		for index in range(10):
			var x_pos: float = -ROAD_HALF_WIDTH + 24.0 + index * 72.0
			draw_rect(Rect2(x_pos, stripe_y, 46.0, 12.0), Color(0.94, 0.94, 0.94))

	draw_rect(Rect2(-ROAD_HALF_WIDTH, DESTINATION_Y, ROAD_HALF_WIDTH * 2.0, 48.0), Color(0.24, 0.78, 0.43, 0.85))
