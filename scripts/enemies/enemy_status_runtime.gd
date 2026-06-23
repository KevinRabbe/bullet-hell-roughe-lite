class_name EnemyStatusRuntime
extends RefCounted

var _owner: Node2D
var _status_rng: RandomNumberGenerator
var _load_weapon_data_callback: Callable
var _tick_damage_callback: Callable
var _active_statuses: Dictionary = {}

func configure(
	owner: Node2D,
	status_rng: RandomNumberGenerator,
	load_weapon_data_callback: Callable,
	tick_damage_callback: Callable
) -> void:
	_owner = owner
	_status_rng = status_rng
	_load_weapon_data_callback = load_weapon_data_callback
	_tick_damage_callback = tick_damage_callback

func tick(delta: float) -> void:
	tick_statuses(_active_statuses, delta, _tick_damage_callback)

func apply_weapon_status_effect(source: Node, source_weapon_id: String, source_slot_index: int = -1) -> bool:
	if source_weapon_id == "":
		return false
	if not _load_weapon_data_callback.is_valid():
		return false
	var weapon_data_variant: Variant = _load_weapon_data_callback.call(source_weapon_id)
	if not (weapon_data_variant is WeaponData):
		return false
	var weapon_data := weapon_data_variant as WeaponData
	if weapon_data.on_hit_status_id == "" or weapon_data.on_hit_status_duration <= 0.0:
		return false
	var status_power_multiplier := compute_status_power_multiplier(source, weapon_data)
	var status_payload := build_status_payload(weapon_data, source, status_power_multiplier)
	return apply_status_payload(
		status_payload,
		source,
		source_weapon_id,
		source_slot_index,
		status_power_multiplier
	)

func apply_status_payload(
	status_payload: Dictionary,
	source: Node = null,
	source_weapon_id: String = "",
	source_slot_index: int = -1,
	status_power_multiplier: float = 1.0
) -> bool:
	var applied := EnemyStatusRuntime.apply_status_payload_to_dict(_active_statuses, status_payload)
	if not applied:
		return false
	EnemyStatusRuntime.try_spread_status(
		_owner,
		_status_rng,
		status_payload,
		source,
		source_weapon_id,
		source_slot_index,
		status_power_multiplier
	)
	return true

func get_status_stack_count(status_id: String) -> int:
	if status_id == "":
		return 0
	var status_variant: Variant = _active_statuses.get(status_id, {})
	if not (status_variant is Dictionary):
		return 0
	return maxi(int((status_variant as Dictionary).get("stacks", 0)), 0)

static func compute_status_power_multiplier(source: Node, weapon_data: WeaponData) -> float:
	var status_power_multiplier := 1.0
	if source != null and source.has_method("get_status_power_multiplier"):
		status_power_multiplier = maxf(float(source.call("get_status_power_multiplier", weapon_data.on_hit_status_id)), 0.0)
	if source != null and weapon_data.on_hit_status_power_stat_id != "" and source.has_method("get_status_power_stat_multiplier"):
		status_power_multiplier *= maxf(
			float(source.call("get_status_power_stat_multiplier", weapon_data.on_hit_status_power_stat_id, 1.0)),
			0.0
		)
	return status_power_multiplier

static func build_status_payload(
	weapon_data: WeaponData,
	source: Node,
	status_power_multiplier: float
) -> Dictionary:
	var status_payload := {
		"status_id": weapon_data.on_hit_status_id,
		"duration": weapon_data.on_hit_status_duration,
		"tick_interval": weapon_data.on_hit_status_tick_interval,
		"flat_damage": weapon_data.on_hit_status_flat_damage,
		"max_hp_fraction": weapon_data.on_hit_status_max_hp_fraction,
		"max_stacks": weapon_data.on_hit_status_max_stacks
	}
	if source != null and source.has_method("get_status_propagation_rule"):
		var propagation_variant: Variant = source.call("get_status_propagation_rule", weapon_data.on_hit_status_id)
		if propagation_variant is Dictionary:
			var propagation_rule: Dictionary = propagation_variant
			status_payload["spread_radius"] = float(propagation_rule.get("radius", 0.0))
			status_payload["spread_chance"] = float(propagation_rule.get("chance", 0.0))
			status_payload["spread_duration_scale"] = float(propagation_rule.get("duration_scale", 1.0))
			status_payload["spread_max_targets"] = int(propagation_rule.get("max_targets", 1))
			status_payload["allow_spread"] = true
	status_payload["flat_damage"] = float(status_payload.get("flat_damage", 0.0)) * status_power_multiplier
	status_payload["max_hp_fraction"] = float(status_payload.get("max_hp_fraction", 0.0)) * status_power_multiplier
	return status_payload

static func apply_status_payload_to_dict(
	active_statuses: Dictionary,
	status_payload: Dictionary
) -> bool:
	var status_id := str(status_payload.get("status_id", ""))
	if status_id == "":
		return false
	var duration := float(status_payload.get("duration", 0.0))
	if duration <= 0.0:
		return false
	var tick_interval := maxf(float(status_payload.get("tick_interval", 0.0)), 0.0)
	var max_stacks := maxi(int(status_payload.get("max_stacks", 1)), 1)
	var current_stacks := 0
	var current_status_variant: Variant = active_statuses.get(status_id, {})
	if current_status_variant is Dictionary:
		current_stacks = int((current_status_variant as Dictionary).get("stacks", 0))
	var next_stacks := mini(current_stacks + 1, max_stacks)
	active_statuses[status_id] = {
		"remaining_duration": duration,
		"tick_interval": tick_interval,
		"tick_time_left": tick_interval,
		"flat_damage": float(status_payload.get("flat_damage", 0.0)),
		"max_hp_fraction": float(status_payload.get("max_hp_fraction", 0.0)),
		"stacks": next_stacks
	}
	return true

static func tick_statuses(active_statuses: Dictionary, delta: float, tick_callback: Callable) -> void:
	if active_statuses.is_empty():
		return
	var expired_statuses: Array[String] = []
	for status_id_variant in active_statuses.keys():
		var status_id := str(status_id_variant)
		var status_variant: Variant = active_statuses.get(status_id, {})
		if not (status_variant is Dictionary):
			expired_statuses.append(status_id)
			continue
		var status: Dictionary = status_variant
		var remaining_duration := maxf(float(status.get("remaining_duration", 0.0)) - delta, 0.0)
		var tick_time_left := float(status.get("tick_time_left", 0.0)) - delta
		var tick_interval := maxf(float(status.get("tick_interval", 0.0)), 0.0)
		while tick_interval > 0.0 and tick_time_left <= 0.0 and remaining_duration > 0.0:
			tick_callback.call(status)
			tick_time_left += tick_interval
		status["remaining_duration"] = remaining_duration
		status["tick_time_left"] = tick_time_left
		active_statuses[status_id] = status
		if remaining_duration <= 0.0:
			expired_statuses.append(status_id)
	for expired_status_id in expired_statuses:
		active_statuses.erase(expired_status_id)

static func try_spread_status(
	owner: Node2D,
	rng: RandomNumberGenerator,
	status_payload: Dictionary,
	source: Node,
	source_weapon_id: String,
	source_slot_index: int,
	status_power_multiplier: float
) -> void:
	if status_payload.get("allow_spread", false) != true:
		return
	var spread_radius := maxf(float(status_payload.get("spread_radius", 0.0)), 0.0)
	var spread_chance := clampf(float(status_payload.get("spread_chance", 0.0)), 0.0, 1.0)
	var spread_duration_scale := maxf(float(status_payload.get("spread_duration_scale", 1.0)), 0.0)
	var spread_max_targets := maxi(int(status_payload.get("spread_max_targets", 1)), 0)
	if spread_radius <= 0.0 or spread_chance <= 0.0 or spread_max_targets <= 0:
		return
	if rng.randf() > spread_chance:
		return

	var spread_payload := status_payload.duplicate(true)
	spread_payload["duration"] = float(spread_payload.get("duration", 0.0)) * spread_duration_scale
	spread_payload["allow_spread"] = false
	if float(spread_payload.get("duration", 0.0)) <= 0.0:
		return

	var targets_applied := 0
	for enemy in owner.get_tree().get_nodes_in_group("enemies"):
		if targets_applied >= spread_max_targets:
			break
		if not (enemy is Node2D) or not is_instance_valid(enemy) or enemy == owner:
			continue
		var enemy_node := enemy as Node2D
		if owner.global_position.distance_to(enemy_node.global_position) > spread_radius:
			continue
		if enemy_node.has_method("apply_status_payload"):
			enemy_node.call("apply_status_payload", spread_payload, source, source_weapon_id, source_slot_index, status_power_multiplier)
			targets_applied += 1
