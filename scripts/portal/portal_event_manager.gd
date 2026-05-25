extends Node2D

@export var portal_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var player_path: NodePath
@export var first_portal_position: Vector2 = Vector2(240.0, 0.0)
@export var elite_spawn_distance: float = 180.0
@export var elite_move_speed: float = 240.0
@export var elite_max_hp: float = 80.0

var player: Node2D

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	_spawn_first_portal()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_activate_nearest_portal()

func _spawn_first_portal() -> void:
	if portal_scene == null:
		return
	var portal_instance := portal_scene.instantiate()
	if portal_instance is Node2D:
		var portal := portal_instance as Node2D
		portal.global_position = first_portal_position
		if portal.has_signal("activated"):
			portal.connect("activated", _on_portal_activated)
		add_child(portal)

func _try_activate_nearest_portal() -> void:
	if player == null or not is_instance_valid(player):
		return

	var nearest_portal: Node
	var nearest_distance_sq := INF
	for portal in get_tree().get_nodes_in_group("portals"):
		if portal is Node2D and is_instance_valid(portal):
			var portal_node := portal as Node2D
			var distance_sq := player.global_position.distance_squared_to(portal_node.global_position)
			if distance_sq < nearest_distance_sq:
				nearest_distance_sq = distance_sq
				nearest_portal = portal_node

	if nearest_portal != null and nearest_portal.has_method("try_activate"):
		nearest_portal.call("try_activate", player)

func _on_portal_activated(portal_position: Vector2) -> void:
	_spawn_elite(portal_position + Vector2.LEFT * elite_spawn_distance)
	_spawn_elite(portal_position + Vector2.RIGHT * elite_spawn_distance)

func _spawn_elite(spawn_position: Vector2) -> void:
	if elite_enemy_scene == null:
		return

	var enemy_instance := elite_enemy_scene.instantiate()
	if enemy_instance is Node2D:
		var enemy_node := enemy_instance as Node2D
		enemy_node.global_position = spawn_position
		if enemy_node.has_method("set_target"):
			enemy_node.call("set_target", player)
		if enemy_node.has_method("set"):
			enemy_node.set("move_speed", elite_move_speed)
			enemy_node.set("max_hp", elite_max_hp)
			enemy_node.set("current_hp", elite_max_hp)
		add_child(enemy_node)
