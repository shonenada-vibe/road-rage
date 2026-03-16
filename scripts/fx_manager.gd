extends Node2D
class_name FxManager

const ParticleBurstScene := preload("res://scripts/particle_burst.gd")


func spawn_impact(position: Vector2, direction: Vector2, intensity: float, tint: Color = Color(1.0, 0.77, 0.34)) -> void:
	var burst: ParticleBurst = ParticleBurstScene.new()
	burst.global_position = position
	burst.configure("impact", direction, intensity, tint)
	add_child(burst)


func spawn_skid(position: Vector2, direction: Vector2, intensity: float, tint: Color = Color(0.76, 0.72, 0.63)) -> void:
	var burst: ParticleBurst = ParticleBurstScene.new()
	burst.global_position = position
	burst.configure("skid", direction, intensity, tint)
	add_child(burst)


func spawn_finish(position: Vector2) -> void:
	var burst: ParticleBurst = ParticleBurstScene.new()
	burst.global_position = position
	burst.configure("finish", Vector2.UP, 1.0, Color(0.34, 1.0, 0.62))
	add_child(burst)

