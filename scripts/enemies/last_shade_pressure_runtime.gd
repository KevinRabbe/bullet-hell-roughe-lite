class_name LastShadePressureRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const ArenaBoundsRuntimeRef = preload("res://scripts/game/arena_bounds.gd")
const EnemyHazardZoneRuntimeRef = preload("res://scripts/enemies/enemy_hazard_zone_runtime.gd")
const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_HUNT := "hunt"
const PHASE_MARK := "mark"
const PHASE_RUSH := "rush"
const PHASE_CONTROL := "control"
const PHASE_RECOVER := "recover"

const HUNT_SECONDS := 2.20
const HUNT_ENRAGED_SECONDS := 1.80
const MARK_SECONDS := 0.65
const RUSH_SECONDS := 0.55
const CONTROL_SECONDS := 2.20
const CONTROL_ENRAGED_SECONDS := 1.90
const RECOVER_SECONDS := 1.00
const RECOVER_ENRAGED_SECONDS := 0.80

const MARK_SPEED_MULTIPLIER := 0.12
const RUSH_SPEED_MULTIPLIER := 3.0
const RUSH_ENRAGED_SPEED_MULTIPLIER := 3.35
const RUSH_DAMAGE_MULTIPLIER := 1.25
const RUSH_ENRAGED_DAMAGE_MULTIPLIER := 1.45
const CONTROL_SPEED_MULTIPLIER := 0.35
const RECOVER_SPEED_MULTIPLIER := 0.22
const CONTROL_INTERVAL_SECONDS := 0.75
const CONTROL_ENRAGED_INTERVAL_SECONDS := 0.58
const CONTROL_FIRST_SHOT_DELAY := 0.22
const CONTROL_PROJECTILE_COUNT := 5
const CONTROL_ENRAGED_PROJECTILE_COUNT := 7
const CONTROL_SPREAD_DEGREES := 50.0
const CONTROL_ENRAGED_SPREAD_DEGREES := 64.0

const HAZARD_OFFSET := 120.0
const HAZARD_RADIUS := 80.0
const HAZARD_DAMAGE := 7.0
const HAZARD_ENRAGED_DAMAGE := 8.0
const HAZARD_INTERVAL := 0.65
const RUSH_LINE_LENGTH := 520.0

const COLOR_BASE := Color(0.48, 0.04, 0.20, 0.76)
const COLOR_MARK := Color(1.0, 0.42, 0.08, 0.98)
const COLOR_RUSH := Color(0.96, 0.05, 0.34, 0.98)
const COLOR_CONTROL := Color(0.72, 0.06, 0.46, 0.94)
const COLOR_RECOVER := Color(0.30, 0.06, 0.20, 0.56)
const COLOR_ENRAGED := Color(0.88, 0.12, 0.78, 1.0)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.92, 0.36, 1.0)

var _phase: String = PHASE_HUNT
var _phase_left: float = HUNT_SECONDS
var _base_move_speed: float = 1.0
var _base_contact_damage: float = 0.0
var _base_ranged_damage: float = 0.0
var _base_ranged_interval: float = 1.0
var _base_projectile_count: int = 1
var _base_projectile_spread: float = 0.0
var _committed_direction: Vector2 = Vector2.RIGHT
var _enraged: bool = false

func configure(boss: Node) -> void:
	_phase = PHASE_HUNT
	_phase_left = HUNT_SECONDS
	_committed_direction = Vector2.RIGHT
	_enraged = false
	if boss != null:
		_base_move_speed = maxf(float(boss.get("move_speed")), 1.0)
		_base_contact_damage = maxf(float(boss.get("contact_damage")), 0.0)
		_base_ranged_damage = maxf(float(boss.get("ranged_damage")), 0.0)
		_base_ranged_interval = maxf(float(boss.get("ranged_interval_seconds")), 0.1)
		_base_projectile_count = maxi(int(boss.get("projectile_count")), 1)
		_base_projectile_spread = maxf(float(boss.get("projectile_spread_degrees")), 0.0)
	_apply_phase(boss)

func tick(delta: float, boss: Node) -> void:
	if boss == null or not is_instance_valid(boss) or delta <= 0.0:
		return
	_try_enter_enrage(boss)
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
		boss.set("ranged_aim_direction_override", Vector2.ZERO)
		boss.set("movement_direction_override", Vector2.ZERO)
		_apply_presence_telegraph(boss, PHASE_HUNT)
	_phase = PHASE_HUNT
	_phase_left = HUNT_SECONDS

func get_phase() -> String:
	return _phase

func is_enraged() -> bool:
	return _enraged

func get_committed_direction() -> Vector2:
	return _committed_direction

func _advance_phase() -> void:
	match _phase:
		PHASE_HUNT:
			_phase = PHASE_MARK
			_phase_left = MARK_SECONDS
		PHASE_MARK:
			_phase = PHASE_RUSH
			_phase_left = RUSH_SECONDS
		PHASE_RUSH:
			_phase = PHASE_CONTROL
			_phase_left = CONTROL_ENRAGED_SECONDS if _enraged else CONTROL_SECONDS
		PHASE_CONTROL:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_ENRAGED_SECONDS if _enraged else RECOVER_SECONDS
		_:
			_phase = PHASE_HUNT
			_phase_left = HUNT_ENRAGED_SECONDS if _enraged else HUNT_SECONDS

func _apply_phase(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	_restore_combat_values(boss)
	boss.set("ranged_aim_direction_override", Vector2.ZERO)
	boss.set("movement_direction_override", Vector2.ZERO)
	match _phase:
		PHASE_MARK:
			_committed_direction = _resolve_target_direction(boss as Node2D)
			boss.set("move_speed", _base_move_speed * MARK_SPEED_MULTIPLIER)
			boss.set("ranged_damage", 0.0)
			boss.set("ranged_aim_direction_override", _committed_direction)
			boss.set("ranged_cooldown_left", maxf(float(boss.get("ranged_cooldown_left")), MARK_SECONDS + RUSH_SECONDS))
			SfxRuntimeRef.play(boss, "boss_windup", -7.0, 0.82 if not _enraged else 0.92, 500)
			_spawn_control_hazards(boss as Node2D)
			_spawn_rush_line_telegraph(boss as Node2D)
		PHASE_RUSH:
			boss.set("move_speed", _base_move_speed * (RUSH_ENRAGED_SPEED_MULTIPLIER if _enraged else RUSH_SPEED_MULTIPLIER))
			boss.set("contact_damage", _base_contact_damage * (RUSH_ENRAGED_DAMAGE_MULTIPLIER if _enraged else RUSH_DAMAGE_MULTIPLIER))
			boss.set("ranged_damage", 0.0)
			boss.set("movement_direction_override", _committed_direction)
			boss.set("ranged_cooldown_left", RUSH_SECONDS)
		PHASE_CONTROL:
			boss.set("move_speed", _base_move_speed * CONTROL_SPEED_MULTIPLIER)
			boss.set("ranged_interval_seconds", CONTROL_ENRAGED_INTERVAL_SECONDS if _enraged else CONTROL_INTERVAL_SECONDS)
			boss.set("projectile_count", CONTROL_ENRAGED_PROJECTILE_COUNT if _enraged else CONTROL_PROJECTILE_COUNT)
			boss.set("projectile_spread_degrees", CONTROL_ENRAGED_SPREAD_DEGREES if _enraged else CONTROL_SPREAD_DEGREES)
			boss.set("ranged_cooldown_left", CONTROL_FIRST_SHOT_DELAY)
		PHASE_RECOVER:
			boss.set("move_speed", _base_move_speed * RECOVER_SPEED_MULTIPLIER)
			boss.set("ranged_damage", 0.0)
			boss.set("ranged_cooldown_left", RECOVER_ENRAGED_SECONDS if _enraged else RECOVER_SECONDS)
	_apply_presence_telegraph(boss, _phase)

func _restore_combat_values(boss: Node) -> void:
	boss.set("move_speed", _base_move_speed)
	boss.set("contact_damage", _base_contact_damage)
	boss.set("ranged_damage", _base_ranged_damage)
	boss.set("ranged_interval_seconds", _base_ranged_interval)
	boss.set("projectile_count", _base_projectile_count)
	boss.set("projectile_spread_degrees", _base_projectile_spread)

func _try_enter_enrage(boss: Node) -> void:
	if _enraged:
		return
	var max_hp := maxf(float(boss.get("max_hp")), 1.0)
	if float(boss.get("current_hp")) > max_hp * 0.5:
		return
	_enraged = true
	SfxRuntimeRef.play(boss, "boss_windup", -5.0, 1.08, 700)
	EventBannerRuntimeRef.show(
		boss,
		"THE VEIL TEARS",
		"LAST SHADE UNBOUND",
		"The rhythm quickens. The marks remain honest.",
		1.35
	)
	_spawn_enrage_cue(boss as Node2D)

func _spawn_control_hazards(boss: Node2D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var target_variant: Variant = boss.get("target")
	if not (target_variant is Node2D) or not is_instance_valid(target_variant):
		return
	var target := target_variant as Node2D
	var perpendicular := _committed_direction.orthogonal()
	var hazard_anchor := _clamp_hazard_anchor(boss, target.global_position)
	var active_duration := CONTROL_ENRAGED_SECONDS if _enraged else CONTROL_SECONDS
	var hazard_damage := HAZARD_ENRAGED_DAMAGE if _enraged else HAZARD_DAMAGE
	for offset_sign in [-1.0, 1.0]:
		var hazard_position: Vector2 = hazard_anchor + perpendicular * HAZARD_OFFSET * float(offset_sign)
		hazard_position = _clamp_hazard_position(boss, hazard_position)
		EnemyHazardZoneRuntimeRef.spawn(
			boss,
			hazard_position,
			HAZARD_RADIUS,
			hazard_damage,
			MARK_SECONDS + RUSH_SECONDS,
			active_duration,
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

func _resolve_target_direction(boss: Node2D) -> Vector2:
	if boss == null:
		return Vector2.RIGHT
	var target_variant: Variant = boss.get("target")
	if target_variant is Node2D and is_instance_valid(target_variant):
		var direction := (target_variant as Node2D).global_position - boss.global_position
		if direction.length_squared() > 0.0001:
			return direction.normalized()
	return Vector2.RIGHT

func _spawn_rush_line_telegraph(boss: Node2D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var cue := Line2D.new()
	cue.name = "LastShadeRushLine"
	cue.points = PackedVector2Array([Vector2.ZERO, _committed_direction * RUSH_LINE_LENGTH])
	cue.width = 5.0
	cue.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_MARK
	cue.z_index = -1
	boss.add_child(cue)
	var duration := MARK_SECONDS + RUSH_SECONDS
	var tween := cue.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(cue, "width", 8.0, MARK_SECONDS)
	tween.tween_property(cue, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(cue):
			cue.queue_free()
	)

func _spawn_enrage_cue(boss: Node2D) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	var ring := Line2D.new()
	ring.name = "LastShadeEnrageCue"
	ring.points = _build_ring_points(72.0)
	ring.width = 6.0
	ring.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_ENRAGED
	ring.z_index = -1
	boss.add_child(ring)
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(ring, "scale", Vector2.ONE * 1.55, 0.48)
	tween.tween_property(ring, "modulate:a", 0.0, 0.48)
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
	elif _enraged:
		ring.default_color = COLOR_ENRAGED
	else:
		match phase:
			PHASE_MARK:
				ring.default_color = COLOR_MARK
			PHASE_RUSH:
				ring.default_color = COLOR_RUSH
			PHASE_CONTROL:
				ring.default_color = COLOR_CONTROL
			PHASE_RECOVER:
				ring.default_color = COLOR_RECOVER
			_:
				ring.default_color = COLOR_BASE
	ring.width = 6.0 if phase == PHASE_MARK else (5.0 if phase == PHASE_RUSH or phase == PHASE_CONTROL else 3.5)

func _build_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(29):
		var angle := TAU * float(point_index) / 28.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
