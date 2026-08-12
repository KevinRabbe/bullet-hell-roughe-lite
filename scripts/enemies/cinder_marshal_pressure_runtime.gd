class_name CinderMarshalPressureRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

const PHASE_REPOSITION := "reposition"
const PHASE_WINDUP := "windup"
const PHASE_BARRAGE := "barrage"
const PHASE_RECOVER := "recover"

const REPOSITION_SECONDS := 2.4
const WINDUP_SECONDS := 0.65
const BARRAGE_SECONDS := 1.45
const RECOVER_SECONDS := 0.85

const WINDUP_SPEED_MULTIPLIER := 0.18
const BARRAGE_SPEED_MULTIPLIER := 0.55
const RECOVER_SPEED_MULTIPLIER := 0.35
const BARRAGE_INTERVAL_SECONDS := 0.65
const BARRAGE_FIRST_SHOT_DELAY := 0.22
const BARRAGE_PROJECTILE_COUNT := 5
const BARRAGE_SPREAD_DEGREES := 44.0

const COLOR_BASE := Color(0.72, 0.12, 0.28, 0.72)
const COLOR_WINDUP := Color(1.0, 0.48, 0.12, 0.96)
const COLOR_BARRAGE := Color(0.96, 0.10, 0.36, 0.94)
const COLOR_RECOVER := Color(0.48, 0.12, 0.20, 0.56)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.88, 0.42, 1.0)
const FIRING_LINE_LENGTH := 320.0

var _phase: String = PHASE_REPOSITION
var _phase_left: float = REPOSITION_SECONDS
var _base_move_speed: float = 1.0
var _base_ranged_damage: float = 0.0
var _base_ranged_interval: float = 1.0
var _base_projectile_count: int = 1
var _base_projectile_spread: float = 0.0
var _committed_direction: Vector2 = Vector2.RIGHT

func configure(boss: Node) -> void:
	_phase = PHASE_REPOSITION
	_phase_left = REPOSITION_SECONDS
	_committed_direction = Vector2.RIGHT
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
		boss.set("ranged_aim_direction_override", Vector2.ZERO)
		_apply_presence_telegraph(boss, PHASE_REPOSITION)
	_phase = PHASE_REPOSITION
	_phase_left = REPOSITION_SECONDS

func get_phase() -> String:
	return _phase

func _advance_phase() -> void:
	match _phase:
		PHASE_REPOSITION:
			_phase = PHASE_WINDUP
			_phase_left = WINDUP_SECONDS
		PHASE_WINDUP:
			_phase = PHASE_BARRAGE
			_phase_left = BARRAGE_SECONDS
		PHASE_BARRAGE:
			_phase = PHASE_RECOVER
			_phase_left = RECOVER_SECONDS
		_:
			_phase = PHASE_REPOSITION
			_phase_left = REPOSITION_SECONDS

func _apply_phase(boss: Node) -> void:
	if boss == null or not is_instance_valid(boss):
		return
	_restore_combat_values(boss)
	boss.set("ranged_aim_direction_override", Vector2.ZERO)
	match _phase:
		PHASE_WINDUP:
			_committed_direction = _resolve_target_direction(boss as Node2D)
			boss.set("move_speed", _base_move_speed * WINDUP_SPEED_MULTIPLIER)
			boss.set("ranged_damage", 0.0)
			boss.set("ranged_aim_direction_override", _committed_direction)
			boss.set("ranged_cooldown_left", maxf(float(boss.get("ranged_cooldown_left")), WINDUP_SECONDS))
			SfxRuntimeRef.play(boss, "boss_windup", -9.0, 0.96, 500)
			_spawn_firing_line_telegraph(boss)
		PHASE_BARRAGE:
			boss.set("move_speed", _base_move_speed * BARRAGE_SPEED_MULTIPLIER)
			boss.set("ranged_aim_direction_override", _committed_direction)
			boss.set("ranged_interval_seconds", BARRAGE_INTERVAL_SECONDS)
			boss.set("projectile_count", BARRAGE_PROJECTILE_COUNT)
			boss.set("projectile_spread_degrees", BARRAGE_SPREAD_DEGREES)
			boss.set("ranged_cooldown_left", BARRAGE_FIRST_SHOT_DELAY)
			_spawn_barrage_release_cue(boss)
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

func _apply_presence_telegraph(boss: Node, phase: String) -> void:
	var ring := boss.get_node_or_null("BossPresence") as Line2D
	if ring == null:
		return
	if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled():
		ring.default_color = COLOR_HIGH_CONTRAST
	else:
		match phase:
			PHASE_WINDUP:
				ring.default_color = COLOR_WINDUP
			PHASE_BARRAGE:
				ring.default_color = COLOR_BARRAGE
			PHASE_RECOVER:
				ring.default_color = COLOR_RECOVER
			_:
				ring.default_color = COLOR_BASE
	match phase:
		PHASE_WINDUP:
			ring.width = 6.0
		PHASE_BARRAGE:
			ring.width = 5.0
		PHASE_RECOVER:
			ring.width = 2.5
		_:
			ring.width = 3.5

func _spawn_firing_line_telegraph(boss: Node) -> void:
	var boss_node := boss as Node2D
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var cue_root := Node2D.new()
	cue_root.name = "CinderMarshalFiringLine"
	cue_root.rotation = _committed_direction.angle()
	cue_root.z_index = -1
	boss_node.add_child(cue_root)

	var cue_color := COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_WINDUP
	for projectile_index in BARRAGE_PROJECTILE_COUNT:
		var progress := float(projectile_index) / float(BARRAGE_PROJECTILE_COUNT - 1)
		var angle := deg_to_rad(lerpf(-BARRAGE_SPREAD_DEGREES * 0.5, BARRAGE_SPREAD_DEGREES * 0.5, progress))
		var firing_line := Line2D.new()
		firing_line.points = PackedVector2Array([Vector2(28.0, 0.0), Vector2.from_angle(angle) * FIRING_LINE_LENGTH])
		firing_line.width = 2.8 if projectile_index == 2 else 1.7
		firing_line.default_color = Color(cue_color, 0.84 if projectile_index == 2 else 0.58)
		cue_root.add_child(firing_line)

	var reduced_motion := AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled()
	cue_root.modulate.a = 0.45
	var tween := cue_root.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not reduced_motion:
		tween.tween_property(cue_root, "scale", Vector2.ONE * 1.04, WINDUP_SECONDS)
	tween.tween_property(cue_root, "modulate:a", 0.96, WINDUP_SECONDS * 0.72)
	tween.chain().tween_property(cue_root, "modulate:a", 0.0, WINDUP_SECONDS * 0.28)
	tween.finished.connect(func() -> void:
		if is_instance_valid(cue_root):
			cue_root.queue_free()
	)

func _spawn_barrage_release_cue(boss: Node) -> void:
	var boss_node := boss as Node2D
	if boss_node == null or not is_instance_valid(boss_node):
		return
	var ring := Line2D.new()
	ring.name = "CinderMarshalBarrageCue"
	ring.points = _build_ring_points(54.0)
	ring.width = 4.0
	ring.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_BARRAGE
	ring.z_index = -1
	boss_node.add_child(ring)
	var duration := 0.10 if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled() else BARRAGE_FIRST_SHOT_DELAY
	var tween := ring.create_tween()
	tween.set_parallel(true)
	tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if not AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		tween.tween_property(ring, "scale", Vector2.ONE * 1.35, duration)
	tween.tween_property(ring, "modulate:a", 0.0, duration)
	tween.finished.connect(func() -> void:
		if is_instance_valid(ring):
			ring.queue_free()
	)

func _resolve_target_direction(boss: Node2D) -> Vector2:
	var target_variant: Variant = boss.get("target")
	if target_variant is Node2D and is_instance_valid(target_variant):
		var direction := (target_variant as Node2D).global_position - boss.global_position
		if direction.length_squared() > 0.0001:
			return direction.normalized()
	return Vector2.RIGHT

func _build_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(25):
		var angle := TAU * float(point_index) / 24.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
