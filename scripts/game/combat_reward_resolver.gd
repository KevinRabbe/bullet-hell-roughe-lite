class_name CombatRewardResolver
extends RefCounted

const GOLD_REMAINDER_PROPERTY := &"_gold_gain_remainder"
const XP_REMAINDER_PROPERTY := &"_xp_gain_remainder"

static func resolve(player: Node, base_gold: int, base_xp: int) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {"gold": maxi(base_gold, 0), "xp": maxi(base_xp, 0)}
	if player.has_method("resolve_combat_rewards"):
		var public_result: Variant = player.call("resolve_combat_rewards", base_gold, base_xp)
		if public_result is Dictionary:
			return (public_result as Dictionary).duplicate(true)

	var gold_result := _resolve_scaled_reward(
		base_gold,
		_get_effective_multiplier(player, "coin_gain"),
		_get_remainder(player, GOLD_REMAINDER_PROPERTY)
	)
	_set_remainder(player, GOLD_REMAINDER_PROPERTY, float(gold_result.get("remainder", 0.0)))

	var xp_result := _resolve_scaled_reward(
		base_xp,
		_get_effective_multiplier(player, "xp_gain"),
		_get_remainder(player, XP_REMAINDER_PROPERTY)
	)
	_set_remainder(player, XP_REMAINDER_PROPERTY, float(xp_result.get("remainder", 0.0)))

	return {
		"gold": int(gold_result.get("granted", 0)),
		"xp": int(xp_result.get("granted", 0))
	}

static func _get_effective_multiplier(player: Node, stat_id: String) -> float:
	if player.has_method("get_effective_stat_value"):
		return maxf(float(player.call("get_effective_stat_value", stat_id, 1.0)), 0.0)
	return 1.0

static func _get_remainder(player: Node, property_name: StringName) -> float:
	var value: Variant = player.get(property_name)
	if value is float or value is int:
		return maxf(float(value), 0.0)
	return 0.0

static func _set_remainder(player: Node, property_name: StringName, value: float) -> void:
	player.set(property_name, maxf(value, 0.0))

static func _resolve_scaled_reward(base_amount: int, multiplier: float, previous_remainder: float) -> Dictionary:
	if base_amount <= 0 or multiplier <= 0.0:
		return {"granted": 0, "remainder": maxf(previous_remainder, 0.0)}
	var total := (float(base_amount) * multiplier) + maxf(previous_remainder, 0.0)
	var granted := maxi(int(floor(total + 0.00001)), 0)
	return {
		"granted": granted,
		"remainder": maxf(total - float(granted), 0.0)
	}
