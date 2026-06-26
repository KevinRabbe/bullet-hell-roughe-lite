extends RefCounted
class_name PortalEventManagerRuntime

static func resolve_player(owner: Node, player_path: NodePath) -> Node2D:
	if player_path == NodePath():
		return null
	var player := owner.get_node_or_null(player_path)
	return player as Node2D if player is Node2D else null

static func resolve_enemy_spawner(owner: Node, enemy_spawner_path: NodePath) -> Node:
	if enemy_spawner_path == NodePath():
		return null
	return owner.get_node_or_null(enemy_spawner_path)

static func count_active_portals(tree: SceneTree) -> int:
	var count := 0
	for portal in tree.get_nodes_in_group("portals"):
		if portal is Node and is_instance_valid(portal):
			count += 1
	return count

static func find_nearest_portal(tree: SceneTree, player: Node2D) -> Node:
	if player == null or not is_instance_valid(player):
		return null
	var nearest_portal: Node
	var nearest_distance_sq := INF
	for portal in tree.get_nodes_in_group("portals"):
		if portal is Node2D and is_instance_valid(portal):
			var portal_node := portal as Node2D
			var distance_sq := player.global_position.distance_squared_to(portal_node.global_position)
			if distance_sq < nearest_distance_sq:
				nearest_distance_sq = distance_sq
				nearest_portal = portal_node
	return nearest_portal

static func instantiate_portal(
	owner: Node,
	portal_scene: PackedScene,
	position: Vector2,
	activated_callback: Callable
) -> Node2D:
	if portal_scene == null:
		return null
	var portal_instance := portal_scene.instantiate()
	if not (portal_instance is Node2D):
		return null
	var portal := portal_instance as Node2D
	portal.global_position = position
	if portal.has_signal("activated") and activated_callback.is_valid():
		portal.connect("activated", activated_callback)
	owner.add_child(portal)
	return portal

static func apply_power_for_hp_loss(player: Node) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {"applied": false}
	var stats_variant: Variant = player.get("stats")
	if not (stats_variant is Object):
		return {"applied": false}
	var stats_object := stats_variant as Object
	var updated_damage := float(stats_object.get("damage")) + 0.35
	var updated_max_hp := maxf(float(stats_object.get("max_hp")) - 20.0, 20.0)
	stats_object.set("damage", updated_damage)
	stats_object.set("max_hp", updated_max_hp)
	player.set("current_hp", minf(float(player.get("current_hp")), updated_max_hp))
	if player.has_method("_update_hp_label"):
		player.call("_update_hp_label")
	return {
		"applied": true,
		"damage": updated_damage,
		"max_hp": updated_max_hp
	}

static func apply_attack_speed_for_damage_loss(player: Node) -> Dictionary:
	if player == null or not is_instance_valid(player):
		return {"applied": false}
	var stats_variant: Variant = player.get("stats")
	if not (stats_variant is Object):
		return {"applied": false}
	var stats_object := stats_variant as Object
	var updated_attack_speed := maxf(float(stats_object.get("attack_speed")) + 0.22, 0.1)
	var updated_damage := maxf(float(stats_object.get("damage")) - 0.18, 0.2)
	stats_object.set("attack_speed", updated_attack_speed)
	stats_object.set("damage", updated_damage)
	if player.has_method("_emit_ui_snapshot_changed"):
		player.call("_emit_ui_snapshot_changed")
	return {
		"applied": true,
		"attack_speed": updated_attack_speed,
		"damage": updated_damage
	}

static func apply_enemy_flood(enemy_spawner: Node) -> Dictionary:
	if enemy_spawner == null or not is_instance_valid(enemy_spawner):
		return {"applied": false}
	var original_spawn_interval := float(enemy_spawner.get("spawn_interval_seconds"))
	var original_max_alive := int(enemy_spawner.get("max_alive_enemies"))
	enemy_spawner.set("spawn_interval_seconds", maxf(original_spawn_interval * 0.45, 0.25))
	enemy_spawner.set("max_alive_enemies", original_max_alive + 20)
	return {
		"applied": true,
		"original_spawn_interval": original_spawn_interval,
		"original_max_alive": original_max_alive
	}

static func restore_enemy_flood(enemy_spawner: Node, original_spawn_interval: float, original_max_alive: int) -> void:
	if enemy_spawner == null or not is_instance_valid(enemy_spawner):
		return
	enemy_spawner.set("spawn_interval_seconds", original_spawn_interval)
	enemy_spawner.set("max_alive_enemies", original_max_alive)

static func apply_enemy_speed_pressure(enemy_spawner: Node, speed_multiplier: float) -> Dictionary:
	if enemy_spawner == null or not is_instance_valid(enemy_spawner):
		return {"applied": false}
	var original_multiplier := float(enemy_spawner.get("external_move_speed_multiplier"))
	var safe_multiplier := maxf(speed_multiplier, 1.0)
	enemy_spawner.set("external_move_speed_multiplier", safe_multiplier)
	return {
		"applied": true,
		"original_move_speed_multiplier": original_multiplier,
		"move_speed_multiplier": safe_multiplier
	}

static func restore_enemy_speed_pressure(enemy_spawner: Node, original_multiplier: float) -> void:
	if enemy_spawner == null or not is_instance_valid(enemy_spawner):
		return
	enemy_spawner.set("external_move_speed_multiplier", original_multiplier)

static func spawn_elite(
	owner: Node,
	elite_enemy_scene: PackedScene,
	player: Node2D,
	spawn_position: Vector2,
	elite_move_speed: float,
	elite_max_hp: float,
	elite_role: String
) -> Node:
	if elite_enemy_scene == null:
		return null
	var enemy_instance := elite_enemy_scene.instantiate()
	if not (enemy_instance is Node2D):
		return null
	var enemy_node := enemy_instance as Node2D
	enemy_node.global_position = spawn_position
	if enemy_node.has_method("set_target"):
		enemy_node.call("set_target", player)
	if enemy_node.has_method("set"):
		enemy_node.set("move_speed", elite_move_speed)
		enemy_node.set("max_hp", elite_max_hp)
		enemy_node.set("current_hp", elite_max_hp)
		enemy_node.set("is_elite", true)
		enemy_node.set("elite_role", elite_role)
	owner.add_child(enemy_node)
	return enemy_node

static func track_event_elite(active_event_elites: Array[Node], enemy: Node, exited_callback: Callable) -> void:
	if enemy == null:
		return
	active_event_elites.append(enemy)
	if exited_callback.is_valid():
		enemy.tree_exited.connect(exited_callback.bind(enemy))

static func pick_elite_role(rng: RandomNumberGenerator) -> String:
	if rng != null and rng.randf() < 0.5:
		return "horned_bruiser"
	return "rift_caller"
