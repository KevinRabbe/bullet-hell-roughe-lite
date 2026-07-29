class_name SfxRuntime
extends Node

const SAMPLE_RATE := 22050
const MAX_ACTIVE_PLAYERS := 12
const RUNTIME_NODE_NAME := "HellshotSfxRuntime"

var _stream_cache: Dictionary = {}
var _last_played_ms: Dictionary = {}

static func play(
	owner: Node,
	cue: String,
	volume_db: float = -12.0,
	pitch_scale: float = 1.0,
	minimum_interval_ms: int = 0
) -> void:
	var runtime: SfxRuntime = _ensure_runtime(owner)
	if runtime == null:
		return
	runtime._play(cue, volume_db, pitch_scale, minimum_interval_ms)

static func _ensure_runtime(owner: Node) -> SfxRuntime:
	if owner == null or not is_instance_valid(owner) or owner.get_tree() == null:
		return null
	var scene := owner.get_tree().current_scene
	if scene == null:
		return null
	var existing := scene.get_node_or_null(RUNTIME_NODE_NAME)
	if existing is SfxRuntime:
		return existing
	var runtime := SfxRuntime.new()
	runtime.name = RUNTIME_NODE_NAME
	runtime.process_mode = Node.PROCESS_MODE_ALWAYS
	scene.add_child(runtime)
	return runtime

func _play(cue: String, volume_db: float, pitch_scale: float, minimum_interval_ms: int) -> void:
	if cue == "" or get_child_count() >= MAX_ACTIVE_PLAYERS:
		return
	var now_ms := Time.get_ticks_msec()
	if minimum_interval_ms > 0:
		var last_ms := int(_last_played_ms.get(cue, -minimum_interval_ms))
		if now_ms - last_ms < minimum_interval_ms:
			return
		_last_played_ms[cue] = now_ms
	var stream := _get_stream(cue)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = clampf(pitch_scale, 0.5, 2.0)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.finished.connect(player.queue_free)
	player.play()

func _get_stream(cue: String) -> AudioStreamWAV:
	var cached: Variant = _stream_cache.get(cue)
	if cached is AudioStreamWAV:
		return cached as AudioStreamWAV
	var duration := _cue_duration(cue)
	if duration <= 0.0:
		return null
	var stream := _build_stream(cue, duration)
	_stream_cache[cue] = stream
	return stream

func _build_stream(cue: String, duration: float) -> AudioStreamWAV:
	var sample_count := maxi(int(ceil(duration * SAMPLE_RATE)), 1)
	var bytes := PackedByteArray()
	bytes.resize(sample_count * 2)
	for index in range(sample_count):
		var t := float(index) / float(SAMPLE_RATE)
		var sample := clampf(_sample_cue(cue, t, duration, index), -0.92, 0.92)
		var pcm := int(round(sample * 32767.0))
		bytes.encode_s16(index * 2, pcm)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = bytes
	return stream

func _cue_duration(cue: String) -> float:
	match cue:
		"projectile_launch":
			return 0.13
		"impact":
			return 0.10
		"player_hit":
			return 0.18
		"portal_event":
			return 0.48
		"portal_reward":
			return 0.36
		"boss_spawn":
			return 0.68
		"boss_windup":
			return 0.28
		"boss_defeat":
			return 0.58
		_:
			return 0.0

func _sample_cue(cue: String, t: float, duration: float, index: int) -> float:
	var progress := clampf(t / maxf(duration, 0.001), 0.0, 1.0)
	match cue:
		"projectile_launch":
			var body := sin(TAU * (115.0 * t - 18.0 * t * t)) * exp(-t * 19.0) * 0.52
			var crack := _noise(index) * exp(-t * 34.0) * 0.36
			var snap := sin(TAU * 1450.0 * t) * exp(-t * 52.0) * 0.18
			return body + crack + snap
		"impact":
			var metal := (sin(TAU * 980.0 * t) + (0.52 * sin(TAU * 1640.0 * t))) * exp(-t * 31.0) * 0.34
			return metal + (_noise(index) * exp(-t * 42.0) * 0.24)
		"player_hit":
			var thump := sin(TAU * (78.0 * t - 22.0 * t * t)) * exp(-t * 15.0) * 0.58
			return thump + (_noise(index) * exp(-t * 28.0) * 0.30)
		"portal_event":
			var fade := sin(PI * progress)
			var phase := (150.0 * t) + (250.0 * t * t)
			return (sin(TAU * phase) * 0.38 + sin(TAU * phase * 1.51) * 0.18 + sin(TAU * 62.0 * t) * 0.16) * fade
		"portal_reward":
			return _chime(t, 0.00, 520.0) + _chime(t, 0.085, 660.0) + _chime(t, 0.17, 840.0)
		"boss_spawn":
			var swell := sin(PI * minf(progress * 1.3, 1.0)) * exp(-progress * 0.65)
			var rumble := sin(TAU * 48.0 * t) * 0.48 + sin(TAU * 72.0 * t) * 0.24
			return (rumble + (_noise(index) * 0.16)) * swell
		"boss_windup":
			var phase := (105.0 * t) + (520.0 * t * t)
			return (sin(TAU * phase) * 0.52 + sin(TAU * phase * 2.0) * 0.14) * sin(PI * progress)
		"boss_defeat":
			var fall_phase := (105.0 * t) - (58.0 * t * t)
			var fall := sin(TAU * fall_phase) * exp(-t * 3.4) * 0.50
			var fracture := _noise(index) * exp(-t * 7.0) * 0.24
			return (fall + fracture) * (1.0 - (progress * 0.35))
		_:
			return 0.0

func _chime(t: float, start: float, frequency: float) -> float:
	var local_t := t - start
	if local_t < 0.0:
		return 0.0
	return (
		sin(TAU * frequency * local_t)
		+ (0.35 * sin(TAU * frequency * 2.0 * local_t))
	) * exp(-local_t * 11.5) * 0.22

func _noise(index: int) -> float:
	var raw := sin((float(index) + 1.0) * 12.9898) * 43758.5453
	return ((raw - floor(raw)) * 2.0) - 1.0
