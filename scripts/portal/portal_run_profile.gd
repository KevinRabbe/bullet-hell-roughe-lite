class_name PortalRunProfile
extends RefCounted

var portal_luck: float = 0.0
var portal_frequency: float = 1.0
var portal_instability: float = 0.0
var portal_reward_multiplier: float = 1.0
var portal_event_biases: Dictionary = {}
var portal_reward_tier_biases: Dictionary = {}

static func from_player(player: Node) -> PortalRunProfile:
	var profile := PortalRunProfile.new()
	if player == null or not is_instance_valid(player):
		return profile
	if player.has_method("get_effective_stat_value"):
		profile.portal_luck = float(player.call("get_effective_stat_value", "portal_luck", 0.0))
		profile.portal_frequency = float(player.call("get_effective_stat_value", "portal_frequency", 1.0))
		profile.portal_instability = float(player.call("get_effective_stat_value", "portal_instability", 0.0))
		profile.portal_reward_multiplier = float(player.call("get_effective_stat_value", "portal_reward_multiplier", 1.0))
	else:
		var stats_variant: Variant = player.get("stats")
		if stats_variant is Object:
			var stats_object := stats_variant as Object
			profile.portal_luck = float(stats_object.get("portal_luck"))
			profile.portal_frequency = float(stats_object.get("portal_frequency"))
			profile.portal_instability = float(stats_object.get("portal_instability"))
			profile.portal_reward_multiplier = float(stats_object.get("portal_reward_multiplier"))
	if player.has_method("get_portal_event_bias"):
		for event_id in _resolve_portal_event_ids():
			profile.portal_event_biases[event_id] = maxf(float(player.call("get_portal_event_bias", event_id)), 0.0)
	if player.has_method("get_portal_reward_tier_bias"):
		profile.portal_reward_tier_biases = {
			"2": float(player.call("get_portal_reward_tier_bias", 2)),
			"3": float(player.call("get_portal_reward_tier_bias", 3))
		}
	return profile

static func _resolve_portal_event_ids() -> Array[String]:
	var default_ids: Array[String] = [
		"attack_speed_for_damage_loss",
		"double_elite",
		"enemy_flood_20s",
		"power_for_hp_loss",
		"triple_reward_for_enemy_speed"
	]
	var main_loop := Engine.get_main_loop()
	if not (main_loop is SceneTree):
		return default_ids
	var registry := (main_loop as SceneTree).root.get_node_or_null("DataRegistry")
	if registry == null:
		return default_ids
	var event_dictionary_variant: Variant = registry.get("portal_events")
	if not (event_dictionary_variant is Dictionary):
		return default_ids
	var event_dictionary: Dictionary = event_dictionary_variant
	if event_dictionary.is_empty():
		return default_ids
	var event_ids: Array[String] = []
	for event_id_variant in event_dictionary.keys():
		var event_id := str(event_id_variant)
		if event_id != "":
			event_ids.append(event_id)
	event_ids.sort()
	return event_ids if not event_ids.is_empty() else default_ids

func get_event_bias(event_id: String) -> float:
	return maxf(float(portal_event_biases.get(event_id, 1.0)), 0.0)

func get_reward_tier_bias(tier: int) -> float:
	return float(portal_reward_tier_biases.get(str(tier), 0.0))

func compute_spawn_chance() -> float:
	var base_chance := 0.30
	var frequency_bonus := (portal_frequency - 1.0) * 0.15
	return clampf(base_chance + frequency_bonus, 0.25, 0.9)
