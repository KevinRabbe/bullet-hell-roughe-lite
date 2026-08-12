class_name WeaponAttackPatternRuntime
extends RefCounted

const PROJECTILE := "projectile"
const SPREAD := "spread"
const MELEE_ARC := "melee_arc"
const MINE := "mine"
const WAVE := "wave"
const ORBIT := "orbit"
const RETURNING := "returning"

const SUPPORTED_PATTERNS: Array[String] = [
	PROJECTILE,
	SPREAD,
	MELEE_ARC,
	MINE,
	WAVE,
	ORBIT,
	RETURNING
]

static func is_supported(pattern_id: String) -> bool:
	return pattern_id in SUPPORTED_PATTERNS

static func build_attack_directions(aim_direction: Vector2, weapon_data: WeaponData) -> Array[Vector2]:
	var base_direction := aim_direction.normalized() if aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	var projectile_count := maxi(weapon_data.projectiles_per_attack, 1)
	if weapon_data.attack_pattern != SPREAD or projectile_count == 1:
		return [base_direction]
	var directions: Array[Vector2] = []
	var spread_radians := deg_to_rad(clampf(weapon_data.spread_degrees, 0.0, 90.0))
	for projectile_index in projectile_count:
		var spread_position := float(projectile_index) / float(projectile_count - 1)
		var angle_offset := lerpf(-spread_radians * 0.5, spread_radians * 0.5, spread_position)
		directions.append(base_direction.rotated(angle_offset))
	return directions

static func resolve_target_range(weapon_data: WeaponData, normal_range: float, range_scale: float) -> float:
	var resolved_scale := maxf(range_scale, 0.1)
	match weapon_data.attack_pattern:
		MELEE_ARC:
			return (weapon_data.melee_reach * resolved_scale) + weapon_data.projectile_hit_radius + 36.0
		ORBIT:
			return (weapon_data.orbit_radius * resolved_scale) + weapon_data.projectile_hit_radius + 48.0
		MINE:
			return (weapon_data.mine_placement_distance * resolved_scale) + weapon_data.effect_radius
		_:
			return normal_range

static func resolve_spawn_position(
	weapon_data: WeaponData,
	shooter_position: Vector2,
	default_position: Vector2,
	aim_direction: Vector2,
	range_scale: float
) -> Vector2:
	if weapon_data.attack_pattern != MINE:
		return default_position
	var resolved_direction := aim_direction.normalized() if aim_direction.length_squared() > 0.0001 else Vector2.RIGHT
	return shooter_position + resolved_direction * weapon_data.mine_placement_distance * maxf(range_scale, 0.1)

static func build_behavior_lines(weapon_data: WeaponData) -> Array[String]:
	if weapon_data == null:
		return []
	var lines: Array[String] = []
	var signature_summary := weapon_data.signature_attack_summary.strip_edges()
	if signature_summary != "":
		lines.append("Signature: %s" % signature_summary)
	match weapon_data.attack_pattern:
		SPREAD:
			lines.append("Pattern: %d-pellet cone (%d deg)" % [weapon_data.projectiles_per_attack, roundi(weapon_data.spread_degrees)])
			lines.append("Per pellet: %d%% damage" % roundi(weapon_data.per_projectile_damage_multiplier * 100.0))
		MELEE_ARC:
			lines.append("Pattern: %d deg melee sweep (%d reach)" % [roundi(weapon_data.melee_arc_degrees), roundi(weapon_data.melee_reach)])
		MINE:
			lines.append("Pattern: Proximity mine (%.2fs arm)" % weapon_data.mine_arm_seconds)
			lines.append("Blast radius: %d" % roundi(weapon_data.effect_radius))
		WAVE:
			lines.append("Pattern: Piercing wave (%d radius)" % roundi(weapon_data.projectile_hit_radius))
			lines.append("Targets: Up to %d" % weapon_data.max_targets)
		ORBIT:
			lines.append("Pattern: Orbiting strike (%d radius)" % roundi(weapon_data.orbit_radius))
			lines.append("Duration: %.2fs" % weapon_data.get_projectile_lifetime_value())
		RETURNING:
			lines.append("Pattern: Returning throw (returns after %.2fs)" % weapon_data.return_after_seconds)
			lines.append("Return: %d%% speed / %d%% damage" % [
				roundi(weapon_data.return_speed_multiplier * 100.0),
				roundi(weapon_data.return_damage_multiplier * 100.0)
			])
		_:
			lines.append("Pattern: Single projectile")
	if weapon_data.attack_pattern not in [WAVE, MINE] and weapon_data.pierce > 0:
		lines.append("Pierce: %d extra target%s" % [weapon_data.pierce, "" if weapon_data.pierce == 1 else "s"])
	if weapon_data.knockback > 0.0:
		lines.append("Knockback: %.1f" % weapon_data.knockback)
	return lines

static func behavior_summary(weapon_data: WeaponData) -> String:
	if weapon_data != null and weapon_data.signature_attack_summary.strip_edges() != "":
		return weapon_data.signature_attack_summary.strip_edges()
	var lines := build_behavior_lines(weapon_data)
	return lines[0] if not lines.is_empty() else "Pattern: Unknown"
