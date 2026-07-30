class_name GateBeastPressureRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_CHASE := "chase"
const PHASE_WINDUP := "windup"
const PHASE_RUSH := "rush"
const PHASE_RECOVER := "recover"

const CHASE_SECONDS := 1.8
const WINDUP_SECONDS := 0.45
const RUSH_SECONDS := 0.65
const RECOVER_SECONDS := 0.55

const WINDUP_SPEED_MULTIPLIER := 0.25
const RUSH_SPEED_MULTIPLIER := 2.15
const RECOVER_SPEED_MULTIPLIER := 0.65

const COLOR_BASE := Color(0.62, 0.10, 0.18, 0.68)
const COLOR_WINDUP := Color(0.94, 0.42, 0.10, 0.95)
const COLOR_RUSH := Color(0.86, 0.14, 0.12, 0.92)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.72, 0.30, 1.0)
const PHASE_CUE_RADIUS := 66.0
const RUSH_STREAK_LENGTH := 74.0
const RUSH_STREAK_OFFSETS: Array[float] = [-18.0, 0.0, 18.0]

var _phase: String = PHASE_CHASE
var _phase_left: float = CHASE_SECONDS
var _base_move_speed: float = 0.0

func configure(boss: Node) -> void:
	_phase = PHASE_CHASE
	_phase_left = CHASE_SECONDS
	_base_move_speed = maxf(float(boss.get("move_speed")), 1.0) if boss != null else 1.0
	_apply_phase(boss)

func tick(delta: float, boss: Node) -> void:
	if boss == null or not is_instance_valid(boss) or delta <= 0.0:
		return
	var remaining_delta := delta
	var phase_changed := false
	while remaining_delta >= _phase_left:
		remaining_delta -= _phase_left
		_advance_phase()
		phase_changed = true
	_phase_left -= remaining_delta
	if phase_changed:
		_apply_phase(boss)

func restore(boss: Node) -> void:
	if boss != null and is_instance_valid(boss) and _base_move_speed > 0.0:
		boss.set("move_speed", _base_move_speed)
	_phase = PHASE_CHASE
	_phase_left = CHASE_SECONDS

func get_phase() -> String:
	return _phase

func _advance_phase() -> void:
	match _phase:
		PHASE_CHASE:
			_phase = PHASE_WINDUP
			_phase_left = WINDUP_SECONDS
		PHASE_WINDUP:
			_phase = PHASE_RUSH
			_phase_left = RUSH_SECONDS
		PHASE_RUSH:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
		_:
			_phase = PHASE_CHASE
			_phase_left = CHASE_SECONDS

func _apply_phase(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var speed_multiplier := 1.0
	match _phase:
		PHASE_WINDUP:
			speed_multiplier = WINDUP_SPEED_MULTIPLIER
			SfxRuntimeRef.play(boss, "boss_windup", -9.0, 1.0, 500)
		PHASE_RUSH:
			speed_multiplier = RUSH_SPEED_MULTIPLIER
		PHASE_RECOVER:
			speed_multiplier = RECOVER_SPEED_MULTIPLIER
	boss.set("move_speed", _base_move_speed * speed_multiplier)
	_apply_presence_telegraph(boss)
	_spawn_phase_cue(boss)
	if _phase == PHASE_RUSH:
		_spawn_rush_streak(boss)

func _apply_presence_telegraph(boss: Node) -> void:
	var ring := boss.get_node_or_null("BossPresence") as Line2D
	if ring == null:
		return
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		ring.default_color = COLOR_HIGH_CONTRAST
	else:
		match _phase:
			PHASE_WINDUP:
				ring.default_color = COLOR_WINDUP
			PHASE_RUSH:
				ring.default_color = COLOR_RUSH
			_:
				ring.default_color = COLOR_BASE
	match _phase:
		PHASE_WINDUP:
			ring.width = 6.0
		PHASE_RUSH:
			ring.width = 5.0
		_:
			ring.width = 3.5

func _spawn_phase_cue(boss: Node) -> void:
	if _phase != PHASE_WINDUP and _phase != PHASE_RUSH:
		return
	if not (boss is Node2D) or boss.get_tree() == null:
		return
	var cue := Line2D.new()
	cue.name = "GateBeastPhaseCue"
	cue.points = _build_cue_points()
	cue.width = 5.0 if _phase == PHASE_WINDUP else 7.0
	cue.default_color = _resolve_phase_cue_color()
	cue.z_index = -1
	(boss as Node2D).add_child(cue)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.22
	if _phase == PHASE_WINDUP:
		duration = WINDUP_SECONDS
		cue.scale = Vector2.ONE * 1.28
	else:
		cue.scale = Vector2.ONE * 0.82
	var tween := cue.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		var target_scale := Vector2.ONE * (0.84 if _phase == PHASE_WINDUP else 1.38)
		tween.tween_property(cue, "scale", target_scale, duration)
	tween.tween_property(cue, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(cue):
			cue.queue_free()
	)

func _spawn_rush_streak(boss: Node) -> void:
	var boss_node := boss as Node2D
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var direction := Vector2.RIGHT
	var target_variant: Variant = boss.get("target")
	if target_variant is Node2D and is_instance_valid(target_variant):
		direction = ((target_variant as Node2D).global_position - boss_node.global_position).normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT

	var streak_root := Node2D.new()
	streak_root.name = "GateBeastRushStreak"
	streak_root.rotation = direction.angle()
	streak_root.z_index = -3
	boss_node.add_child(streak_root)

	var color := COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_RUSH
	for offset_y in RUSH_STREAK_OFFSETS:
		var streak := Line2D.new()
		streak.points = PackedVector2Array([
			Vector2(-RUSH_STREAK_LENGTH, offset_y),
			Vector2(10.0, offset_y)
		])
		streak.width = 3.0 if is_zero_approx(offset_y) else 2.0
		var gradient := Gradient.new()
		var transparent_color := color
		transparent_color.a = 0.0
		gradient.set_color(0, transparent_color)
		gradient.set_color(1, color)
		streak.gradient = gradient
		streak_root.add_child(streak)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	var duration := 0.18 if reduced_motion else RUSH_SECONDS
	var tween := streak_root.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(streak_root, "scale:x", 1.32, duration)
	tween.tween_property(streak_root, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(streak_root):
			streak_root.queue_free()
	)

func _build_cue_points() -> PackedVector2Array:
	var points := PackedVector2Array()
	var point_count := 24
	for index in range(point_count + 1):
		var angle := TAU * float(index) / float(point_count)
		points.append(Vector2(cos(angle), sin(angle)) * PHASE_CUE_RADIUS)
	return points

func _resolve_phase_cue_color() -> Color:
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		return COLOR_HIGH_CONTRAST
	return COLOR_WINDUP if _phase == PHASE_WINDUP else COLOR_RUSH
