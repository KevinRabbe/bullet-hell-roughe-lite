extends RefCounted
class_name PortalRiskRewardRuntime

const PortalEventResolver = preload("res://scripts/portal/portal_event_resolver.gd")
const PortalRunProfile = preload("res://scripts/portal/portal_run_profile.gd")

const AUTHORED_SEVERITY_LEVELS: Array[String] = ["low", "moderate", "high", "extreme"]

static func build_profile(player: Node) -> PortalRunProfile:
	return PortalRunProfile.from_player(player)

static func pick_event_result(rng: RandomNumberGenerator, player: Node) -> Dictionary:
	var profile := build_profile(player)
	var event_result := PortalEventResolver.build_event_roll(rng, profile)
	event_result["profile"] = profile
	return event_result

static func is_authored_severity(value: String) -> bool:
	return value.strip_edges().to_lower() in AUTHORED_SEVERITY_LEVELS

static func roll_reward_tier_result(
	rng: RandomNumberGenerator,
	source: String,
	player: Node,
	event_result: Dictionary = {}
) -> Dictionary:
	return PortalEventResolver.roll_reward_tier(rng, source, build_profile(player), event_result)
