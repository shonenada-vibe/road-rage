extends Node2D
class_name TrafficLight

var red_duration: float = 5.0
var green_duration: float = 4.0
var cycle_offset: float = 0.0


func _init(offset: float = 0.0) -> void:
	cycle_offset = offset


func _process(delta: float) -> void:
	queue_redraw()


func is_red() -> bool:
	var cycle := red_duration + green_duration
	return fmod(Time.get_ticks_msec() / 1000.0 + cycle_offset, cycle) < red_duration


func stop_line_y() -> float:
	return global_position.y + 84.0


func _draw() -> void:
	draw_line(Vector2.ZERO, Vector2(0.0, 118.0), Color(0.14, 0.17, 0.21), 6.0)
	draw_rect(Rect2(-16.0, -12.0, 32.0, 78.0), Color(0.18, 0.2, 0.25))
	draw_circle(Vector2(0.0, 6.0), 8.0, Color(0.4, 0.12, 0.12))
	draw_circle(Vector2(0.0, 26.0), 8.0, Color(0.38, 0.31, 0.08))
	draw_circle(Vector2(0.0, 46.0), 8.0, Color(0.09, 0.36, 0.16))

	if is_red():
		draw_circle(Vector2(0.0, 6.0), 7.0, Color(1.0, 0.27, 0.2))
	else:
		draw_circle(Vector2(0.0, 46.0), 7.0, Color(0.38, 1.0, 0.45))
