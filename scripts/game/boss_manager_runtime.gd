extends RefCounted
class_name BossManagerRuntime

const BOSS_DEFINITIONS: Dictionary = {
	"gate_beast": {
		"id": "gate_beast",
		"display_name": "Gate Beast",
		"pressure_id": "gate_beast"
	},
	"cinder_marshal": {
		"id": "cinder_marshal",
		"display_name": "Cinder Marshal",
		"pressure_id": "cinder_marshal"
	},
	"pyre_archon": {
		"id": "pyre_archon",
		"display_name": "Pyre Archon",
		"pressure_id": "pyre_archon"
	},
	"last_shade": {
		"id": "last_shade",
		"display_name": "Last Shade",
		"pressure_id": "last_shade"
	}
}

static func get_boss_definition(boss_id: String) -> Dictionary:
	var definition_variant: Variant = BOSS_DEFINITIONS.get(boss_id, {})
	return (definition_variant as Dictionary).duplicate(true) if definition_variant is Dictionary else {}

static func supported_boss_ids() -> Array[String]:
	var boss_ids: Array[String] = []
	for boss_id_variant in BOSS_DEFINITIONS.keys():
		boss_ids.append(str(boss_id_variant))
	boss_ids.sort()
	return boss_ids

static func resolve_player(owner: Node, player_path: NodePath) -> Node2D:
	if player_path == NodePath():
		return null
	var player := owner.get_node_or_null(player_path)
	return player as Node2D if player is Node2D else null

static func should_auto_spawn(boss_spawned: bool, elapsed_seconds: float, spawn_after_seconds: float) -> bool:
	return not boss_spawned and elapsed_seconds >= spawn_after_seconds

static func is_debug_spawn_event(event: InputEvent, boss_spawned: bool, debug_spawn_key: Key) -> bool:
	if not OS.is_debug_build():
		return false
	if boss_spawned:
		return false
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	return key_event.pressed and not key_event.echo and key_event.keycode == debug_spawn_key

static func instantiate_boss(
	owner: Node,
	boss_scene: PackedScene,
	player: Node2D,
	boss_id: String
) -> Node2D:
	if boss_scene == null:
		return null
	if player == null or not is_instance_valid(player):
		return null
	if get_boss_definition(boss_id).is_empty():
		return null
	if owner.get_tree() == null or owner.get_tree().current_scene == null:
		return null
	var boss_instance := boss_scene.instantiate()
	if not (boss_instance is Node2D):
		return null
	var boss := boss_instance as Node2D
	_configure_boss_instance(boss, player, boss_id)
	owner.get_tree().current_scene.add_child(boss)
	boss.global_position = player.global_position + Vector2(260.0, -40.0)
	return boss

static func evaluate_boss_exit(active_boss: Node2D, exiting_boss: Node2D) -> Dictionary:
	if exiting_boss != active_boss:
		return {
			"matches_active": false,
			"boss_defeated": false,
			"boss_should_reset_spawn": false
		}
	if exiting_boss == null or not is_instance_valid(exiting_boss):
		return {
			"matches_active": true,
			"boss_defeated": false,
			"boss_should_reset_spawn": false
		}
	var current_hp := float(exiting_boss.get("current_hp"))
	return {
		"matches_active": true,
		"boss_defeated": current_hp <= 0.0,
		"boss_should_reset_spawn": current_hp > 0.0
	}

static func _configure_boss_instance(boss: Node2D, player: Node2D, boss_id: String) -> void:
	boss.set("enemy_variant", boss_id)
	boss.set("is_boss", true)
	if boss.has_method("set_target"):
		boss.call("set_target", player)
