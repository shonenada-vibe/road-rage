extends Node2D

const PlayerCarScene := preload("res://scripts/player_car.gd")
const TrafficActorScene := preload("res://scripts/traffic_actor.gd")
const TrafficLightScene := preload("res://scripts/traffic_light.gd")

const WORLD_LENGTH: float = 4200.0
const ROAD_HALF_WIDTH: float = 360.0
const SIDEWALK_HALF_WIDTH: float = 560.0
const SPEED_LIMIT: float = 680.0
const DESTINATION_Y: float = -3880.0

var player: PlayerCar
var camera: Camera2D
var hud_label: Label
var info_label: Label
var finish_label: Label

var rule_score: float = 100.0
var chaos_score: float = 0.0
var status_text: String = "平稳起步，保持在车道内。"
var status_timer: float = 3.0
var shake_strength: float = 0.0
var finished: bool = false

var traffic_lights: Array = []
var light_crossed: Dictionary = {}


func _ready() -> void:
	randomize()
	_create_player()
	_create_lights()
	_create_obstacles()
	_create_camera()
	_create_hud()
	_update_hud()
	queue_redraw()


func _create_player() -> void:
	player = PlayerCarScene.new()
	player.global_position = Vector2(110.0, 240.0)
	player.set_drive_bounds(ROAD_HALF_WIDTH, SIDEWALK_HALF_WIDTH)
	player.traffic_hit.connect(_on_player_traffic_hit)
	add_child(player)


func _create_lights() -> void:
	var light_rows := [-700.0, -1760.0, -2940.0]
	for row in light_rows:
		var left_light := TrafficLightScene.new(randf_range(0.0, 5.0))
		left_light.position = Vector2(-SIDEWALK_HALF_WIDTH + 86.0, row)
		add_child(left_light)
		traffic_lights.append(left_light)
		light_crossed[left_light] = false

		var right_light := TrafficLightScene.new(randf_range(0.0, 5.0))
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


func _create_camera() -> void:
	camera = Camera2D.new()
	camera.enabled = true
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 6.0
	player.add_child(camera)


func _create_hud() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.05, 0.07, 0.1, 0.8)
	backdrop.position = Vector2(20.0, 20.0)
	backdrop.size = Vector2(430.0, 130.0)
	layer.add_child(backdrop)

	hud_label = Label.new()
	hud_label.position = Vector2(40.0, 38.0)
	hud_label.size = Vector2(400.0, 90.0)
	hud_label.add_theme_font_size_override("font_size", 22)
	layer.add_child(hud_label)

	info_label = Label.new()
	info_label.position = Vector2(20.0, 680.0)
	info_label.size = Vector2(1240.0, 40.0)
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 20)
	info_label.text = "方向键 / WASD: 驾驶   绿灯通行，红灯停车   抵达终点即可结算   R: 重新开始"
	layer.add_child(info_label)

	finish_label = Label.new()
	finish_label.position = Vector2(190.0, 220.0)
	finish_label.size = Vector2(900.0, 220.0)
	finish_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	finish_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	finish_label.add_theme_font_size_override("font_size", 32)
	finish_label.visible = false
	layer.add_child(finish_label)


func _process(delta: float) -> void:
	if Input.is_key_pressed(KEY_R):
		get_tree().reload_current_scene()
		return

	if finished:
		_update_finish_text()
		_update_camera(delta)
		return

	status_timer = maxf(0.0, status_timer - delta)
	if status_timer <= 0.0:
		status_text = "在拥堵中控住节奏，或者把怒气转成混乱分。"

	_apply_rule_checks(delta)
	_update_hud()
	_update_camera(delta)

	if player.global_position.y <= DESTINATION_Y:
		finished = true
		player.set_finished()
		status_text = "到达终点。按 R 可以立刻再跑一趟。"
		status_timer = 999.0
		finish_label.visible = true


func _apply_rule_checks(delta: float) -> void:
	if player.speed_units() > SPEED_LIMIT:
		rule_score = maxf(0.0, rule_score - 7.5 * delta)
		status_text = "你超速了，守规则分正在下降。"
		status_timer = 0.6

	if player.is_on_sidewalk():
		rule_score = maxf(0.0, rule_score - 13.0 * delta)
		status_text = "你压上了非机动车道/人行区域。"
		status_timer = 0.4

	for light in traffic_lights:
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


func _update_hud() -> void:
	var distance_left := maxf(0.0, player.global_position.y - DESTINATION_Y)
	hud_label.text = "速度 %d km/h\n守规则 %.0f / 100    混乱 %.0f\n%s\n剩余距离 %.0f m" % [
		player.speed_kph(),
		rule_score,
		chaos_score,
		status_text,
		distance_left / 7.5,
	]


func _update_finish_text() -> void:
	var style := "克制通关"
	if chaos_score >= 180.0 and rule_score < 45.0:
		style = "彻底路怒通关"
	elif chaos_score >= 90.0:
		style = "高压释放通关"
	elif rule_score >= 75.0:
		style = "规则模范通关"

	finish_label.text = "已抵达目的地\n守规则 %.0f / 100\n混乱 %.0f\n评价：%s\n按 R 重新开始" % [
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


func _on_player_traffic_hit(kind: String, chaos_gain: float, impact_force: float) -> void:
	chaos_score += chaos_gain
	shake_strength = minf(22.0, shake_strength + impact_force * 0.016)
	match kind:
		"pedestrian":
			status_text = "行人被夸张地撞飞了。"
		"scooter":
			status_text = "电动车在空中翻滚出去。"
		"parked_car":
			status_text = "违停车辆被你顶得横着滑开。"
		_:
			status_text = "碰撞制造了新的混乱。"
	status_timer = 1.8


func _draw() -> void:
	draw_rect(Rect2(-1200.0, DESTINATION_Y - 320.0, 2400.0, WORLD_LENGTH + 900.0), Color(0.13, 0.16, 0.19))
	draw_rect(Rect2(-SIDEWALK_HALF_WIDTH, DESTINATION_Y - 180.0, SIDEWALK_HALF_WIDTH - ROAD_HALF_WIDTH, WORLD_LENGTH + 380.0), Color(0.48, 0.44, 0.4))
	draw_rect(Rect2(ROAD_HALF_WIDTH, DESTINATION_Y - 180.0, SIDEWALK_HALF_WIDTH - ROAD_HALF_WIDTH, WORLD_LENGTH + 380.0), Color(0.48, 0.44, 0.4))
	draw_rect(Rect2(-ROAD_HALF_WIDTH, DESTINATION_Y - 180.0, ROAD_HALF_WIDTH * 2.0, WORLD_LENGTH + 380.0), Color(0.2, 0.22, 0.26))

	for lane_x in [-180.0, 0.0, 180.0]:
		for segment in range(36):
			var y_top := DESTINATION_Y - 100.0 + float(segment) * 132.0
			draw_rect(Rect2(lane_x - 5.0, y_top, 10.0, 68.0), Color(0.92, 0.9, 0.78))

	for light in traffic_lights:
		var stripe_y := light.position.y + 90.0
		for index in range(10):
			var x_pos := -ROAD_HALF_WIDTH + 24.0 + index * 72.0
			draw_rect(Rect2(x_pos, stripe_y, 46.0, 12.0), Color(0.94, 0.94, 0.94))

	draw_rect(Rect2(-ROAD_HALF_WIDTH, DESTINATION_Y, ROAD_HALF_WIDTH * 2.0, 48.0), Color(0.24, 0.78, 0.43, 0.85))
