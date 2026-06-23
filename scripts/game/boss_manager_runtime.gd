extends RefCounted
class_name BossManagerRuntime

static func resolve_player(owner: Node, player_path: NodePath) -> Node2D:
	if player_path == NodePath():
		return null
	var player := owner.get_node_or_null(player_path)
	return player as Node2D if player is Node2D else null

static func should_auto_spawn(boss_spawned: bool, elapsed_seconds: float, spawn_after_seconds: float) -> bool:
	return not boss_spawned and elapsed_seconds >= spawn_after_seconds

static func is_debug_spawn_event(event: InputEvent, boss_spawned: bool, debug_spawn_key: Key) -> bool:
	if boss_spawned:
		return false
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	return key_event.pressed and not key_event.echo and key_event.keycode == debug_spawn_key

static func instantiate_boss(
	owner: Node,
	boss_scene: PackedScene,
	player: Node2D
) -> Node2D:
	if boss_scene == null:
		return null
	if player == null or not is_instance_valid(player):
		return null
	var boss_instance := boss_scene.instantiate()
	if not (boss_instance is Node2D):
		return null
	var boss := boss_instance as Node2D
	boss.global_position = player.global_position + Vector2(260.0, -40.0)
	_configure_boss_instance(boss, player)
	owner.get_tree().current_scene.add_child(boss)
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

static func _configure_boss_instance(boss: Node2D, player: Node2D) -> void:
	boss.set("is_boss", true)
	boss.set("move_speed", 150.0)
	boss.set("max_hp", 320.0)
	boss.set("current_hp", 320.0)
	boss.set("contact_damage", 22.0)
	boss.set("contact_range", 70.0)
	boss.set("damage_interval_seconds", 0.7)
	if boss.has_method("set_target"):
		boss.call("set_target", player)
