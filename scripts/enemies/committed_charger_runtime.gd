class_name CommittedChargerRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_APPROACH := "approach"
const PHASE_WINDUP := "windup"
const PHASE_CHARGE := "charge"
const PHASE_RECOVER := "recover"

const APPROACH_SECONDS := 2.2
const WINDUP_SECONDS := 0.55
const CHARGE_SECONDS := 0.48
const RECOVER_SECONDS := 0.72
const CHARGE_SPEED_MULTIPLIER := 3.1

const COLOR_WINDUP := Color(1.0, 0.42, 0.10, 0.92)
const COLOR_CHARGE := Color(0.94, 0.08, 0.20, 0.90)
const COLOR_RECOVER := Color(0.58, 0.18, 0.24, 0.64)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.90, 0.42, 1.0)

var _phase: String = PHASE_APPROACH
var _phase_left: float = APPROACH_SECONDS
var _charge_direction: Vector2 = Vector2.RIGHT

func configure(_enemy: Node) -> void:
	_phase = PHASE_APPROACH
	_phase_left = APPROACH_SECONDS
	_charge_direction = Vector2.RIGHT

func resolve_velocity(
	delta: float,
	enemy: Node2D,
	target: Node2D,
	base_velocity: Vector2
) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return base_velocity
	if target == null or not is_instance_valid(target):
		return Vector2.ZERO
	_tick_phase(delta, enemy, target)
	match _phase:
		PHASE_WINDUP, PHASE_RECOVER:
			return Vector2.ZERO
		PHASE_CHARGE:
			return _charge_direction * maxf(float(enemy.get("move_speed")), 1.0) * CHARGE_SPEED_MULTIPLIER
		_:
			return base_velocity

func get_phase() -> String:
	return _phase

func get_charge_direction() -> Vector2:
	return _charge_direction

func _tick_phase(delta: float, enemy: Node2D, target: Node2D) -> void:
	if delta <= 0.0:
		return
	var remaining_delta := delta
	while remaining_delta >= _phase_left:
		remaining_delta -= _phase_left
		_advance_phase(enemy, target)
	_phase_left -= remaining_delta

func _advance_phase(enemy: Node2D, target: Node2D) -> void:
	match _phase:
		PHASE_APPROACH:
			_phase = PHASE_WINDUP
			_phase_left = WINDUP_SECONDS
			_charge_direction = _resolve_target_direction(enemy, target)
			SfxRuntimeRef.play(enemy, "enemy_charge", -15.0, 1.0, 350)
			_spawn_charge_lane(enemy)
		PHASE_WINDUP:
			_phase = PHASE_CHARGE
			_phase_left = CHARGE_SECONDS
			_spawn_charge_streak(enemy)
		PHASE_CHARGE:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
			_spawn_recovery_cue(enemy)
		_:
			_phase = PHASE_APPROACH
			_phase_left = APPROACH_SECONDS

func _spawn_charge_lane(enemy: Node2D) -> void:
	var line := Line2D.new()
	line.name = "CommittedChargeLane"
	var charge_distance := maxf(float(enemy.get("move_speed")), 1.0) * CHARGE_SPEED_MULTIPLIER * CHARGE_SECONDS
	line.points = PackedVector2Array([Vector2(24.0, 0.0), Vector2(maxf(charge_distance, 180.0), 0.0)])
	line.width = 5.0
	line.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_WINDUP
	line.rotation = _charge_direction.angle()
	line.z_index = -1
	line.modulate.a = 0.46
	enemy.add_child(line)
	var tween := line.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(line, "scale:x", 1.04, WINDUP_SECONDS)
	tween.tween_property(line, "modulate:a", 0.98, WINDUP_SECONDS * 0.72)
	tween.chain().tween_property(line, "modulate:a", 0.0, WINDUP_SECONDS * 0.28)
	tween.finished.connect(func() -> void:
		if is_instance_valid(line):
			line.queue_free()
	)

func _spawn_charge_streak(enemy: Node2D) -> void:
	var streak := Line2D.new()
	streak.name = "CommittedChargeStreak"
	streak.points = PackedVector2Array([Vector2(-70.0, 0.0), Vector2(18.0, 0.0)])
	streak.width = 6.0
	streak.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_CHARGE
	streak.rotation = _charge_direction.angle()
	streak.z_index = -2
	enemy.add_child(streak)
	var duration := 0.12 if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled() else CHARGE_SECONDS
	var tween := streak.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(streak, "scale:x", 1.28, duration)
	tween.tween_property(streak, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(streak):
			streak.queue_free()
	)

func _spawn_recovery_cue(enemy: Node2D) -> void:
	var ring := Line2D.new()
	ring.name = "CommittedChargeRecovery"
	ring.points = _build_ring_points(34.0)
	ring.width = 2.6
	ring.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_RECOVER
	ring.z_index = -1
	enemy.add_child(ring)
	var duration := 0.14 if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled() else RECOVER_SECONDS
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(ring, "scale", Vector2.ONE * 1.14, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

func _resolve_target_direction(enemy: Node2D, target: Node2D) -> Vector2:
	var direction := target.global_position - enemy.global_position
	return direction.normalized() if direction.length_squared() > 0.0001 else Vector2.RIGHT

func _build_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(21):
		var angle := TAU * float(point_index) / 20.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
