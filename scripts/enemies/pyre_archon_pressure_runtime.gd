class_name PyreArchonPressureRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const ArenaBoundsRuntimeRef = preload("res://scripts/game/arena_bounds.gd")
const EnemyHazardZoneRuntimeRef = preload("res://scripts/enemies/enemy_hazard_zone_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_REPOSITION := "reposition"
const PHASE_RITUAL := "ritual"
const PHASE_CONTROL := "control"
const PHASE_RECOVER := "recover"

const REPOSITION_SECONDS := 2.4
const RITUAL_SECONDS := 0.85
const CONTROL_SECONDS := 2.50
const RECOVER_SECONDS := 1.0
const RITUAL_SPEED_MULTIPLIER := 0.15
const CONTROL_SPEED_MULTIPLIER := 0.45
const RECOVER_SPEED_MULTIPLIER := 0.25
const CONTROL_INTERVAL_SECONDS := 0.90
const CONTROL_FIRST_SHOT_DELAY := 0.25

const HAZARD_OFFSET := 108.0
const HAZARD_RADIUS := 80.0
const HAZARD_DAMAGE := 6.0
const HAZARD_INTERVAL := 0.65

const COLOR_BASE := Color(0.66, 0.08, 0.22, 0.74)
const COLOR_RITUAL := Color(1.0, 0.36, 0.08, 0.98)
const COLOR_CONTROL := Color(0.90, 0.05, 0.30, 0.94)
const COLOR_RECOVER := Color(0.42, 0.10, 0.18, 0.56)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.90, 0.40, 1.0)

var _phase: String = PHASE_REPOSITION
var _phase_left: float = REPOSITION_SECONDS
var _base_move_speed: float = 1.0
var _base_ranged_damage: float = 0.0
var _base_ranged_interval: float = 1.0
var _base_projectile_count: int = 1
var _base_projectile_spread: float = 0.0

func configure(boss: Node) -> void:
	_phase = PHASE_REPOSITION
	_phase_left = REPOSITION_SECONDS
	if boss != null:
		_base_move_speed = maxf(float(boss.get("move_speed")), 1.0)
		_base_ranged_damage = maxf(float(boss.get("ranged_damage")), 0.0)
		_base_ranged_interval = maxf(float(boss.get("ranged_interval_seconds")), 0.1)
		_base_projectile_count = maxi(int(boss.get("projectile_count")), 1)
		_base_projectile_spread = maxf(float(boss.get("projectile_spread_degrees")), 0.0)
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
	if boss != null and is_instance_valid(boss):
		_restore_combat_values(boss)
		_apply_presence_telegraph(boss, PHASE_REPOSITION)
	_phase = PHASE_REPOSITION
	_phase_left = REPOSITION_SECONDS

func get_phase() -> String:
	return _phase

func _advance_phase() -> void:
	match _phase:
		PHASE_REPOSITION:
			_phase = PHASE_RITUAL
			_phase_left = RITUAL_SECONDS
		PHASE_RITUAL:
			_phase = PHASE_CONTROL
			_phase_left = CONTROL_SECONDS
		PHASE_CONTROL:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
		_:
			_phase = PHASE_REPOSITION
			_phase_left = REPOSITION_SECONDS

func _apply_phase(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	_restore_combat_values(boss)
	match _phase:
		PHASE_RITUAL:
			boss.set("move_speed", _base_move_speed * RITUAL_SPEED_MULTIPLIER)
			boss.set("ranged_damage", 0.0)
			boss.set("ranged_cooldown_left", RITUAL_SECONDS)
			SfxRuntimeRef.play(boss, "boss_windup", -8.0, 0.88, 500)
			_spawn_control_hazards(boss as Node2D)
			_spawn_ritual_cue(boss as Node2D)
		PHASE_CONTROL:
			boss.set("move_speed", _base_move_speed * CONTROL_SPEED_MULTIPLIER)
			boss.set("ranged_interval_seconds", CONTROL_INTERVAL_SECONDS)
			boss.set("projectile_count", 1)
			boss.set("projectile_spread_degrees", 0.0)
			boss.set("ranged_cooldown_left", CONTROL_FIRST_SHOT_DELAY)
		PHASE_RECOVER:
			boss.set("move_speed", _base_move_speed * RECOVER_SPEED_MULTIPLIER)
			boss.set("ranged_damage", 0.0)
			boss.set("ranged_cooldown_left", RECOVER_SECONDS)
	_apply_presence_telegraph(boss, _phase)

func _restore_combat_values(boss: Node) -> void:
	boss.set("move_speed", _base_move_speed)
	boss.set("ranged_damage", _base_ranged_damage)
	boss.set("ranged_interval_seconds", _base_ranged_interval)
	boss.set("projectile_count", _base_projectile_count)
	boss.set("projectile_spread_degrees", _base_projectile_spread)

func _spawn_control_hazards(boss: Node2D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var target_variant: Variant = boss.get("target")
	if not (target_variant is Node2D) or not is_instance_valid(target_variant):
		return
	var target := target_variant as Node2D
	var direction := (target.global_position - boss.global_position).normalized()
	if direction.length_squared() <= 0.0001:
		direction = Vector2.RIGHT
	var perpendicular := direction.orthogonal()
	var hazard_anchor := _clamp_hazard_anchor(boss, target.global_position)
	for offset_sign in [-1.0, 1.0]:
		var hazard_position: Vector2 = hazard_anchor + (perpendicular * HAZARD_OFFSET * float(offset_sign))
		hazard_position = _clamp_hazard_position(boss, hazard_position)
		EnemyHazardZoneRuntimeRef.spawn(
			boss,
			hazard_position,
			HAZARD_RADIUS,
			HAZARD_DAMAGE,
			RITUAL_SECONDS,
			CONTROL_SECONDS,
			HAZARD_INTERVAL
		)

func _clamp_hazard_anchor(boss: Node, world_position: Vector2) -> Vector2:
	var arena_bounds := ArenaBoundsRuntimeRef.ensure_for_scene(boss)
	if arena_bounds == null or not arena_bounds.has_method("clamp_spawn_position"):
		return world_position
	var resolved: Variant = arena_bounds.call(
		"clamp_spawn_position",
		world_position,
		HAZARD_OFFSET + HAZARD_RADIUS
	)
	return resolved if resolved is Vector2 else world_position

func _clamp_hazard_position(boss: Node, world_position: Vector2) -> Vector2:
	var arena_bounds := ArenaBoundsRuntimeRef.ensure_for_scene(boss)
	if arena_bounds == null or not arena_bounds.has_method("clamp_spawn_position"):
		return world_position
	var resolved: Variant = arena_bounds.call("clamp_spawn_position", world_position, HAZARD_RADIUS)
	return resolved if resolved is Vector2 else world_position

func _spawn_ritual_cue(boss: Node2D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var ring := Line2D.new()
	ring.name = "PyreArchonRitualCue"
	ring.points = _build_ring_points(72.0)
	ring.width = 5.0
	ring.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_RITUAL
	ring.scale = Vector2.ONE * 0.76
	ring.z_index = -1
	boss.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(ring, "scale", Vector2.ONE * 1.18, RITUAL_SECONDS)
	tween.tween_property(ring, "modulate:a", 0.0, RITUAL_SECONDS)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

func _apply_presence_telegraph(boss: Node, phase: String) -> void:
	var ring := boss.get_node_or_null("BossPresence") as Line2D
	if ring == null:
		return
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		ring.default_color = COLOR_HIGH_CONTRAST
	else:
		match phase:
			PHASE_RITUAL:
				ring.default_color = COLOR_RITUAL
			PHASE_CONTROL:
				ring.default_color = COLOR_CONTROL
			PHASE_RECOVER:
				ring.default_color = COLOR_RECOVER
			_:
				ring.default_color = COLOR_BASE
	ring.width = 6.0 if phase == PHASE_RITUAL else (5.0 if phase == PHASE_CONTROL else 3.5)

func _build_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(29):
		var angle := TAU * float(point_index) / 28.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
