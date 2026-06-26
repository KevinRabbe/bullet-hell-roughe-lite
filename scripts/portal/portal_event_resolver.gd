class_name PortalEventResolver
extends RefCounted

const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")

static func pick_event_id(rng: RandomNumberGenerator, profile: PortalRunProfile) -> String:
	return str(build_event_roll(rng, profile).get("event_id", "double_elite"))

static func build_event_roll(rng: RandomNumberGenerator, profile: PortalRunProfile) -> Dictionary:
	var safe_profile := profile if profile != null else PortalRunProfile.new()
	var event_definitions := _load_event_definitions()
	if not event_definitions.is_empty():
		return _build_event_roll_from_data(rng, safe_profile, event_definitions)
	return _build_fallback_event_roll(rng, safe_profile)

static func roll_reward_tier(
	rng: RandomNumberGenerator,
	source: String,
	profile: PortalRunProfile,
	event_result: Dictionary = {}
) -> Dictionary:
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
	var event_data_variant: Variant = event_result.get("event_data", {})
	var event_data: Dictionary = event_data_variant if event_data_variant is Dictionary else {}
	var event_tier_biases_variant: Variant = event_data.get("reward_tier_biases", {})
	var event_tier_biases: Dictionary = event_tier_biases_variant if event_tier_biases_variant is Dictionary else {}
	var event_tier2_bonus := float(event_tier_biases.get("2", 0.0))
	var event_tier3_bonus := float(event_tier_biases.get("3", 0.0))
	var tier2_chance := clampf(((0.35 + (safe_profile.portal_luck * 0.08) + (safe_profile.portal_instability * 0.03)) * reward_multiplier) + tier2_bias + event_tier2_bonus, 0.2, 0.95)
	var tier3_chance := clampf(((0.08 + (safe_profile.portal_luck * 0.05) + (safe_profile.portal_instability * 0.1)) * reward_multiplier) + tier3_bias + event_tier3_bonus, 0.02, 0.8)
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
		"event_tier2_bonus": event_tier2_bonus,
		"event_tier3_bonus": event_tier3_bonus,
		"portal_luck": safe_profile.portal_luck,
		"portal_instability": safe_profile.portal_instability
	}

static func _build_fallback_event_roll(rng: RandomNumberGenerator, safe_profile: PortalRunProfile) -> Dictionary:
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
		return {
			"event_id": "double_elite",
			"event_ids": [],
			"weights": [],
			"portal_instability": safe_profile.portal_instability
		}
	return {
		"event_id": str(WeightedPicker.pick_value(rng, event_ids, weights)),
		"event_ids": event_ids,
		"weights": weights,
		"portal_instability": safe_profile.portal_instability
	}

static func _build_event_roll_from_data(
	rng: RandomNumberGenerator,
	safe_profile: PortalRunProfile,
	event_definitions: Array[Dictionary]
) -> Dictionary:
	var event_ids: Array = []
	var weights: Array[float] = []
	for event_definition in event_definitions:
		var event_id := str(event_definition.get("id", ""))
		if event_id == "":
			continue
		var base_weight := maxf(float(event_definition.get("base_weight", 0.0)), 0.0)
		var instability_scale := float(event_definition.get("instability_weight_scale", 0.0))
		var profile_weight := (base_weight * (1.0 + (safe_profile.portal_instability * instability_scale))) * safe_profile.get_event_bias(event_id)
		_append_weighted_event(event_ids, weights, event_id, profile_weight)
	if event_ids.is_empty():
		return _build_fallback_event_roll(rng, safe_profile)
	var picked_event_id := str(WeightedPicker.pick_value(rng, event_ids, weights))
	var picked_event_data := _find_event_definition(event_definitions, picked_event_id)
	return {
		"event_id": picked_event_id,
		"event_ids": event_ids,
		"weights": weights,
		"portal_instability": safe_profile.portal_instability,
		"event_data": picked_event_data
	}

static func _load_event_definitions() -> Array[Dictionary]:
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return []
	var registry := (main_loop as SceneTree).root.get_node_or_null("DataRegistry")
	if registry == null:
		return []
	var event_dictionary_variant: Variant = registry.get("portal_events")
	if not (event_dictionary_variant is Dictionary):
		return []
	var event_dictionary: Dictionary = event_dictionary_variant
	if event_dictionary.is_empty():
		return []
	var event_ids: Array[String] = []
	for event_id_variant in event_dictionary.keys():
		var event_id := str(event_id_variant)
		if event_id != "":
			event_ids.append(event_id)
	event_ids.sort()
	var definitions: Array[Dictionary] = []
	for event_id in event_ids:
		var event_variant: Variant = event_dictionary.get(event_id, {})
		if event_variant is Dictionary:
			definitions.append((event_variant as Dictionary).duplicate(true))
	return definitions

static func _find_event_definition(event_definitions: Array[Dictionary], event_id: String) -> Dictionary:
	for event_definition in event_definitions:
		if str(event_definition.get("id", "")) == event_id:
			return event_definition
	return {}

static func _append_weighted_event(event_ids: Array, weights: Array[float], event_id: String, weight: float) -> void:
	var safe_weight := maxf(weight, 0.0)
	if safe_weight <= 0.0:
		return
	event_ids.append(event_id)
	weights.append(safe_weight)
