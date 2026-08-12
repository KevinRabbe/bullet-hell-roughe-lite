class_name RewardPickup
extends Node2D

const AccessibilitySettingsRuntimeRef = preload("res://scripts/ui/accessibility_settings_runtime.gd")

const DEFAULT_PICKUP_RANGE := 40.0
const COLLECT_DISTANCE := 16.0
const ATTRACT_SPEED := 360.0
const COLOR_GOLD := Color(0.94, 0.62, 0.20, 0.95)
const COLOR_XP := Color(0.92, 0.12, 0.48, 0.92)
const COLOR_HIGH_CONTRAST := Color(1.0, 0.94, 0.68, 1.0)

var _target: Node2D
var _gold_reward: int = 0
var _xp_reward: int = 0
var _collected: bool = false

func configure(target: Node, gold_reward: int, xp_reward: int) -> void:
	_target = target as Node2D if target is Node2D else null
	_gold_reward = maxi(gold_reward, 0)
	_xp_reward = maxi(xp_reward, 0)

func _ready() -> void:
	name = "RewardPickup"
	z_index = 12
	_build_visual()

func _process(delta: float) -> void:
	if _collected:
		return
	if _target == null or not is_instance_valid(_target):
		_target = _resolve_player()
	if _target == null:
		return
	var distance := global_position.distance_to(_target.global_position)
	if distance <= COLLECT_DISTANCE:
		_collect()
		return
	if distance > _resolve_pickup_range():
		return
	global_position = global_position.move_toward(_target.global_position, ATTRACT_SPEED * delta)

func _resolve_player() -> Node2D:
	var tree := get_tree()
	if tree == null:
		return null
	var players := tree.get_nodes_in_group("players")
	for player_variant in players:
		if player_variant is Node2D and is_instance_valid(player_variant):
			return player_variant as Node2D
	return null

func _resolve_pickup_range() -> float:
	if _target == null or not is_instance_valid(_target):
		return DEFAULT_PICKUP_RANGE
	var base_value := DEFAULT_PICKUP_RANGE
	var stats_variant: Variant = _target.get("stats")
	if stats_variant != null:
		var raw_value: Variant = stats_variant.get("pickup_range")
		if raw_value is float or raw_value is int:
			base_value = maxf(float(raw_value), 0.0)
	if _target.has_method("get_effective_stat_value"):
		return maxf(float(_target.call("get_effective_stat_value", "pickup_range", base_value)), 0.0)
	return base_value

func _collect() -> void:
	if _collected:
		return
	_collected = true
	if _target != null and is_instance_valid(_target):
		if _gold_reward > 0 and _target.has_method("add_gold"):
			_target.call("add_gold", _gold_reward)
		if _xp_reward > 0 and _target.has_method("add_xp"):
			_target.call("add_xp", _xp_reward)
	queue_free()

func _build_visual() -> void:
	var high_contrast := AccessibilitySettingsRuntimeRef.is_high_contrast_enabled()
	var primary_color := COLOR_HIGH_CONTRAST if high_contrast else (COLOR_GOLD if _gold_reward > 0 else COLOR_XP)
	var secondary_color := COLOR_HIGH_CONTRAST if high_contrast else COLOR_XP
	var scale_weight := clampf(
		0.82 + (float(_gold_reward + _xp_reward) * 0.015),
		0.82,
		1.18
	)
	scale = Vector2.ONE * scale_weight

	var diamond := Polygon2D.new()
	diamond.polygon = PackedVector2Array([
		Vector2(0.0, -5.5),
		Vector2(5.5, 0.0),
		Vector2(0.0, 5.5),
		Vector2(-5.5, 0.0)
	])
	diamond.color = primary_color
	add_child(diamond)

	var outline := Line2D.new()
	outline.points = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(7.0, 0.0),
		Vector2(0.0, 7.0),
		Vector2(-7.0, 0.0),
		Vector2(0.0, -7.0)
	])
	outline.width = 1.5
	outline.default_color = secondary_color
	add_child(outline)
