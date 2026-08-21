# res://game/scripts/AudioManager.gd
extends Node

## Процедурный аудио-менеджер: генерирует все SFX прямо в памяти (без файлов).
## Использует AudioStreamWAV с сгенерированными PCM-семплами.
## Подписан на глобальные сигналы EventBus и играет соответствующий звук.

const SAMPLE_RATE: int = 22050
const MAX_POLYPHONY: int = 8

var _players: Array[AudioStreamPlayer] = []
var _next_player: int = 0

# Заранее сгенерированные стримы
var sfx_release: AudioStreamWAV
var sfx_socket: AudioStreamWAV
var sfx_death: AudioStreamWAV
var sfx_lowbattery: AudioStreamWAV
var sfx_ui_click: AudioStreamWAV
var sfx_victory: AudioStreamWAV

var _lowbattery_playing: bool = false
var _music_player: AudioStreamPlayer

func _ready() -> void:
	# Пул плееров для SFX
	for i in range(MAX_POLYPHONY):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	# Отдельный плеер для фоновой ambient
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -14.0
	add_child(_music_player)

	# Генерируем банки SFX
	sfx_release = _generate_release_sfx()
	sfx_socket = _generate_socket_sfx()
	sfx_death = _generate_death_sfx()
	sfx_lowbattery = _generate_lowbattery_sfx()
	sfx_ui_click = _generate_ui_click_sfx()
	sfx_victory = _generate_victory_sfx()

	# Подписки
	EventBus.tether_broken.connect(_on_tether_broken)
	EventBus.socket_reached.connect(_on_socket_reached)
	EventBus.player_died.connect(_on_player_died)
	EventBus.level_completed.connect(_on_level_completed)
	EventBus.battery_changed.connect(_on_battery_changed)

# ---------------------------------------------------------
# Публичный API
# ---------------------------------------------------------

func play(stream: AudioStream, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	var p := _players[_next_player]
	_next_player = (_next_player + 1) % MAX_POLYPHONY
	p.stream = stream
	p.pitch_scale = pitch
	p.volume_db = volume_db
	p.play()

func play_ui_click() -> void:
	play(sfx_ui_click, 1.0, -4.0)

# ---------------------------------------------------------
# Реакции на события
# ---------------------------------------------------------

func _on_tether_broken(_impulse: Vector2, tension: float) -> void:
	# Питч зависит от натяжения: сильнее натянут — выше рывок
	var p: float = lerpf(0.9, 1.25, clampf(tension, 0.0, 1.0))
	play(sfx_release, p, -2.0)

func _on_socket_reached(_pos: Vector2, _progress_value: int) -> void:
	play(sfx_socket, 1.0, -3.0)

func _on_player_died() -> void:
	play(sfx_death, 1.0, -1.0)

func _on_level_completed() -> void:
	play(sfx_victory, 1.0, 0.0)

func _on_battery_changed(current: float, _max_val: float) -> void:
	# Тревожный писк при батарее < 2 сек
	if current > 0.0 and current < 2.0 and not _lowbattery_playing:
		_lowbattery_playing = true
		play(sfx_lowbattery, 1.0, -6.0)
		get_tree().create_timer(0.35).timeout.connect(func(): _lowbattery_playing = false)

# ---------------------------------------------------------
# ГЕНЕРАТОРЫ ЗВУКА
# ---------------------------------------------------------

func _make_stream(samples: PackedFloat32Array) -> AudioStreamWAV:
	# PCM 16-bit mono
	var byte_data := PackedByteArray()
	byte_data.resize(samples.size() * 2)
	for i in range(samples.size()):
		var v: float = clampf(samples[i], -1.0, 1.0)
		var s16: int = int(v * 32767.0)
		if s16 < 0:
			s16 += 65536
		byte_data[i * 2] = s16 & 0xFF
		byte_data[i * 2 + 1] = (s16 >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = SAMPLE_RATE
	wav.stereo = false
	wav.data = byte_data
	return wav

# Резкий "клик отрыва": короткая волна пилы с ниспадающим питчем + шум-хвост
func _generate_release_sfx() -> AudioStreamWAV:
	var dur := 0.28
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 4242
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-6.0 * t)                       # затухание
		var freq: float = lerpf(680.0, 220.0, clampf(t / dur, 0.0, 1.0))
		var phase := fmod(t * freq, 1.0)
		var saw := (phase - 0.5) * 2.0                 # -1..1
		var noise := (rng.randf() - 0.5) * 0.35
		samples[i] = (saw * 0.75 + noise) * env * 0.9
	return _make_stream(samples)

# "Щелчок стыковки": короткий колокольчик с быстрой атакой
func _generate_socket_sfx() -> AudioStreamWAV:
	var dur := 0.45
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-5.5 * t)
		var s := sin(TAU * 880.0 * t) * 0.6 + sin(TAU * 1320.0 * t) * 0.35 + sin(TAU * 1760.0 * t) * 0.2
		samples[i] = s * env * 0.6
	return _make_stream(samples)

# "Смерть": шум + низкая пила
func _generate_death_sfx() -> AudioStreamWAV:
	var dur := 0.55
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-3.5 * t)
		var freq: float = lerpf(320.0, 80.0, clampf(t / dur, 0.0, 1.0))
		var phase := fmod(t * freq, 1.0)
		var saw := (phase - 0.5) * 2.0
		var noise := (rng.randf() - 0.5) * 0.7
		samples[i] = (saw * 0.55 + noise * 0.55) * env
	return _make_stream(samples)

# Короткий писк тревоги
func _generate_lowbattery_sfx() -> AudioStreamWAV:
	var dur := 0.12
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := sin(PI * clampf(t / dur, 0.0, 1.0))
		samples[i] = sin(TAU * 1200.0 * t) * env * 0.6
	return _make_stream(samples)

# UI click
func _generate_ui_click_sfx() -> AudioStreamWAV:
	var dur := 0.08
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var env := exp(-25.0 * t)
		samples[i] = sin(TAU * 660.0 * t) * env * 0.6
	return _make_stream(samples)

# Победная арпеджированная фанфара
func _generate_victory_sfx() -> AudioStreamWAV:
	var dur := 1.2
	var count := int(dur * SAMPLE_RATE)
	var samples := PackedFloat32Array()
	samples.resize(count)
	# C-E-G-C арпеджио
	var notes := [523.25, 659.25, 783.99, 1046.50]
	var note_len := dur / notes.size()
	for i in range(count):
		var t := float(i) / SAMPLE_RATE
		var idx: int = clampi(int(t / note_len), 0, notes.size() - 1)
		var local_t := t - idx * note_len
		var env := exp(-3.5 * local_t)
		var f: float = notes[idx]
		var s := sin(TAU * f * t) * 0.55 + sin(TAU * f * 2.0 * t) * 0.25
		samples[i] = s * env * 0.55
	return _make_stream(samples)
