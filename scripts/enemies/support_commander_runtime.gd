class_name SupportCommanderRuntime
extends RefCounted

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const AURA_RADIUS := 190.0
const DAMAGE_MULTIPLIER := 1.15
const UPDATE_INTERVAL_SECONDS := 0.20
const COLOR_AURA := Color(0.92, 0.18, 0.24, 0.54)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.90, 0.42, 0.88)

var _source_id: int = 0
var _update_left: float = 0.0
var _affected_enemies: Array[Node] = []
var _aura_visual: Node2D

func configure(enemy: Node) -> void:
	_source_id = enemy.get_instance_id() if enemy != null else 0
	_update_left = 0.0
	_affected_enemies.clear()
	_create_aura_visual(enemy as Node2D)

func resolve_velocity(
	delta: float,
	enemy: Node2D,
	_target: Node2D,
	base_velocity: Vector2
) -> Vector2:
	if enemy == null or not is_instance_valid(enemy):
		return base_velocity
	_update_left = maxf(_update_left - delta, 0.0)
	if _update_left <= 0.0:
		_update_aura(enemy)
		_update_left = UPDATE_INTERVAL_SECONDS
	return base_velocity

func restore(_enemy: Node) -> void:
	for affected_enemy in _affected_enemies:
		_clear_effect(affected_enemy)
	_affected_enemies.clear()
	if _aura_visual != null and is_instance_valid(_aura_visual):
		_aura_visual.queue_free()
	_aura_visual = null

func get_affected_count() -> int:
	var count := 0
	for affected_enemy in _affected_enemies:
		if affected_enemy != null and is_instance_valid(affected_enemy):
			count += 1
	return count

func _update_aura(enemy: Node2D) -> void:
	var next_affected: Array[Node] = []
	for candidate_variant in enemy.get_tree().get_nodes_in_group("enemies"):
		var candidate := candidate_variant as Node2D
		if candidate == null or candidate == enemy or not is_instance_valid(candidate):
			continue
		if candidate.get("is_boss") == true:
			continue
		if candidate.global_position.distance_to(enemy.global_position) > AURA_RADIUS:
			continue
		if not candidate.has_method("set_support_damage_multiplier"):
			continue
		candidate.call("set_support_damage_multiplier", _source_id, DAMAGE_MULTIPLIER)
		next_affected.append(candidate)
	for previous_enemy in _affected_enemies:
		if not next_affected.has(previous_enemy):
			_clear_effect(previous_enemy)
	_affected_enemies = next_affected

func _clear_effect(candidate: Node) -> void:
	if candidate != null and is_instance_valid(candidate) and candidate.has_method("clear_support_damage_multiplier"):
		candidate.call("clear_support_damage_multiplier", _source_id)

func _create_aura_visual(enemy: Node2D) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	_aura_visual = Node2D.new()
	_aura_visual.name = "CommandAura"
	_aura_visual.z_index = -2
	enemy.add_child(_aura_visual)
	var ring := Line2D.new()
	ring.points = _build_ring_points(AURA_RADIUS)
	ring.width = 2.8
	ring.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_AURA
	_aura_visual.add_child(ring)
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	var tween := _aura_visual.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_aura_visual, "modulate:a", 0.54, 0.65)
	tween.tween_property(_aura_visual, "modulate:a", 1.0, 0.65)

func _build_ring_points(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(33):
		var angle := TAU * float(point_index) / 32.0
		points.append(Vector2.from_angle(angle) * radius)
	return points
