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
	var stats_variant: Variant = player.get("stats")
	if stats_variant is Object:
		var stats_object := stats_variant as Object
		profile.portal_luck = float(stats_object.get("portal_luck"))
		profile.portal_frequency = float(stats_object.get("portal_frequency"))
		profile.portal_instability = float(stats_object.get("portal_instability"))
		profile.portal_reward_multiplier = float(stats_object.get("portal_reward_multiplier"))
	if player.has_method("get_portal_event_bias"):
		profile.portal_event_biases = {
			"double_elite": maxf(float(player.call("get_portal_event_bias", "double_elite")), 0.0),
			"power_for_hp_loss": maxf(float(player.call("get_portal_event_bias", "power_for_hp_loss")), 0.0),
			"enemy_flood_20s": maxf(float(player.call("get_portal_event_bias", "enemy_flood_20s")), 0.0)
		}
	if player.has_method("get_portal_reward_tier_bias"):
		profile.portal_reward_tier_biases = {
			"2": float(player.call("get_portal_reward_tier_bias", 2)),
			"3": float(player.call("get_portal_reward_tier_bias", 3))
		}
	return profile

func get_event_bias(event_id: String) -> float:
	return maxf(float(portal_event_biases.get(event_id, 1.0)), 0.0)

func get_reward_tier_bias(tier: int) -> float:
	return float(portal_reward_tier_biases.get(str(tier), 0.0))

func compute_spawn_chance() -> float:
	var base_chance := 0.30
	var frequency_bonus := (portal_frequency - 1.0) * 0.15
	return clampf(base_chance + frequency_bonus, 0.25, 0.9)
