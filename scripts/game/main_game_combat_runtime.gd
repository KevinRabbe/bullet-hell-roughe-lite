class_name MainGameCombatRuntime
extends RefCounted

static func set_combat_active(owner: Node, active: bool) -> void:
	if owner == null:
		return
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	RunFlowRuntime.set_process_mode_for_paths(
		owner,
		["Player", "EnemySpawner", "PortalEventManager", "RewardController", "BossManager"],
		mode
	)
	RunFlowRuntime.set_group_process_mode(owner.get_tree(), "enemies", mode)
	RunFlowRuntime.set_group_process_mode(owner.get_tree(), "projectiles", mode)

static func clear_combat_entities(tree: SceneTree) -> void:
	RunFlowRuntime.clear_group_nodes(tree, "enemies")
	RunFlowRuntime.clear_group_nodes(tree, "projectiles")

static func heal_player_to_full(player: Node) -> void:
	if player != null and player.has_method("heal_to_full"):
		player.call("heal_to_full")

static func is_shop_enabled(shop_controller: Node) -> bool:
	if shop_controller == null:
		return false
	return shop_controller.get("enabled") == true
