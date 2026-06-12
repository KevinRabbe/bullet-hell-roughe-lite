class_name ProjectileImpactHelper
extends RefCounted

static func compute_final_damage(
	base_damage: float,
	damage_multiplier: float,
	shooter: Node,
	target: Node,
	weapon_data: WeaponData
) -> float:
	var final_damage := base_damage * damage_multiplier
	if shooter != null and shooter.has_method("get_damage_multiplier_for_target"):
		final_damage *= float(shooter.call("get_damage_multiplier_for_target", target))
	if weapon_data == null:
		return final_damage
	final_damage = _apply_status_bonus_damage(final_damage, target, weapon_data)
	final_damage = _apply_density_bonus_damage(final_damage, shooter, weapon_data)
	final_damage = _apply_player_stat_bonus_damage(final_damage, shooter, weapon_data)
	return final_damage

static func _apply_status_bonus_damage(final_damage: float, target: Node, weapon_data: WeaponData) -> float:
	if weapon_data.bonus_damage_vs_status_id == "":
		return final_damage
	var stacks := 0
	if target != null and target.has_method("get_status_stack_count"):
		stacks = int(target.call("get_status_stack_count", weapon_data.bonus_damage_vs_status_id))
	if stacks <= 0:
		return final_damage
	final_damage *= weapon_data.bonus_damage_vs_status_multiplier
	if weapon_data.bonus_damage_vs_status_max_hp_fraction > 0.0:
		final_damage += _get_target_max_hp(target) * weapon_data.bonus_damage_vs_status_max_hp_fraction * float(stacks)
	return final_damage

static func _apply_density_bonus_damage(final_damage: float, shooter: Node, weapon_data: WeaponData) -> float:
	if shooter == null:
		return final_damage
	if weapon_data.bonus_damage_per_enemy_with_status_id == "":
		return final_damage
	if weapon_data.bonus_damage_per_enemy_with_status_amount <= 0.0:
		return final_damage
	if not shooter.has_method("count_enemies_with_status"):
		return final_damage
	var empowered_enemy_count := int(shooter.call("count_enemies_with_status", weapon_data.bonus_damage_per_enemy_with_status_id))
	if weapon_data.bonus_damage_per_enemy_with_status_max_enemies > 0:
		empowered_enemy_count = mini(empowered_enemy_count, weapon_data.bonus_damage_per_enemy_with_status_max_enemies)
	if empowered_enemy_count <= 0:
		return final_damage
	return final_damage * (1.0 + (weapon_data.bonus_damage_per_enemy_with_status_amount * float(empowered_enemy_count)))

static func _apply_player_stat_bonus_damage(final_damage: float, shooter: Node, weapon_data: WeaponData) -> float:
	if shooter == null:
		return final_damage
	if weapon_data.bonus_damage_per_player_stat_id == "":
		return final_damage
	if weapon_data.bonus_damage_per_player_stat_amount <= 0.0:
		return final_damage
	if not shooter.has_method("get_stat_value_for_weapon_bonus"):
		return final_damage
	var player_stat_value := float(shooter.call("get_stat_value_for_weapon_bonus", weapon_data.bonus_damage_per_player_stat_id, 0.0))
	if weapon_data.bonus_damage_per_player_stat_max_value > 0.0:
		player_stat_value = minf(player_stat_value, weapon_data.bonus_damage_per_player_stat_max_value)
	if player_stat_value <= 0.0:
		return final_damage
	return final_damage * (1.0 + (weapon_data.bonus_damage_per_player_stat_amount * player_stat_value))

static func _get_target_max_hp(target: Node) -> float:
	if target == null:
		return 0.0
	return maxf(float(target.get("max_hp")), 0.0)
