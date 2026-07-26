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
		"brightness_amount": 0.04,
		"impact_scale": 1.35,
		"impact_duration": 0.10
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
		profile["impact_scale"] = 1.5
	if "rapid" in tags:
		profile["pulse_speed"] = 9.0
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.07)
		profile["impact_scale"] = minf(float(profile["impact_scale"]), 1.22)
		profile["impact_duration"] = 0.07
	elif "heavy" in tags:
		profile["pulse_speed"] = 3.5
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.06)
		profile["impact_scale"] = maxf(float(profile["impact_scale"]), 1.7)
		profile["impact_duration"] = 0.14
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

static func spawn_impact_feedback(projectile: Node2D, visual: Sprite2D, profile: Dictionary) -> void:
	if projectile == null or not is_instance_valid(projectile) or projectile.get_tree() == null:
		return
	var scene := projectile.get_tree().current_scene
	if scene == null:
		return
	var impact := Sprite2D.new()
	impact.global_position = projectile.global_position
	impact.global_rotation = projectile.global_rotation
	impact.z_index = projectile.z_index + 1
	if visual != null and visual.texture != null:
		impact.texture = visual.texture
		impact.scale = visual.scale * 0.72
	else:
		impact.scale = Vector2.ONE * 0.12
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
	impact.modulate = Color(1.0, 0.92, 0.78, 1.0) if high_contrast else Color(1.0, 0.76, 0.42, 0.9)
	scene.add_child(impact)

	var duration := maxf(float(profile.get("impact_duration", 0.10)), 0.04)
	var tween := impact.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		var impact_scale := maxf(float(profile.get("impact_scale", 1.35)), 1.0)
		tween.tween_property(impact, "scale", impact.scale * impact_scale, duration)
	tween.parallel().tween_property(impact, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(impact):
			impact.queue_free()
	)

static func _contains_any(tags: Array[String], candidates: Array[String]) -> bool:
	for candidate in candidates:
		if candidate in tags:
			return true
	return false
