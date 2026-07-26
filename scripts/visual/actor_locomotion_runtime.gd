class_name ActorLocomotionRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const META_REST_SCALE := "_actor_motion_rest_scale"
const META_REST_POSITION := "_actor_motion_rest_position"
const META_REST_ROTATION := "_actor_motion_rest_rotation"
const META_ELAPSED := "_actor_motion_elapsed"
const META_WARMUP := "_actor_motion_warmup"

static func capture_rest_pose(sprite: Sprite2D, warmup_seconds: float = 0.0) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	sprite.set_meta(META_REST_SCALE, sprite.scale)
	sprite.set_meta(META_REST_POSITION, sprite.position)
	sprite.set_meta(META_REST_ROTATION, sprite.rotation)
	sprite.set_meta(META_ELAPSED, 0.0)
	sprite.set_meta(META_WARMUP, maxf(warmup_seconds, 0.0))

static func update_visual(sprite: Sprite2D, velocity: Vector2, delta: float, profile_id: String) -> void:
	if sprite == null or not is_instance_valid(sprite) or delta <= 0.0:
		return
	_ensure_rest_pose(sprite)
	var warmup := maxf(float(sprite.get_meta(META_WARMUP, 0.0)), 0.0)
	if warmup > 0.0:
		sprite.set_meta(META_WARMUP, maxf(warmup - delta, 0.0))
		return

	var rest_scale: Vector2 = sprite.get_meta(META_REST_SCALE, sprite.scale)
	var rest_position: Vector2 = sprite.get_meta(META_REST_POSITION, sprite.position)
	var rest_rotation := float(sprite.get_meta(META_REST_ROTATION, sprite.rotation))
	_update_facing(sprite, velocity)

	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		sprite.position = rest_position
		sprite.scale = rest_scale
		sprite.rotation = rest_rotation
		return

	var elapsed := float(sprite.get_meta(META_ELAPSED, 0.0)) + delta
	sprite.set_meta(META_ELAPSED, elapsed)
	var profile := _profile(profile_id)
	var speed := velocity.length()
	var moving := speed > 4.0

	if moving:
		_apply_walk(sprite, rest_position, rest_scale, rest_rotation, velocity, elapsed, profile)
	else:
		_apply_idle(sprite, rest_position, rest_scale, rest_rotation, elapsed, profile)

static func settle_visual(sprite: Sprite2D) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	_ensure_rest_pose(sprite)
	sprite.position = sprite.get_meta(META_REST_POSITION, sprite.position)
	sprite.scale = sprite.get_meta(META_REST_SCALE, sprite.scale)
	sprite.rotation = float(sprite.get_meta(META_REST_ROTATION, sprite.rotation))

static func _apply_walk(
	sprite: Sprite2D,
	rest_position: Vector2,
	rest_scale: Vector2,
	rest_rotation: float,
	velocity: Vector2,
	elapsed: float,
	profile: Dictionary
) -> void:
	var reference_speed := maxf(float(profile.get("reference_speed", 200.0)), 1.0)
	var speed_ratio := clampf(velocity.length() / reference_speed, 0.35, 1.4)
	var cadence := float(profile.get("cadence", 8.0)) * lerpf(0.82, 1.12, clampf(speed_ratio, 0.0, 1.0))
	var phase := elapsed * cadence
	var stride := sin(phase)
	var lift := abs(stride)
	var compression := cos(phase * 2.0)
	var bob_px := float(profile.get("bob_px", 2.0)) * clampf(speed_ratio, 0.6, 1.15)
	var sway_px := float(profile.get("sway_px", 0.4))
	var squash := float(profile.get("squash", 0.03))
	var lean := float(profile.get("lean", 0.03))
	var x_direction := clampf(velocity.x / reference_speed, -1.0, 1.0)

	sprite.position = rest_position + Vector2(cos(phase) * sway_px, -lift * bob_px)
	var x_scale_multiplier := 1.0 + (compression * squash * 0.45)
	var y_scale_multiplier := 1.0 - (compression * squash)
	sprite.scale = Vector2(rest_scale.x * x_scale_multiplier, rest_scale.y * y_scale_multiplier)
	sprite.rotation = rest_rotation + (x_direction * lean) + (stride * lean * 0.18)

static func _apply_idle(
	sprite: Sprite2D,
	rest_position: Vector2,
	rest_scale: Vector2,
	rest_rotation: float,
	elapsed: float,
	profile: Dictionary
) -> void:
	var idle_speed := float(profile.get("idle_speed", 2.0))
	var idle_amount := float(profile.get("idle_amount", 0.012))
	var breath := sin(elapsed * idle_speed)
	sprite.position = rest_position + Vector2(0.0, breath * 0.45)
	sprite.scale = Vector2(
		rest_scale.x * (1.0 - (breath * idle_amount * 0.35)),
		rest_scale.y * (1.0 + (breath * idle_amount))
	)
	sprite.rotation = rest_rotation

static func _update_facing(sprite: Sprite2D, velocity: Vector2) -> void:
	if velocity.x < -2.0:
		sprite.flip_h = true
	elif velocity.x > 2.0:
		sprite.flip_h = false

static func _ensure_rest_pose(sprite: Sprite2D) -> void:
	if not sprite.has_meta(META_REST_SCALE):
		capture_rest_pose(sprite)

static func _profile(profile_id: String) -> Dictionary:
	match profile_id:
		"player":
			return {
				"reference_speed": 300.0,
				"cadence": 10.8,
				"bob_px": 3.0,
				"sway_px": 0.8,
				"squash": 0.040,
				"lean": 0.055,
				"idle_speed": 2.1,
				"idle_amount": 0.012
			}
		"imp_runner":
			return {
				"reference_speed": 190.0,
				"cadence": 13.5,
				"bob_px": 4.0,
				"sway_px": 0.8,
				"squash": 0.060,
				"lean": 0.065,
				"idle_speed": 2.8,
				"idle_amount": 0.016
			}
		"husk_brute":
			return {
				"reference_speed": 105.0,
				"cadence": 6.2,
				"bob_px": 3.0,
				"sway_px": 0.45,
				"squash": 0.052,
				"lean": 0.032,
				"idle_speed": 1.7,
				"idle_amount": 0.015
			}
		"spit_fiend":
			return {
				"reference_speed": 120.0,
				"cadence": 7.4,
				"bob_px": 2.3,
				"sway_px": 0.45,
				"squash": 0.032,
				"lean": 0.028,
				"idle_speed": 2.6,
				"idle_amount": 0.018
			}
		"skeleton_rifleman":
			return {
				"reference_speed": 125.0,
				"cadence": 7.8,
				"bob_px": 2.2,
				"sway_px": 0.35,
				"squash": 0.028,
				"lean": 0.040,
				"idle_speed": 2.0,
				"idle_amount": 0.010
			}
		"gate_beast":
			return {
				"reference_speed": 150.0,
				"cadence": 5.0,
				"bob_px": 3.7,
				"sway_px": 0.5,
				"squash": 0.055,
				"lean": 0.026,
				"idle_speed": 1.45,
				"idle_amount": 0.018
			}
		_:
			return {
				"reference_speed": 140.0,
				"cadence": 8.4,
				"bob_px": 2.6,
				"sway_px": 0.45,
				"squash": 0.038,
				"lean": 0.035,
				"idle_speed": 2.0,
				"idle_amount": 0.012
			}
