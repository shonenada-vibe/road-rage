extends CharacterBody2D
class_name AIVehicle

var vehicle_style: String = "sedan"
var lane_center_x: float = 0.0
var travel_direction_y: float = -1.0
var cruise_speed: float = 520.0
var current_speed: float = 0.0
var acceleration: float = 320.0
var braking_power: float = 540.0
var road_half_width: float = 360.0
var sidewalk_half_width: float = 560.0
var body_color: Color = Color(0.85, 0.24, 0.21)
var body_size: Vector2 = Vector2(46.0, 96.0)
var chaos_value: float = 34.0
var wobble_phase: float = 0.0
var lifetime: float = 0.0
var traffic_lights: Array = []

var wrecked: bool = false
var wreck_velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var wreck_drag: float = 240.0
var visuals_ready: bool = false


func _init(style_name: String = "sedan") -> void:
	vehicle_style = style_name


func _ready() -> void:
	collision_layer = 2
	collision_mask = 1
	z_index = 24
	_build_visuals()


func setup_spawn(origin: Vector2, lane_x: float, direction_y: float, light_nodes: Array, new_road_half_width: float, new_sidewalk_half_width: float) -> void:
	_configure_style()
	global_position = origin
	lane_center_x = lane_x
	travel_direction_y = direction_y
	traffic_lights = light_nodes
	road_half_width = new_road_half_width
	sidewalk_half_width = new_sidewalk_half_width
	current_speed = cruise_speed * randf_range(0.72, 0.9)
	wobble_phase = randf_range(0.0, TAU)


func _configure_style() -> void:
	match vehicle_style:
		"taxi":
			body_color = Color(0.96, 0.79, 0.18)
			cruise_speed = randf_range(420.0, 610.0)
			chaos_value = 32.0
		"delivery":
			body_color = Color(0.9, 0.43, 0.18)
			body_size = Vector2(52.0, 108.0)
			cruise_speed = randf_range(360.0, 520.0)
			chaos_value = 38.0
		"blue":
			body_color = Color(0.26, 0.58, 0.94)
			cruise_speed = randf_range(430.0, 620.0)
			chaos_value = 34.0
		_:
			body_color = Color(0.84, 0.21, 0.27)
			cruise_speed = randf_range(440.0, 640.0)
			chaos_value = 35.0


func _build_visuals() -> void:
	if visuals_ready:
		return
	visuals_ready = true

	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body_size
	collision.shape = shape
	add_child(collision)

	var body := Polygon2D.new()
	body.color = body_color
	body.polygon = PackedVector2Array([
		Vector2(-body_size.x * 0.5, -body_size.y * 0.5 + 8.0),
		Vector2(-body_size.x * 0.32, -body_size.y * 0.5),
		Vector2(body_size.x * 0.32, -body_size.y * 0.5),
		Vector2(body_size.x * 0.5, -body_size.y * 0.5 + 8.0),
		Vector2(body_size.x * 0.5, body_size.y * 0.5 - 14.0),
		Vector2(body_size.x * 0.28, body_size.y * 0.5),
		Vector2(-body_size.x * 0.28, body_size.y * 0.5),
		Vector2(-body_size.x * 0.5, body_size.y * 0.5 - 14.0),
	])
	add_child(body)

	var window := Polygon2D.new()
	window.color = Color(0.77, 0.91, 1.0)
	window.polygon = PackedVector2Array([
		Vector2(-body_size.x * 0.26, -20.0),
		Vector2(body_size.x * 0.26, -20.0),
		Vector2(body_size.x * 0.22, 24.0),
		Vector2(-body_size.x * 0.22, 24.0),
	])
	add_child(window)

	var bumper := Polygon2D.new()
	bumper.color = Color(0.12, 0.14, 0.17)
	bumper.polygon = PackedVector2Array([
		Vector2(-body_size.x * 0.32, -body_size.y * 0.5 + 7.0),
		Vector2(body_size.x * 0.32, -body_size.y * 0.5 + 7.0),
		Vector2(body_size.x * 0.26, -body_size.y * 0.5 + 18.0),
		Vector2(-body_size.x * 0.26, -body_size.y * 0.5 + 18.0),
	])
	add_child(bumper)


func _physics_process(delta: float) -> void:
	lifetime += delta

	if wrecked:
		global_position += wreck_velocity * delta
		rotation += angular_velocity * delta
		wreck_velocity = wreck_velocity.move_toward(Vector2.ZERO, wreck_drag * delta)
		angular_velocity = move_toward(angular_velocity, 0.0, 4.2 * delta)
		if abs(global_position.x) > sidewalk_half_width + 280.0 or abs(global_position.y) > 5400.0:
			queue_free()
		return

	var should_brake: bool = _should_stop_for_red()
	var target_speed: float = 0.0 if should_brake else cruise_speed
	var change_rate: float = braking_power if should_brake else acceleration
	current_speed = move_toward(current_speed, target_speed, change_rate * delta)

	var lane_wobble: float = sin(lifetime * 1.8 + wobble_phase) * 8.0
	velocity.x = ((lane_center_x + lane_wobble) - global_position.x) * 4.6
	velocity.y = current_speed * travel_direction_y
	move_and_slide()

	var target_rotation: float = deg_to_rad(clampf(velocity.x * 0.04, -9.0, 9.0))
	rotation = lerpf(rotation, target_rotation, 5.5 * delta)


func _should_stop_for_red() -> bool:
	for light_ref in traffic_lights:
		var light: TrafficLight = light_ref
		if not light.is_red():
			continue

		var stop_y: float = light.stop_line_y()
		if travel_direction_y < 0.0 and global_position.y > stop_y and global_position.y - stop_y < 170.0:
			return true
		if travel_direction_y > 0.0 and global_position.y < stop_y and stop_y - global_position.y < 170.0:
			return true

	return false


func can_be_hit() -> bool:
	return not wrecked


func hit_kind() -> String:
	return "traffic_car"


func hit_chaos_value() -> float:
	return chaos_value


func launch(impact_vector: Vector2, impact_force: float) -> void:
	if wrecked:
		return

	wrecked = true
	collision_layer = 0
	collision_mask = 0
	z_index = 34
	wreck_velocity = impact_vector.normalized() * maxf(260.0, impact_force * 0.9)
	wreck_velocity.x += sign(impact_vector.x) * 90.0
	angular_velocity = deg_to_rad(randf_range(-420.0, 420.0))
