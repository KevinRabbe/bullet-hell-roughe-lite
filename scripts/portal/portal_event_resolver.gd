class_name PortalEventResolver
extends RefCounted

const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")

static func pick_event_id(rng: RandomNumberGenerator, profile: PortalRunProfile) -> String:
	var safe_profile := profile if profile != null else PortalRunProfile.new()
	var event_ids: Array = []
	var weights: Array[float] = []
	_append_weighted_event(
		event_ids,
		weights,
		"double_elite",
		(1.0 + (safe_profile.portal_instability * 1.2)) * safe_profile.get_event_bias("double_elite")
	)
	_append_weighted_event(
		event_ids,
		weights,
		"power_for_hp_loss",
		1.0 * safe_profile.get_event_bias("power_for_hp_loss")
	)
	_append_weighted_event(
		event_ids,
		weights,
		"enemy_flood_20s",
		(1.0 + (safe_profile.portal_instability * 1.5)) * safe_profile.get_event_bias("enemy_flood_20s")
	)
	if event_ids.is_empty():
		return "double_elite"
	return str(WeightedPicker.pick_value(rng, event_ids, weights))

static func roll_reward_tier(rng: RandomNumberGenerator, source: String, profile: PortalRunProfile) -> Dictionary:
	if source != "portal_event":
		return {
			"tier": 1,
			"tier2_chance": 0.0,
			"tier3_chance": 0.0
		}
	var safe_profile := profile if profile != null else PortalRunProfile.new()
	var reward_multiplier := maxf(safe_profile.portal_reward_multiplier, 0.25)
	var tier2_bias := safe_profile.get_reward_tier_bias(2)
	var tier3_bias := safe_profile.get_reward_tier_bias(3)
	var tier2_chance := clampf(((0.35 + (safe_profile.portal_luck * 0.08) + (safe_profile.portal_instability * 0.03)) * reward_multiplier) + tier2_bias, 0.2, 0.9)
	var tier3_chance := clampf(((0.08 + (safe_profile.portal_luck * 0.05) + (safe_profile.portal_instability * 0.1)) * reward_multiplier) + tier3_bias, 0.02, 0.7)
	var roll := rng.randf()
	var tier := 1
	if roll <= tier3_chance:
		tier = 3
	elif roll <= tier2_chance:
		tier = 2
	return {
		"tier": tier,
		"roll": roll,
		"tier2_chance": tier2_chance,
		"tier3_chance": tier3_chance,
		"tier2_bias": tier2_bias,
		"tier3_bias": tier3_bias,
		"portal_luck": safe_profile.portal_luck,
		"portal_instability": safe_profile.portal_instability
	}

static func _append_weighted_event(event_ids: Array, weights: Array[float], event_id: String, weight: float) -> void:
	var safe_weight := maxf(weight, 0.0)
	if safe_weight <= 0.0:
		return
	event_ids.append(event_id)
	weights.append(safe_weight)
