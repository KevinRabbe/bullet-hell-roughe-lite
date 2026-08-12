class_name EnemyHazardZone
extends Area2D

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const COLOR_WARNING := Color(0.96, 0.34, 0.08, 0.76)
const COLOR_ACTIVE := Color(0.90, 0.06, 0.20, 0.90)
const COLOR_FILL_WARNING := Color(0.72, 0.12, 0.08, 0.10)
const COLOR_FILL_ACTIVE := Color(0.76, 0.03, 0.12, 0.18)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.90, 0.40, 1.0)

var radius: float = 78.0
var damage: float = 5.0
var warning_seconds: float = 0.70
var active_seconds: float = 2.60
var damage_interval_seconds: float = 0.65
var source_enemy: Node

var _elapsed: float = 0.0
var _damage_cooldown: float = 0.0
var _armed: bool = false
var _edge: Line2D
var _fill: Polygon2D

func _ready() -> void:
	name = "EnemyHazardZone"
	add_to_group("projectiles")
	collision_layer = 0
	collision_mask = 1
	monitoring = true
	monitorable = false
	z_index = -1
	_build_collision()
	_build_visuals()

func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _armed and _elapsed >= warning_seconds:
		_arm_zone()
	if _armed:
		_damage_cooldown = maxf(_damage_cooldown - delta, 0.0)
		if _damage_cooldown <= 0.0:
			_damage_overlapping_players()
			_damage_cooldown = damage_interval_seconds
		var active_elapsed := _elapsed - warning_seconds
		if active_elapsed >= active_seconds:
			queue_free()
			return
		if active_seconds - active_elapsed <= 0.45:
			var fade := clampf((active_seconds - active_elapsed) / 0.45, 0.0, 1.0)
			modulate.a = fade

func is_armed() -> bool:
	return _armed

func _build_collision() -> void:
	var shape_node := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	shape_node.shape = circle
	add_child(shape_node)

func _build_visuals() -> void:
	var points := _build_circle_points(radius)
	_fill = Polygon2D.new()
	_fill.polygon = points
	_fill.color = COLOR_FILL_WARNING
	add_child(_fill)

	_edge = Line2D.new()
	_edge.points = _build_circle_loop(radius)
	_edge.width = 3.0
	_edge.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_WARNING
	add_child(_edge)
	if AccessibilitySettingsRuntimeRef.is_reduced_motion_enabled():
		return
	var tween := _edge.create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_edge, "modulate:a", 0.48, 0.22)
	tween.tween_property(_edge, "modulate:a", 1.0, 0.22)

func _arm_zone() -> void:
	_armed = true
	_damage_cooldown = 0.0
	if _fill != null:
		_fill.color = COLOR_FILL_ACTIVE
	if _edge != null:
		_edge.width = 4.0
		_edge.default_color = COLOR_HIGH_CONTRAST if AccessibilitySettingsRuntimeRef.is_high_contrast_enabled() else COLOR_ACTIVE

func _damage_overlapping_players() -> void:
	for body in get_overlapping_bodies():
		if body == null or not body.is_in_group("players") or not body.has_method("take_damage"):
			continue
		body.call("take_damage", damage)
		if body.has_method("notify_damaged_by_enemy"):
			body.call("notify_damaged_by_enemy", source_enemy if is_instance_valid(source_enemy) else null)

func _build_circle_points(zone_radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(28):
		var angle := TAU * float(point_index) / 28.0
		points.append(Vector2.from_angle(angle) * zone_radius)
	return points

func _build_circle_loop(zone_radius: float) -> PackedVector2Array:
	var points := _build_circle_points(zone_radius)
	points.append(points[0])
	return points
