extends Node
class_name AudioLab

var engine_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer

var engine_stream: AudioStreamWAV
var ambience_stream: AudioStreamWAV
var click_stream: AudioStreamWAV
var finish_stream: AudioStreamWAV
var impact_streams: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	engine_player = AudioStreamPlayer.new()
	engine_player.bus = "Master"
	engine_player.volume_db = -26.0
	add_child(engine_player)

	ambience_player = AudioStreamPlayer.new()
	ambience_player.bus = "Master"
	ambience_player.volume_db = -31.0
	add_child(ambience_player)

	ui_player = AudioStreamPlayer.new()
	ui_player.bus = "Master"
	add_child(ui_player)

	engine_stream = _build_engine_stream()
	ambience_stream = _build_ambience_stream()
	click_stream = _build_click_stream()
	finish_stream = _build_finish_stream()
	impact_streams = [
		_build_impact_stream(0.18, 0.42),
		_build_impact_stream(0.26, 0.65),
		_build_impact_stream(0.34, 0.95),
	]

	engine_player.stream = engine_stream
	ambience_player.stream = ambience_stream


func start_gameplay_audio() -> void:
	if not engine_player.playing:
		engine_player.play()
	if not ambience_player.playing:
		ambience_player.play()


func stop_gameplay_audio() -> void:
	engine_player.stop()
	ambience_player.stop()


func update_engine(speed_ratio: float, skid_ratio: float) -> void:
	start_gameplay_audio()
	engine_player.pitch_scale = 0.76 + speed_ratio * 0.82 + skid_ratio * 0.1
	engine_player.volume_db = lerpf(-25.0, -8.5, speed_ratio)
	ambience_player.pitch_scale = 0.92 + speed_ratio * 0.16
	ambience_player.volume_db = lerpf(-33.0, -25.0, speed_ratio)


func play_collision(position: Vector2, intensity: float) -> void:
	var player := AudioStreamPlayer2D.new()
	player.bus = "Master"
	player.global_position = position
	player.max_distance = 1800.0
	player.attenuation = 1.4
	player.volume_db = clampf(-12.0 + intensity * 0.012, -10.0, 2.0)
	player.pitch_scale = randf_range(0.88, 1.08)

	if intensity < 420.0:
		player.stream = impact_streams[0]
	elif intensity < 680.0:
		player.stream = impact_streams[1]
	else:
		player.stream = impact_streams[2]

	add_child(player)
	player.play()
	player.finished.connect(player.queue_free)


func play_menu_confirm() -> void:
	ui_player.stream = click_stream
	ui_player.pitch_scale = 1.0
	ui_player.volume_db = -8.0
	ui_player.play()


func play_finish() -> void:
	ui_player.stream = finish_stream
	ui_player.pitch_scale = 1.0
	ui_player.volume_db = -5.0
	ui_player.play()


func _build_engine_stream() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var sample_count: int = int(mix_rate * 0.82)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var wave: float = sin(TAU * 72.0 * t) * 0.52
		wave += sin(TAU * 144.0 * t) * 0.16
		wave += sin(TAU * 216.0 * t) * 0.08
		wave += sin(TAU * 18.0 * t) * 0.04
		data.encode_s16(index * 2, int(clampf(wave, -1.0, 1.0) * 32767.0))

	return _build_wav(data, mix_rate, sample_count, true)


func _build_ambience_stream() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var sample_count: int = int(mix_rate * 1.4)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var noise_state: float = 0.0

	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var target: float = randf_range(-0.18, 0.18)
		noise_state = lerpf(noise_state, target, 0.16)
		var wave: float = sin(TAU * 28.0 * t) * 0.06
		wave += sin(TAU * 53.0 * t) * 0.05
		wave += noise_state * 0.7
		data.encode_s16(index * 2, int(clampf(wave, -1.0, 1.0) * 32767.0))

	return _build_wav(data, mix_rate, sample_count, true)


func _build_click_stream() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var sample_count: int = int(mix_rate * 0.16)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var envelope: float = 1.0 - (float(index) / float(sample_count))
		var wave: float = sin(TAU * 780.0 * t) * 0.45
		wave += sin(TAU * 1150.0 * t) * 0.18
		data.encode_s16(index * 2, int(clampf(wave * envelope, -1.0, 1.0) * 32767.0))

	return _build_wav(data, mix_rate, sample_count, false)


func _build_finish_stream() -> AudioStreamWAV:
	var mix_rate: int = 22050
	var sample_count: int = int(mix_rate * 0.42)
	var data := PackedByteArray()
	data.resize(sample_count * 2)

	for index in range(sample_count):
		var t: float = float(index) / float(mix_rate)
		var progress: float = float(index) / float(sample_count)
		var envelope: float = sin(progress * PI)
		var wave: float = sin(TAU * lerpf(520.0, 880.0, progress) * t) * 0.36
		wave += sin(TAU * lerpf(780.0, 1160.0, progress) * t) * 0.14
		data.encode_s16(index * 2, int(clampf(wave * envelope, -1.0, 1.0) * 32767.0))

	return _build_wav(data, mix_rate, sample_count, false)


func _build_impact_stream(duration: float, harshness: float) -> AudioStreamWAV:
	var mix_rate: int = 22050
	var sample_count: int = int(mix_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var noise_state: float = 0.0

	for index in range(sample_count):
		var progress: float = float(index) / float(sample_count)
		var t: float = float(index) / float(mix_rate)
		var envelope: float = pow(1.0 - progress, 1.8)
		var target: float = randf_range(-1.0, 1.0)
		noise_state = lerpf(noise_state, target, 0.32)
		var wave: float = noise_state * (0.55 + harshness * 0.2)
		wave += sin(TAU * 64.0 * t) * 0.28
		wave += sin(TAU * 118.0 * t) * 0.18
		data.encode_s16(index * 2, int(clampf(wave * envelope, -1.0, 1.0) * 32767.0))

	return _build_wav(data, mix_rate, sample_count, false)


func _build_wav(data: PackedByteArray, mix_rate: int, sample_count: int, looped: bool) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	if looped:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_begin = 0
		stream.loop_end = sample_count
	return stream

