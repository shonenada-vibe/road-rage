extends CharacterBody2D
class_name PlayerCar

signal traffic_hit(kind: String, chaos_gain: float, impact_force: float, impact_position: Vector2, impact_vector: Vector2)

const ROAD_MARGIN: float = 24.0

var road_half_width: float = 360.0
var sidewalk_half_width: float = 540.0

var acceleration: float = 900.0
var drag: float = 520.0
var brake_strength: float = 1200.0
var max_forward_speed: float = 920.0
var max_side_speed: float = 360.0

var forward_speed: float = 0.0
var side_speed: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var controls_locked: bool = false
var collision_cooldown: float = 0.0
var recoil_velocity: Vector2 = Vector2.ZERO


func _ready() -> void:
	z_index = 30
	collision_layer = 1
	collision_mask = 2
	_build_visuals()
	last_position = global_position


func set_drive_bounds(new_road_half_width: float, new_sidewalk_half_width: float) -> void:
	road_half_width = new_road_half_width
	sidewalk_half_width = new_sidewalk_half_width


func set_finished() -> void:
	controls_locked = true
	forward_speed = 0.0
	side_speed = 0.0
	velocity = Vector2.ZERO


func _build_visuals() -> void:
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(42.0, 84.0)
	collision.shape = shape
	add_child(collision)

	var body := Polygon2D.new()
	body.color = Color(0.95, 0.29, 0.22)
	body.polygon = PackedVector2Array([
		Vector2(-20.0, -42.0),
		Vector2(20.0, -42.0),
		Vector2(22.0, 30.0),
		Vector2(12.0, 42.0),
		Vector2(-12.0, 42.0),
		Vector2(-22.0, 30.0),
	])
	add_child(body)

	var windshield := Polygon2D.new()
	windshield.color = Color(0.75, 0.91, 1.0)
	windshield.polygon = PackedVector2Array([
		Vector2(-13.0, -26.0),
		Vector2(13.0, -26.0),
		Vector2(10.0, -4.0),
		Vector2(-10.0, -4.0),
	])
	add_child(windshield)

	var stripe := Polygon2D.new()
	stripe.color = Color(1.0, 0.84, 0.32)
	stripe.polygon = PackedVector2Array([
		Vector2(-4.0, -40.0),
		Vector2(4.0, -40.0),
		Vector2(3.0, 36.0),
		Vector2(-3.0, 36.0),
	])
	add_child(stripe)


func _physics_process(delta: float) -> void:
	last_position = global_position
	collision_cooldown = maxf(0.0, collision_cooldown - delta)

	if not controls_locked:
		_update_input(delta)
	else:
		forward_speed = move_toward(forward_speed, 0.0, brake_strength * delta)
		side_speed = move_toward(side_speed, 0.0, brake_strength * delta)

	recoil_velocity = recoil_velocity.move_toward(Vector2.ZERO, 880.0 * delta)
	velocity = Vector2(side_speed, -forward_speed) + recoil_velocity
	move_and_slide()
	_resolve_world_bounds()
	_handle_collisions()
	_update_visual_tilt(delta)


func _update_input(delta: float) -> void:
	var throttle := 0.0
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		throttle += 1.0
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		throttle -= 1.0

	if throttle > 0.0:
		forward_speed = minf(forward_speed + acceleration * delta, max_forward_speed)
	elif throttle < 0.0:
		forward_speed = maxf(forward_speed - brake_strength * delta, 0.0)
	else:
		forward_speed = maxf(forward_speed - drag * delta, 240.0)

	var steer := 0.0
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		steer -= 1.0
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		steer += 1.0

	var steer_target := steer * max_side_speed
	side_speed = move_toward(side_speed, steer_target, 1400.0 * delta)
	if is_zero_approx(steer):
		side_speed = move_toward(side_speed, 0.0, 900.0 * delta)


func _resolve_world_bounds() -> void:
	if abs(global_position.x) > sidewalk_half_width:
		global_position.x = clampf(global_position.x, -sidewalk_half_width, sidewalk_half_width)
		side_speed *= -0.15


func _handle_collisions() -> void:
	if collision_cooldown > 0.0:
		return

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		var collider := collision.get_collider()
		if collider != null and collider.has_method("can_be_hit") and collider.call("can_be_hit"):
			var impact_force := maxf(forward_speed * 0.95 + abs(side_speed) * 0.7, 260.0)
			var impact_vector := Vector2(side_speed * 0.9, -maxf(forward_speed, 260.0))
			if collider.has_method("launch"):
				collider.call("launch", impact_vector, impact_force)

			var hit_kind: String = "obstacle"
			if collider.has_method("hit_kind"):
				hit_kind = String(collider.call("hit_kind"))

			var chaos_value: float = 10.0
			if collider.has_method("hit_chaos_value"):
				chaos_value = float(collider.call("hit_chaos_value"))

			forward_speed *= 0.66
			side_speed *= 0.44
			recoil_velocity += impact_vector.normalized() * -minf(impact_force * 0.42, 260.0)
			collision_cooldown = 0.18
			emit_signal("traffic_hit", hit_kind, chaos_value + impact_force * 0.028, impact_force, collision.get_position(), impact_vector)
			break


func _update_visual_tilt(delta: float) -> void:
	var target_rotation := deg_to_rad(clampf(side_speed * 0.045, -12.0, 12.0))
	rotation = lerpf(rotation, target_rotation, 8.0 * delta)


func speed_units() -> float:
	return forward_speed


func speed_kph() -> int:
	return int(round(forward_speed * 0.18))


func speed_ratio() -> float:
	return clampf(forward_speed / max_forward_speed, 0.0, 1.0)


func is_on_sidewalk() -> bool:
	return abs(global_position.x) > road_half_width + ROAD_MARGIN


func skid_ratio() -> float:
	return clampf(abs(side_speed) / max_side_speed, 0.0, 1.0)


func crossed_line(y_line: float) -> bool:
	return last_position.y > y_line and global_position.y <= y_line
