class_name MainGameActivationRuntime
extends RefCounted

const OVERLAY_PATHS: Array[NodePath] = [
	NodePath("WaveIntermission/Panel"),
	NodePath("ShopUI/Panel"),
	NodePath("LevelUpUI/Panel"),
	NodePath("RunEndUI/Panel")
]

const COMBAT_NODE_PATHS: Array[String] = [
	"Player",
	"EnemySpawner",
	"PortalEventManager",
	"RewardController",
	"BossManager"
]

static func hide_run_overlays(owner: Node) -> void:
	if owner == null:
		return
	for path in OVERLAY_PATHS:
		var node := owner.get_node_or_null(path)
		if node is Control:
			(node as Control).visible = false

static func set_gameplay_active(
	owner: Node,
	character_select_layer: CanvasLayer,
	shop_node: Node,
	active: bool
) -> void:
	if owner != null and owner.has_method("_set_combat_active"):
		owner.call("_set_combat_active", active)
	var shop_mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	if shop_node != null:
		shop_node.process_mode = shop_mode
	if not active:
		hide_run_overlays(owner)
	if character_select_layer != null:
		character_select_layer.visible = not active
