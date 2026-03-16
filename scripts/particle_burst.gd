extends Node2D
class_name ParticleBurst

var burst_type: String = "impact"
var tint: Color = Color.WHITE
var direction: Vector2 = Vector2.UP

var positions: Array = []
var velocities: Array = []
var sizes: Array = []
var life_left: Array = []
var max_life: Array = []
var gravity: Vector2 = Vector2.ZERO
var elapsed: float = 0.0


func configure(new_burst_type: String, new_direction: Vector2, intensity: float, new_tint: Color) -> void:
	burst_type = new_burst_type
	direction = new_direction.normalized()
	if direction == Vector2.ZERO:
		direction = Vector2.UP
	tint = new_tint

	match burst_type:
		"skid":
			gravity = Vector2(0.0, 24.0)
			_seed_particles(10, 24.0, 90.0, 0.18, 0.36, intensity)
		"finish":
			gravity = Vector2(0.0, 180.0)
			_seed_particles(42, 100.0, 260.0, 0.55, 1.0, intensity)
		_:
			gravity = Vector2(0.0, 140.0)
			_seed_particles(24, 80.0, 220.0, 0.22, 0.58, intensity)

	queue_redraw()


func _seed_particles(count: int, min_speed: float, max_speed: float, min_life: float, max_life_value: float, intensity: float) -> void:
	positions.clear()
	velocities.clear()
	sizes.clear()
	life_left.clear()
	max_life.clear()

	for index in range(count):
		var spread_dir: Vector2 = direction.rotated(randf_range(-1.2, 1.2))
		var speed: float = randf_range(min_speed, max_speed) * (0.75 + intensity * 0.35)
		var particle_life: float = randf_range(min_life, max_life_value)
		positions.append(Vector2.ZERO)
		velocities.append(spread_dir * speed)
		sizes.append(randf_range(2.0, 7.0))
		life_left.append(particle_life)
		max_life.append(particle_life)


func _process(delta: float) -> void:
	elapsed += delta
	var any_alive: bool = false

	for index in range(positions.size()):
		var life: float = life_left[index]
		if life <= 0.0:
			continue

		any_alive = true
		var velocity: Vector2 = velocities[index]
		var position_value: Vector2 = positions[index]
		life -= delta
		life_left[index] = life
		velocity = velocity + gravity * delta
		position_value = position_value + velocity * delta
		velocity = velocity * 0.94
		velocities[index] = velocity
		positions[index] = position_value

	if not any_alive:
		queue_free()
		return

	queue_redraw()


func _draw() -> void:
	for index in range(positions.size()):
		var life: float = life_left[index]
		if life <= 0.0:
			continue

		var alpha: float = clampf(life / max_life[index], 0.0, 1.0)
		var color: Color = Color(tint.r, tint.g, tint.b, alpha)
		var pos: Vector2 = positions[index]
		var radius: float = float(sizes[index]) * alpha

		if burst_type == "skid":
			draw_circle(pos, radius, color)
		else:
			var velocity: Vector2 = velocities[index]
			var trail: Vector2 = velocity.normalized() * minf(18.0, velocity.length() * 0.06)
			draw_line(pos - trail, pos + trail, color, maxf(1.0, radius))
			draw_circle(pos, radius * 0.72, color)
