class_name PortalEventPresentationRuntime
extends RefCounted

const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")

static func show_event_started(owner: Node, event_result: Dictionary) -> void:
	var event_id := str(event_result.get("event_id", "double_elite"))
	var event_data_variant: Variant = event_result.get("event_data", {})
	var event_data: Dictionary = event_data_variant if event_data_variant is Dictionary else {}
	var title := str(event_data.get("title", _fallback_title(event_id))).strip_edges()
	var description := str(event_data.get("description", _fallback_description(event_id))).strip_edges()
	var category := str(event_data.get("category", "event")).strip_edges().to_lower()
	EventBannerRuntimeRef.show(
		owner,
		_eyebrow_for_category(category),
		title.to_upper(),
		description
	)

static func _eyebrow_for_category(category: String) -> String:
	match category:
		"trade":
			return "RIFT BARGAIN"
		"swarm":
			return "RIFT SURGE"
		"greed":
			return "RIFT GREED"
		"boss":
			return "RIFT HUNT"
		_:
			return "PORTAL EVENT"

static func _fallback_title(event_id: String) -> String:
	var normalized := event_id.strip_edges().replace("_", " ")
	return normalized.capitalize() if normalized != "" else "Portal Event"

static func _fallback_description(event_id: String) -> String:
	match event_id:
		"double_elite":
			return "Two elite enemies answer the rift."
		"power_for_hp_loss":
			return "Gain damage at the cost of permanent Max HP."
		"attack_speed_for_damage_loss":
			return "Attack faster at the cost of permanent direct damage."
		"enemy_flood_20s":
			return "Survive a dense enemy flood for twenty seconds."
		"triple_reward_for_enemy_speed":
			return "Survive faster enemies to claim three rewards."
		_:
			return "The rift changes the rules of this fight."
