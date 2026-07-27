class_name PlayerDamageRuntime
extends RefCounted

const ARMOR_SCALING: float = 15.0

static func resolve_incoming_damage(raw_damage: float, armor: float) -> float:
	var safe_damage := maxf(raw_damage, 0.0)
	if safe_damage <= 0.0 or is_zero_approx(armor):
		return safe_damage
	if armor > 0.0:
		return safe_damage * (ARMOR_SCALING / (ARMOR_SCALING + armor))
	return safe_damage * (1.0 + (absf(armor) / ARMOR_SCALING))
