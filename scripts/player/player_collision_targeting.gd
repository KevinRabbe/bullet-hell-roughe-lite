extends Node

var player_facade: Node

func configure(next_player_facade: Node) -> void:
	player_facade = next_player_facade

func get_damage_multiplier_for_target(target: Node) -> float:
	if player_facade == null or target == null:
		return 1.0
	var active_character_data: Dictionary = player_facade.get("active_character_data")
	var log_runtime_events: bool = player_facade.get("log_runtime_events") == true
	var damage_rules_variant: Variant = active_character_data.get("damage_rules", [])
	if damage_rules_variant is Array:
		var damage_rules: Array = damage_rules_variant
		for damage_rule_variant in damage_rules:
			if not (damage_rule_variant is Dictionary):
				continue
			var damage_rule: Dictionary = damage_rule_variant
			if target_matches_damage_rule(target, damage_rule):
				var debug_label: String = str(damage_rule.get("debug_label", ""))
				if debug_label != "" and log_runtime_events:
					print(debug_label)
				return float(damage_rule.get("multiplier", 1.0))
	return 1.0

func get_status_propagation_rule(status_id: String) -> Dictionary:
	if player_facade == null:
		return {}
	var active_character_data: Dictionary = player_facade.get("active_character_data")
	var propagation_rules_variant: Variant = active_character_data.get("status_propagation_rules", {})
	if not (propagation_rules_variant is Dictionary):
		return {}
	var propagation_rules: Dictionary = propagation_rules_variant
	var rule_variant: Variant = propagation_rules.get(status_id, {})
	if rule_variant is Dictionary:
		var resolved_rule: Dictionary = (rule_variant as Dictionary).duplicate(true)
		apply_pressure_scaling_to_propagation_rule(resolved_rule)
		apply_status_density_scaling_to_propagation_rule(status_id, resolved_rule)
		return resolved_rule
	return {}

func count_enemies_with_status(status_id: String, max_distance: float = 0.0) -> int:
	if status_id == "" or player_facade == null:
		return 0
	var count: int = 0
	for enemy in player_facade.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if max_distance > 0.0 and enemy is Node2D:
			var enemy_node: Node2D = enemy as Node2D
			var player_position: Vector2 = (player_facade as Node2D).global_position
			if player_position.distance_to(enemy_node.global_position) > max_distance:
				continue
		if enemy.has_method("get_status_stack_count") and int(enemy.call("get_status_stack_count", status_id)) > 0:
			count += 1
	return count

func count_nearby_enemies(max_distance: float) -> int:
	if max_distance <= 0.0 or player_facade == null:
		return 0
	var count: int = 0
	var player_position: Vector2 = (player_facade as Node2D).global_position
	for enemy in player_facade.get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var enemy_node: Node2D = enemy as Node2D
		if player_position.distance_to(enemy_node.global_position) <= max_distance:
			count += 1
	return count

func target_matches_damage_rule(target: Node, damage_rule: Dictionary) -> bool:
	var targets_variant: Variant = damage_rule.get("targets", [])
	if not (targets_variant is Array):
		return false
	var targets: Array = targets_variant
	for target_key_variant in targets:
		var target_key: String = str(target_key_variant)
		match target_key:
			"elite":
				if target.get("is_elite") == true:
					return true
			"boss":
				if target.get("is_boss") == true:
					return true
			"strongest":
				if is_priority_damage_target(target):
					return true
	return false

func is_priority_damage_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target) or player_facade == null:
		return false
	if target.get("is_priority_target") == true:
		return true
	if not target.is_in_group("enemies"):
		return false
	var strongest_hp: float = -INF
	var strongest_target: Node = null
	for enemy in player_facade.get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_hp: float = float(enemy.get("current_hp"))
		if enemy_hp > strongest_hp:
			strongest_hp = enemy_hp
			strongest_target = enemy
	return strongest_target == target

func apply_pressure_scaling_to_propagation_rule(rule: Dictionary) -> void:
	var pressure_radius: float = maxf(float(rule.get("pressure_radius", 0.0)), 0.0)
	if pressure_radius <= 0.0:
		return
	var nearby_enemy_count: int = count_nearby_enemies(pressure_radius)
	if nearby_enemy_count <= 0:
		return
	var pressure_target_limit: int = maxi(int(rule.get("pressure_target_limit", nearby_enemy_count)), 1)
	var effective_pressure: int = mini(nearby_enemy_count, pressure_target_limit)
	rule["chance"] = clampf(
		float(rule.get("chance", 0.0)) + (float(rule.get("spread_chance_per_nearby_enemy", 0.0)) * effective_pressure),
		0.0,
		1.0
	)
	rule["radius"] = maxf(
		float(rule.get("radius", 0.0)) + (float(rule.get("spread_radius_per_nearby_enemy", 0.0)) * effective_pressure),
		0.0
	)
	rule["max_targets"] = maxi(
		int(round(float(rule.get("max_targets", 1)) + (float(rule.get("spread_max_targets_per_nearby_enemy", 0.0)) * effective_pressure))),
		1
	)

func apply_status_density_scaling_to_propagation_rule(status_id: String, rule: Dictionary) -> void:
	var counted_status_id: String = str(rule.get("spread_status_count_id", status_id))
	if counted_status_id == "":
		return
	var count_radius: float = maxf(float(rule.get("spread_status_count_radius", 0.0)), 0.0)
	var marked_enemy_count: int = count_enemies_with_status(counted_status_id, count_radius)
	if marked_enemy_count <= 0:
		return
	var marked_enemy_limit: int = maxi(int(rule.get("spread_status_count_limit", marked_enemy_count)), 1)
	var effective_mark_count: int = mini(marked_enemy_count, marked_enemy_limit)
	rule["chance"] = clampf(
		float(rule.get("chance", 0.0)) + (float(rule.get("spread_chance_per_marked_enemy", 0.0)) * effective_mark_count),
		0.0,
		1.0
	)
	rule["radius"] = maxf(
		float(rule.get("radius", 0.0)) + (float(rule.get("spread_radius_per_marked_enemy", 0.0)) * effective_mark_count),
		0.0
	)
	rule["max_targets"] = maxi(
		int(round(float(rule.get("max_targets", 1)) + (float(rule.get("spread_max_targets_per_marked_enemy", 0.0)) * effective_mark_count))),
		1
	)
