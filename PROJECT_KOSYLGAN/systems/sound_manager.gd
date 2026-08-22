extends Node

# Procedural Sound Manager for PROJECT: KOSYLGAN
# Generates and plays audio effects in pure GDScript (zero external assets needed)

var sfx_players: Array[AudioStreamPlayer] = []
var max_players: int = 8

var sample_rate: int = 22050

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in range(max_players):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func _get_free_player() -> AudioStreamPlayer:
	for p in sfx_players:
		if not p.playing:
			return p
	return sfx_players[0]

func _create_wav(samples: PackedByteArray) -> AudioStreamWAV:
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = samples
	return wav

# 1. Footstep (soft mechanical tap)
func play_footstep(volume_db: float = -14.0) -> void:
	var duration = 0.05
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = 1.0 - (float(i) / num_samples)
		var freq = 120.0 - (t * 800.0)
		var s = sin(t * freq * TAU) * 0.4
		s += (randf() * 2.0 - 1.0) * 0.2
		var val = int(clamp(s * env * 18000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = volume_db
	player.pitch_scale = randf_range(0.9, 1.1)
	player.play()

# 2. Robot Switch (futuristic chirp)
func play_switch() -> void:
	var duration = 0.18
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = sin((float(i) / num_samples) * PI)
		var freq = 440.0 + (t * 2200.0)
		var s = sin(t * freq * TAU) * 0.5 + sin(t * freq * 2.0 * TAU) * 0.25
		var val = int(clamp(s * env * 24000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -6.0
	player.pitch_scale = 1.0
	player.play()

# 3. Lift Object (mechanical servo whirr)
func play_pickup() -> void:
	var duration = 0.28
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = sin((float(i) / num_samples) * PI)
		var freq = 200.0 + (t * 600.0)
		var s = sin(t * freq * TAU) * 0.6
		s += sin(t * 50.0 * TAU) * 0.2 # vibration
		var val = int(clamp(s * env * 26000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -5.0
	player.play()

# 4. Drop Box (heavy bass thud)
func play_drop() -> void:
	var duration = 0.22
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = pow(1.0 - (float(i) / num_samples), 2.0)
		var freq = 110.0 - (t * 300.0)
		var s = sin(t * max(30.0, freq) * TAU) * 0.8
		s += (randf() * 2.0 - 1.0) * 0.3
		var val = int(clamp(s * env * 30000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -3.0
	player.pitch_scale = randf_range(0.95, 1.05)
	player.play()

# 5. Wire Cut (sharp mechanical snip)
func play_cut() -> void:
	var duration = 0.12
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = pow(1.0 - (float(i) / num_samples), 3.0)
		var s = (randf() * 2.0 - 1.0) * 0.8 + sin(t * 1200.0 * TAU) * 0.3
		var val = int(clamp(s * env * 28000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -4.0
	player.pitch_scale = randf_range(0.95, 1.1)
	player.play()

# 6. Electrical Spark / Error Buzz
func play_spark_error() -> void:
	var duration = 0.35
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = 1.0 - (float(i) / num_samples)
		var freq = 60.0 # 60Hz buzz
		var s = 0.7 if sin(t * freq * TAU) > 0 else -0.7
		s += (randf() * 2.0 - 1.0) * 0.5
		var val = int(clamp(s * env * 28000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -2.0
	player.play()

# 7. Success Chime / Laser Deactivated
func play_success() -> void:
	var duration = 0.6
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = 1.0 - (float(i) / num_samples)
		var freq = 523.25 if t < 0.18 else (659.25 if t < 0.36 else 783.99) # C - E - G chord
		var s = sin(t * freq * TAU) * 0.6 + sin(t * freq * 2.0 * TAU) * 0.2
		var val = int(clamp(s * env * 25000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -4.0
	player.play()

# 8. Guide Tablet Pickup / Reading
func play_tablet_read() -> void:
	var duration = 0.25
	var num_samples = int(sample_rate * duration)
	var bytes = PackedByteArray()
	bytes.resize(num_samples * 2)
	
	for i in range(num_samples):
		var t = float(i) / sample_rate
		var env = sin((float(i) / num_samples) * PI)
		var freq = 600.0 + (t * 800.0)
		var s = sin(t * freq * TAU) * 0.5
		var val = int(clamp(s * env * 24000.0, -32767, 32767))
		bytes.encode_s16(i * 2, val)
	
	var player = _get_free_player()
	player.stream = _create_wav(bytes)
	player.volume_db = -6.0
	player.play()
