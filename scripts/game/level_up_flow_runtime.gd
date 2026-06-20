class_name LevelUpFlowRuntime
extends RefCounted

static func apply_choice(player: Node, choice: Dictionary) -> void:
	if player == null:
		return
	if player.has_method("apply_level_up_bonus"):
		player.call("apply_level_up_bonus", str(choice.get("id", "")), float(choice.get("value", 0.0)))
	if player.has_method("consume_pending_level_up"):
		player.call("consume_pending_level_up")

static func has_pending_choice(player: Node) -> bool:
	return player != null and player.has_method("has_pending_level_up") and player.call("has_pending_level_up") == true

static func try_reroll(player: Node, reroll_cost: int) -> bool:
	return player != null and player.has_method("spend_gold") and player.call("spend_gold", reroll_cost) == true
