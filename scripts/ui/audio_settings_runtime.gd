extends RefCounted

const CONFIG_PATH := "user://audio_settings.cfg"
const AUDIO_SECTION := "audio"
const KEY_MASTER := "master"
const KEY_MUSIC := "music"
const KEY_SFX := "sfx"
const KEY_AMBIENCE := "ambience"
const KEY_MUTED := "muted"
const STEP := 0.1
const MIN_LEVEL := 0.0
const MAX_LEVEL := 1.0
const MIN_DB := -80.0

const BUS_BY_KEY := {
	"master": "Master",
	"music": "Music",
	"sfx": "SFX",
	"ambience": "Ambience"
}

static func default_settings() -> Dictionary:
	return {
		"master": 1.0,
		"music": 1.0,
		"sfx": 1.0,
		"ambience": 1.0,
		"muted": false
	}

static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var result := default_settings()
	var load_error := config.load(CONFIG_PATH)
	if load_error != OK:
		return result
	for key in [KEY_MASTER, KEY_MUSIC, KEY_SFX, KEY_AMBIENCE]:
		result[key] = clampf(float(config.get_value(AUDIO_SECTION, key, result[key])), MIN_LEVEL, MAX_LEVEL)
	result[KEY_MUTED] = config.get_value(AUDIO_SECTION, KEY_MUTED, false) == true
	return result

static func save_settings(settings: Dictionary) -> void:
	var config := ConfigFile.new()
	for key in [KEY_MASTER, KEY_MUSIC, KEY_SFX, KEY_AMBIENCE]:
		config.set_value(AUDIO_SECTION, key, _normalized_level(settings, key))
	config.set_value(AUDIO_SECTION, KEY_MUTED, settings.get(KEY_MUTED, false) == true)
	config.save(CONFIG_PATH)

static func apply_saved_settings() -> Dictionary:
	var settings := load_settings()
	apply_settings(settings)
	return settings

static func apply_settings(settings: Dictionary) -> void:
	var muted: bool = settings.get(KEY_MUTED, false) == true
	for key in BUS_BY_KEY.keys():
		var bus_name: String = str(BUS_BY_KEY[key])
		var bus_index: int = AudioServer.get_bus_index(bus_name)
		if bus_index < 0:
			continue
		var level: float = 0.0 if muted else _normalized_level(settings, key)
		AudioServer.set_bus_volume_db(bus_index, _linear_to_db(level))

static func clone_settings(settings: Dictionary) -> Dictionary:
	return {
		KEY_MASTER: _normalized_level(settings, KEY_MASTER),
		KEY_MUSIC: _normalized_level(settings, KEY_MUSIC),
		KEY_SFX: _normalized_level(settings, KEY_SFX),
		KEY_AMBIENCE: _normalized_level(settings, KEY_AMBIENCE),
		KEY_MUTED: settings.get(KEY_MUTED, false) == true
	}

static func settings_match(left: Dictionary, right: Dictionary) -> bool:
	for key in [KEY_MASTER, KEY_MUSIC, KEY_SFX, KEY_AMBIENCE]:
		if not is_equal_approx(_normalized_level(left, key), _normalized_level(right, key)):
			return false
	return left.get(KEY_MUTED, false) == right.get(KEY_MUTED, false)

static func set_level(settings: Dictionary, key: String, level: float) -> Dictionary:
	var normalized := clone_settings(settings)
	if BUS_BY_KEY.has(key):
		normalized[key] = clampf(level, MIN_LEVEL, MAX_LEVEL)
	return normalized

static func cycle_level(settings: Dictionary, key: String, direction: int) -> Dictionary:
	var current: float = _normalized_level(settings, key)
	return set_level(settings, key, current + (STEP * direction))

static func toggle_muted(settings: Dictionary) -> Dictionary:
	var normalized := clone_settings(settings)
	normalized[KEY_MUTED] = normalized.get(KEY_MUTED, false) != true
	return normalized

static func build_summary(settings: Dictionary) -> String:
	var muted: bool = settings.get(KEY_MUTED, false) == true
	return "%s | Master %s | Music %s | SFX %s | Ambience %s" % [
		"Muted" if muted else "Live",
		_percent_text(_normalized_level(settings, KEY_MASTER)),
		_percent_text(_normalized_level(settings, KEY_MUSIC)),
		_percent_text(_normalized_level(settings, KEY_SFX)),
		_percent_text(_normalized_level(settings, KEY_AMBIENCE))
	]

static func _normalized_level(settings: Dictionary, key: String) -> float:
	return clampf(float(settings.get(key, default_settings().get(key, 1.0))), MIN_LEVEL, MAX_LEVEL)

static func _linear_to_db(level: float) -> float:
	if level <= 0.0001:
		return MIN_DB
	return linear_to_db(level)

static func _percent_text(level: float) -> String:
	return "%d%%" % int(round(level * 100.0))
