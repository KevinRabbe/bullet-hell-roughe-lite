class_name AccessibilitySettingsRuntime
extends RefCounted

const CONFIG_PATH := "user://accessibility_settings.cfg"
const ACCESSIBILITY_SECTION := "accessibility"
const KEY_LARGE_TEXT := "large_text"
const KEY_REDUCED_MOTION := "reduced_motion"
const KEY_HIGH_CONTRAST := "high_contrast"

static var _active_settings: Dictionary = {}

static func default_settings() -> Dictionary:
	return {
		"large_text": false,
		"reduced_motion": false,
		"high_contrast": false
	}

static func load_settings() -> Dictionary:
	var result: Dictionary = default_settings()
	var config := ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		_active_settings = clone_settings(result)
		return result
	result["large_text"] = config.get_value(ACCESSIBILITY_SECTION, KEY_LARGE_TEXT, false) == true
	result["reduced_motion"] = config.get_value(ACCESSIBILITY_SECTION, KEY_REDUCED_MOTION, false) == true
	result["high_contrast"] = config.get_value(ACCESSIBILITY_SECTION, KEY_HIGH_CONTRAST, false) == true
	_active_settings = clone_settings(result)
	return result

static func save_settings(settings: Dictionary) -> void:
	var normalized: Dictionary = normalize_settings(settings)
	var config := ConfigFile.new()
	config.set_value(ACCESSIBILITY_SECTION, KEY_LARGE_TEXT, normalized["large_text"])
	config.set_value(ACCESSIBILITY_SECTION, KEY_REDUCED_MOTION, normalized["reduced_motion"])
	config.set_value(ACCESSIBILITY_SECTION, KEY_HIGH_CONTRAST, normalized["high_contrast"])
	config.save(CONFIG_PATH)
	_active_settings = clone_settings(normalized)

static func apply_saved_settings() -> Dictionary:
	var settings: Dictionary = load_settings()
	apply_settings(settings)
	return settings

static func apply_settings(settings: Dictionary) -> Dictionary:
	_active_settings = normalize_settings(settings)
	return clone_settings(_active_settings)

static func clone_settings(settings: Dictionary) -> Dictionary:
	return normalize_settings(settings).duplicate(true)

static func settings_match(left: Dictionary, right: Dictionary) -> bool:
	var left_normalized: Dictionary = normalize_settings(left)
	var right_normalized: Dictionary = normalize_settings(right)
	return left_normalized["large_text"] == right_normalized["large_text"] \
		and left_normalized["reduced_motion"] == right_normalized["reduced_motion"] \
		and left_normalized["high_contrast"] == right_normalized["high_contrast"]

static func toggle_flag(settings: Dictionary, key: String) -> Dictionary:
	var result: Dictionary = normalize_settings(settings)
	if not result.has(key):
		return result
	result[key] = result.get(key, false) != true
	return result

static func normalize_settings(settings: Dictionary) -> Dictionary:
	var normalized: Dictionary = default_settings()
	normalized["large_text"] = settings.get("large_text", false) == true
	normalized["reduced_motion"] = settings.get("reduced_motion", false) == true
	normalized["high_contrast"] = settings.get("high_contrast", false) == true
	return normalized

static func get_active_settings() -> Dictionary:
	if _active_settings.is_empty():
		_active_settings = default_settings()
	return clone_settings(_active_settings)

static func is_large_text_enabled(settings: Dictionary = {}) -> bool:
	var source: Dictionary = get_active_settings() if settings.is_empty() else normalize_settings(settings)
	return source["large_text"] == true

static func is_reduced_motion_enabled(settings: Dictionary = {}) -> bool:
	var source: Dictionary = get_active_settings() if settings.is_empty() else normalize_settings(settings)
	return source["reduced_motion"] == true

static func is_high_contrast_enabled(settings: Dictionary = {}) -> bool:
	var source: Dictionary = get_active_settings() if settings.is_empty() else normalize_settings(settings)
	return source["high_contrast"] == true

static func get_font_scale(settings: Dictionary = {}) -> float:
	return 1.12 if is_large_text_enabled(settings) else 1.0

static func scale_font(base_size: int, settings: Dictionary = {}) -> int:
	return int(round(float(base_size) * get_font_scale(settings)))

static func build_summary(settings: Dictionary) -> String:
	var normalized: Dictionary = normalize_settings(settings)
	var tags: Array[String] = []
	if normalized["large_text"] == true:
		tags.append("Large Text")
	if normalized["reduced_motion"] == true:
		tags.append("Reduced Motion")
	if normalized["high_contrast"] == true:
		tags.append("High Contrast")
	return "Standard" if tags.is_empty() else ", ".join(tags)
