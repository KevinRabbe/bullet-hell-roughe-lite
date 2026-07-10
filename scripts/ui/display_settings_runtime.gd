extends RefCounted

const CONFIG_PATH := "user://display_settings.cfg"
const DISPLAY_SECTION := "display"
const KEY_WIDTH := "width"
const KEY_HEIGHT := "height"
const KEY_FULLSCREEN := "fullscreen"
const DEFAULT_RESOLUTION := Vector2i(1280, 720)
const MIN_RESOLUTION := Vector2i(1280, 720)
const RESOLUTION_PRESETS: Array[Vector2i] = [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080)
]

static func default_settings() -> Dictionary:
	return {
		"resolution": DEFAULT_RESOLUTION,
		"fullscreen": false
	}

static func load_settings() -> Dictionary:
	var config := ConfigFile.new()
	var result := default_settings()
	var load_error := config.load(CONFIG_PATH)
	if load_error != OK:
		return result
	var width := max(int(config.get_value(DISPLAY_SECTION, KEY_WIDTH, DEFAULT_RESOLUTION.x)), MIN_RESOLUTION.x)
	var height := max(int(config.get_value(DISPLAY_SECTION, KEY_HEIGHT, DEFAULT_RESOLUTION.y)), MIN_RESOLUTION.y)
	result["resolution"] = _normalize_resolution(Vector2i(width, height))
	result["fullscreen"] = config.get_value(DISPLAY_SECTION, KEY_FULLSCREEN, false) == true
	return result

static func save_settings(settings: Dictionary) -> void:
	var config := ConfigFile.new()
	var resolution := _normalize_resolution(_extract_resolution(settings))
	config.set_value(DISPLAY_SECTION, KEY_WIDTH, resolution.x)
	config.set_value(DISPLAY_SECTION, KEY_HEIGHT, resolution.y)
	config.set_value(DISPLAY_SECTION, KEY_FULLSCREEN, settings.get("fullscreen", false) == true)
	config.save(CONFIG_PATH)

static func apply_saved_settings() -> Dictionary:
	var settings := load_settings()
	apply_settings(settings)
	return settings

static func apply_settings(settings: Dictionary) -> void:
	var resolution := _normalize_resolution(_extract_resolution(settings))
	var fullscreen := settings.get("fullscreen", false) == true
	DisplayServer.window_set_min_size(MIN_RESOLUTION)
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution)

static func cycle_resolution(settings: Dictionary, direction: int) -> Dictionary:
	var normalized := clone_settings(settings)
	var current := _normalize_resolution(_extract_resolution(settings))
	var current_index := RESOLUTION_PRESETS.find(current)
	if current_index < 0:
		current_index = 0
	var next_index := wrapi(current_index + direction, 0, RESOLUTION_PRESETS.size())
	normalized["resolution"] = RESOLUTION_PRESETS[next_index]
	return normalized

static func set_fullscreen(settings: Dictionary, enabled: bool) -> Dictionary:
	var normalized := clone_settings(settings)
	normalized["fullscreen"] = enabled
	return normalized

static func toggle_fullscreen(settings: Dictionary) -> Dictionary:
	return set_fullscreen(settings, settings.get("fullscreen", false) != true)

static func build_summary(settings: Dictionary) -> String:
	var resolution := _normalize_resolution(_extract_resolution(settings))
	var mode := "Fullscreen" if settings.get("fullscreen", false) == true else "Windowed"
	return "%s / %dx%d" % [mode, resolution.x, resolution.y]

static func get_resolution(settings: Dictionary) -> Vector2i:
	return _normalize_resolution(_extract_resolution(settings))

static func clone_settings(settings: Dictionary) -> Dictionary:
	return {
		"resolution": _normalize_resolution(_extract_resolution(settings)),
		"fullscreen": settings.get("fullscreen", false) == true
	}

static func settings_match(left: Dictionary, right: Dictionary) -> bool:
	var left_resolution := _normalize_resolution(_extract_resolution(left))
	var right_resolution := _normalize_resolution(_extract_resolution(right))
	return left_resolution == right_resolution and left.get("fullscreen", false) == right.get("fullscreen", false)

static func _extract_resolution(settings: Dictionary) -> Vector2i:
	var resolution_variant: Variant = settings.get("resolution", DEFAULT_RESOLUTION)
	if resolution_variant is Vector2i:
		return resolution_variant
	if resolution_variant is Vector2:
		var resolution_vector: Vector2 = resolution_variant
		return Vector2i(int(resolution_vector.x), int(resolution_vector.y))
	if resolution_variant is Array and resolution_variant.size() >= 2:
		return Vector2i(int(resolution_variant[0]), int(resolution_variant[1]))
	return DEFAULT_RESOLUTION

static func _normalize_resolution(resolution: Vector2i) -> Vector2i:
	if RESOLUTION_PRESETS.has(resolution):
		return resolution
	var fallback := DEFAULT_RESOLUTION
	for candidate in RESOLUTION_PRESETS:
		if candidate.x >= resolution.x and candidate.y >= resolution.y:
			fallback = candidate
			break
	return fallback
