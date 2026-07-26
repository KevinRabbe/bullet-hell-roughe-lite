extends RefCounted

const WeaponTagUtil = preload("res://scripts/weapons/weapon_tag_runtime.gd")
const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const ARCANE_TAGS: Array[String] = [
	"magic",
	"portal",
	"hellfire",
	"ritual",
	"necromancy",
	"curse"
]

static func build_profile(weapon_data: WeaponData) -> Dictionary:
	var profile := {
		"spin_speed": 0.0,
		"pulse_amount": 0.02,
		"pulse_speed": 5.0,
		"brightness_amount": 0.04
	}
	if weapon_data == null:
		return profile
	var tags := WeaponTagUtil.weapon_tags(weapon_data)
	if "thrown" in tags:
		profile["spin_speed"] = 7.0
	elif "orbit" in tags:
		profile["spin_speed"] = 2.4
	if _contains_any(tags, ARCANE_TAGS):
		profile["pulse_amount"] = 0.08
		profile["brightness_amount"] = 0.14
	if "rapid" in tags:
		profile["pulse_speed"] = 9.0
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.07)
	elif "heavy" in tags:
		profile["pulse_speed"] = 3.5
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.06)
	return profile

static func sample_scale_multiplier(profile: Dictionary, elapsed: float, phase: float) -> float:
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return 1.0
	var pulse_amount := float(profile.get("pulse_amount", 0.0))
	if is_zero_approx(pulse_amount):
		return 1.0
	var pulse_speed := float(profile.get("pulse_speed", 5.0))
	return 1.0 + (sin((elapsed * pulse_speed) + phase) * pulse_amount)

static func sample_rotation_offset(profile: Dictionary, elapsed: float) -> float:
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return 0.0
	return elapsed * float(profile.get("spin_speed", 0.0))

static func sample_modulate(profile: Dictionary, elapsed: float, phase: float, base_modulate: Color) -> Color:
	var brightness_amount := float(profile.get("brightness_amount", 0.0))
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		brightness_amount = maxf(brightness_amount, 0.16)
	if brightness_amount <= 0.0:
		return base_modulate
	var pulse_speed := float(profile.get("pulse_speed", 5.0))
	var wave := (sin((elapsed * pulse_speed) + phase) + 1.0) * 0.5
	var factor := 1.0 + (brightness_amount * wave)
	return Color(
		base_modulate.r * factor,
		base_modulate.g * factor,
		base_modulate.b * factor,
		base_modulate.a
	)

static func _contains_any(tags: Array[String], candidates: Array[String]) -> bool:
	for candidate in candidates:
		if candidate in tags:
			return true
	return false
