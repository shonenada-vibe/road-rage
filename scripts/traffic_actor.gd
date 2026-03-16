extends CharacterBody2D
class_name TrafficActor

var actor_kind: String = "pedestrian"
var chaos_value: float = 10.0
var lane_min_x: float = -300.0
var lane_max_x: float = 300.0
var travel_direction: float = 1.0
var forward_speed: float = 0.0
var lateral_amplitude: float = 0.0
var lateral_frequency: float = 0.0
var spawn_origin: Vector2 = Vector2.ZERO
var color_primary: Color = Color.WHITE
var body_size: Vector2 = Vector2(24.0, 24.0)
var launch_drag: float = 260.0
var phase: float = 0.0

var launched: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
var angular_velocity: float = 0.0
var lifetime: float = 0.0


func _init(kind: String = "pedestrian") -> void:
	actor_kind = kind


func _ready() -> void:
	z_index = 18
	collision_layer = 2
	collision_mask = 1
	_configure_actor()
	_build_visuals()


func setup_spawn(origin: Vector2, min_x: float, max_x: float, direction: float = 1.0) -> void:
	spawn_origin = origin
	global_position = origin
	lane_min_x = min_x
	lane_max_x = max_x
	travel_direction = direction
	phase = randf_range(0.0, TAU)


func _configure_actor() -> void:
	match actor_kind:
		"pedestrian":
			body_size = Vector2(20.0, 28.0)
			color_primary = Color(1.0, 0.89, 0.58)
			forward_speed = 80.0
			lateral_amplitude = 10.0
			lateral_frequency = 4.5
			chaos_value = 15.0
			launch_drag = 180.0
		"scooter":
			body_size = Vector2(26.0, 52.0)
			color_primary = Color(0.33, 0.94, 0.98)
			forward_speed = randf_range(180.0, 260.0)
			lateral_amplitude = randf_range(90.0, 150.0)
			lateral_frequency = randf_range(1.2, 2.0)
			chaos_value = 22.0
			launch_drag = 210.0
		"parked_car":
			body_size = Vector2(46.0, 92.0)
			color_primary = Color(0.95, 0.79, 0.25)
			forward_speed = 0.0
			lateral_amplitude = 0.0
			lateral_frequency = 0.0
			chaos_value = 10.0
			launch_drag = 320.0
		_:
			body_size = Vector2(24.0, 24.0)
			color_primary = Color.WHITE


func _build_visuals() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = body_size
	collision.shape = shape
	add_child(collision)

	var body := Polygon2D.new()
	body.color = color_primary
	body.polygon = PackedVector2Array([
		Vector2(-body_size.x * 0.5, -body_size.y * 0.5),
		Vector2(body_size.x * 0.5, -body_size.y * 0.5),
		Vector2(body_size.x * 0.5, body_size.y * 0.5),
		Vector2(-body_size.x * 0.5, body_size.y * 0.5),
	])
	add_child(body)

	if actor_kind == "pedestrian":
		var head := Polygon2D.new()
		head.color = Color(0.13, 0.16, 0.22)
		head.polygon = _circle_polygon(8.0)
		head.position = Vector2(0.0, -body_size.y * 0.5 - 8.0)
		add_child(head)
	elif actor_kind == "scooter":
		var trim := Polygon2D.new()
		trim.color = Color(0.05, 0.11, 0.14)
		trim.polygon = PackedVector2Array([
			Vector2(-5.0, -body_size.y * 0.5),
			Vector2(5.0, -body_size.y * 0.5),
			Vector2(3.0, body_size.y * 0.5),
			Vector2(-3.0, body_size.y * 0.5),
		])
		add_child(trim)
	elif actor_kind == "parked_car":
		var window := Polygon2D.new()
		window.color = Color(0.78, 0.92, 1.0)
		window.polygon = PackedVector2Array([
			Vector2(-14.0, -18.0),
			Vector2(14.0, -18.0),
			Vector2(12.0, 16.0),
			Vector2(-12.0, 16.0),
		])
		add_child(window)


func _physics_process(delta: float) -> void:
	lifetime += delta
	if launched:
		global_position += knockback_velocity * delta
		rotation += angular_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, launch_drag * delta)
		angular_velocity = move_toward(angular_velocity, 0.0, 6.0 * delta)
		if abs(global_position.x) > 960.0 or global_position.y > 960.0 or global_position.y < -4700.0:
			queue_free()
		return

	match actor_kind:
		"pedestrian":
			_move_pedestrian(delta)
		"scooter":
			_move_scooter(delta)
		"parked_car":
			velocity = Vector2.ZERO
			rotation = lerpf(rotation, 0.0, 8.0 * delta)

	move_and_slide()


func _move_pedestrian(delta: float) -> void:
	if global_position.x < lane_min_x:
		travel_direction = 1.0
	elif global_position.x > lane_max_x:
		travel_direction = -1.0

	var sway := sin(lifetime * lateral_frequency + phase) * lateral_amplitude
	velocity.x = (forward_speed * travel_direction) + sway
	velocity.y = sin(lifetime * 2.3 + phase) * 14.0
	rotation = lerpf(rotation, deg_to_rad(10.0) * sign(velocity.x), 7.0 * delta)


func _move_scooter(delta: float) -> void:
	var target_x := clampf(spawn_origin.x + sin(lifetime * lateral_frequency + phase) * lateral_amplitude, lane_min_x, lane_max_x)
	velocity.x = (target_x - global_position.x) * 3.4
	velocity.y = forward_speed * travel_direction
	rotation = lerpf(rotation, deg_to_rad(clampf(velocity.x * 0.08, -18.0, 18.0)), 6.0 * delta)


func can_be_hit() -> bool:
	return not launched


func hit_kind() -> String:
	return actor_kind


func hit_chaos_value() -> float:
	return chaos_value


func launch(impact_vector: Vector2, impact_force: float) -> void:
	if launched:
		return

	launched = true
	collision_layer = 0
	collision_mask = 0

	var force_scale := impact_force
	match actor_kind:
		"pedestrian":
			force_scale *= 1.35
		"scooter":
			force_scale *= 1.15
		"parked_car":
			force_scale *= 0.65

	knockback_velocity = impact_vector.normalized() * maxf(240.0, force_scale)
	knockback_velocity.x += sign(impact_vector.x) * 60.0
	angular_velocity = deg_to_rad(randf_range(-780.0, 780.0))


func _circle_polygon(radius: float, steps: int = 14) -> PackedVector2Array:
	var points := PackedVector2Array()
	for index in range(steps):
		var angle := TAU * float(index) / float(steps)
		points.append(Vector2.RIGHT.rotated(angle) * radius)
	return points
