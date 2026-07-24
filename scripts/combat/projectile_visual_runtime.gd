extends RefCounted

const WeaponTagUtil = preload("res://scripts/weapons/weapon_tag_runtime.gd")

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
		"pulse_speed": 5.0
	}
	if weapon_data == null:
		return profile
	var tags := WeaponTagUtil.weapon_tags(weapon_data)
	if "thrown" in tags:
		profile["spin_speed"] = 7.0
	elif "orbit" in tags or "wave" in tags:
		profile["spin_speed"] = 2.4
	if _contains_any(tags, ARCANE_TAGS):
		profile["pulse_amount"] = 0.08
	if "rapid" in tags:
		profile["pulse_speed"] = 9.0
	elif "heavy" in tags:
		profile["pulse_speed"] = 3.5
	return profile

static func sample_scale_multiplier(profile: Dictionary, elapsed: float, phase: float) -> float:
	var pulse_amount := float(profile.get("pulse_amount", 0.0))
	if is_zero_approx(pulse_amount):
		return 1.0
	var pulse_speed := float(profile.get("pulse_speed", 5.0))
	return 1.0 + (sin((elapsed * pulse_speed) + phase) * pulse_amount)

static func _contains_any(tags: Array[String], candidates: Array[String]) -> bool:
	for candidate in candidates:
		if candidate in tags:
			return true
	return false
