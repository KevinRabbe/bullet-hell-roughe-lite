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
const COLOR_TRAIL_BONE := Color(1.0, 0.80, 0.48, 0.82)
const COLOR_TRAIL_INFERNAL := Color(1.0, 0.30, 0.08, 0.86)
const COLOR_TRAIL_OCCULT := Color(0.94, 0.16, 0.46, 0.82)
const COLOR_TRAIL_HIGH_CONTRAST := Color(1.0, 0.92, 0.72, 0.94)
const IMPACT_RING_SEGMENTS := 16

static func build_profile(weapon_data: WeaponData) -> Dictionary:
	var profile := {
		"spin_speed": 0.0,
		"pulse_amount": 0.02,
		"pulse_speed": 5.0,
		"brightness_amount": 0.04,
		"impact_scale": 1.35,
		"impact_duration": 0.10,
		"impact_color": COLOR_TRAIL_BONE,
		"trail_enabled": false,
		"trail_length": 14.0,
		"trail_width": 2.0,
		"trail_color": COLOR_TRAIL_BONE
	}
	if weapon_data == null:
		return profile
	var tags := WeaponTagUtil.weapon_tags(weapon_data)
	if "thrown" in tags:
		profile["spin_speed"] = 7.0
		profile["trail_enabled"] = true
		profile["trail_length"] = 16.0
		profile["trail_width"] = 2.5
		profile["trail_color"] = COLOR_TRAIL_OCCULT
	elif "orbit" in tags:
		profile["spin_speed"] = 2.4
	if _contains_any(tags, ARCANE_TAGS):
		profile["pulse_amount"] = 0.08
		profile["brightness_amount"] = 0.14
		profile["impact_scale"] = 1.5
		profile["impact_color"] = COLOR_TRAIL_INFERNAL if "hellfire" in tags or "burn" in tags else COLOR_TRAIL_OCCULT
		profile["trail_enabled"] = true
		profile["trail_length"] = 20.0
		profile["trail_width"] = 3.0
		profile["trail_color"] = COLOR_TRAIL_INFERNAL if "hellfire" in tags or "burn" in tags else COLOR_TRAIL_OCCULT
	if "rapid" in tags:
		profile["pulse_speed"] = 9.0
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.07)
		profile["impact_scale"] = minf(float(profile["impact_scale"]), 1.22)
		profile["impact_duration"] = 0.07
		profile["trail_enabled"] = true
		profile["trail_length"] = 10.0
		profile["trail_width"] = 1.4
		profile["trail_color"] = COLOR_TRAIL_BONE
	elif "heavy" in tags:
		profile["pulse_speed"] = 3.5
		profile["brightness_amount"] = maxf(float(profile["brightness_amount"]), 0.06)
		profile["impact_scale"] = maxf(float(profile["impact_scale"]), 1.7)
		profile["impact_duration"] = 0.14
		profile["trail_enabled"] = true
		profile["trail_length"] = 28.0
		profile["trail_width"] = 4.0
	return profile

static func create_trail(profile: Dictionary) -> Line2D:
	if profile.get("trail_enabled", false) != true:
		return null
	var length := maxf(float(profile.get("trail_length", 14.0)), 2.0)
	var width := maxf(float(profile.get("trail_width", 2.0)), 0.5)
	var color_variant: Variant = profile.get("trail_color", COLOR_TRAIL_BONE)
	var color := color_variant as Color if color_variant is Color else COLOR_TRAIL_BONE
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		color = COLOR_TRAIL_HIGH_CONTRAST
	var gradient := Gradient.new()
	var transparent_color := color
	transparent_color.a = 0.0
	gradient.set_color(0, transparent_color)
	gradient.set_color(1, color)
	var trail := Line2D.new()
	trail.points = PackedVector2Array([Vector2(-length, 0.0), Vector2.ZERO])
	trail.width = width
	trail.gradient = gradient
	trail.z_index = -1
	return trail

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
	_spawn_impact_ring(scene, projectile, profile, duration)
	var tween := impact.create_tween()
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(impact, "modulate:a", 0.0, duration)
	else:
		var impact_scale := maxf(float(profile.get("impact_scale", 1.35)), 1.0)
		tween.tween_property(impact, "scale", impact.scale * impact_scale, duration)
		tween.parallel().tween_property(impact, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(impact):
			impact.queue_free()
	)

static func _spawn_impact_ring(scene: Node, projectile: Node2D, profile: Dictionary, duration: float) -> void:
	var color_variant: Variant = profile.get("impact_color", COLOR_TRAIL_BONE)
	var color := color_variant as Color if color_variant is Color else COLOR_TRAIL_BONE
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		color = COLOR_TRAIL_HIGH_CONTRAST

	var ring := Line2D.new()
	ring.points = _build_ring_points(7.0, IMPACT_RING_SEGMENTS)
	ring.closed = true
	ring.width = 2.0
	ring.default_color = color
	ring.global_position = projectile.global_position
	ring.z_index = projectile.z_index + 2
	scene.add_child(ring)

	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		var impact_scale := maxf(float(profile.get("impact_scale", 1.35)), 1.0)
		tween.tween_property(ring, "scale", Vector2.ONE * impact_scale, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

static func _build_ring_points(radius: float, segment_count: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	var safe_segment_count := maxi(segment_count, 3)
	for index in safe_segment_count:
		var angle := TAU * (float(index) / float(safe_segment_count))
		points.append(Vector2.from_angle(angle) * radius)
	return points

static func _contains_any(tags: Array[String], candidates: Array[String]) -> bool:
	for candidate in candidates:
		if candidate in tags:
			return true
	return false
