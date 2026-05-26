extends Node2D

signal portal_event_completed

@export var portal_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var first_portal_position: Vector2 = Vector2(240.0, 0.0)
@export var elite_spawn_distance: float = 180.0
@export var elite_move_speed: float = 240.0
@export var elite_max_hp: float = 80.0

var player: Node2D
var enemy_spawner: Node
var active_event_elites: Array[Node] = []
var rng := RandomNumberGenerator.new()
var flood_timer: Timer
var flood_original_spawn_interval: float = 1.2
var flood_original_max_alive: int = 25

func _ready() -> void:
	rng.randomize()
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	flood_timer = Timer.new()
	flood_timer.one_shot = true
	flood_timer.timeout.connect(_on_flood_event_finished)
	add_child(flood_timer)
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
	var event_id := _pick_portal_event_id()
	print("Portal activated. Event: %s" % event_id)
	match event_id:
		"double_elite":
			_start_double_elite_event(portal_position)
		"power_for_hp_loss":
			_start_power_for_hp_loss_event()
		"enemy_flood_20s":
			_start_enemy_flood_event()

func _start_double_elite_event(portal_position: Vector2) -> void:
	print("Portal event started: Double Elite")
	active_event_elites.clear()
	_track_event_elite(_spawn_elite(portal_position + Vector2.LEFT * elite_spawn_distance))
	_track_event_elite(_spawn_elite(portal_position + Vector2.RIGHT * elite_spawn_distance))
	if active_event_elites.is_empty():
		print("Portal event completed: no active elites.")
		portal_event_completed.emit()

func _start_power_for_hp_loss_event() -> void:
	print("Portal event started: Power for Max HP loss")
	if player != null and is_instance_valid(player):
		var stats_variant := player.get("stats")
		if stats_variant != null and stats_variant is Object:
			stats_variant.set("damage", float(stats_variant.get("damage")) + 0.35)
			stats_variant.set("max_hp", maxf(float(stats_variant.get("max_hp")) - 20.0, 20.0))
			player.set("current_hp", minf(float(player.get("current_hp")), float(stats_variant.get("max_hp"))))
			if player.has_method("_update_hp_label"):
				player.call("_update_hp_label")
			print("Power trade applied: +0.35 damage, -20 max HP")
	print("Portal event completed: Power for Max HP loss")
	portal_event_completed.emit()

func _start_enemy_flood_event() -> void:
	print("Portal event started: 20-second enemy flood")
	if enemy_spawner != null and is_instance_valid(enemy_spawner):
		flood_original_spawn_interval = float(enemy_spawner.get("spawn_interval_seconds"))
		flood_original_max_alive = int(enemy_spawner.get("max_alive_enemies"))
		enemy_spawner.set("spawn_interval_seconds", maxf(flood_original_spawn_interval * 0.45, 0.25))
		enemy_spawner.set("max_alive_enemies", flood_original_max_alive + 20)
	flood_timer.start(20.0)

func _on_flood_event_finished() -> void:
	if enemy_spawner != null and is_instance_valid(enemy_spawner):
		enemy_spawner.set("spawn_interval_seconds", flood_original_spawn_interval)
		enemy_spawner.set("max_alive_enemies", flood_original_max_alive)
	print("Portal event completed: enemy flood survived.")
	portal_event_completed.emit()

func _spawn_elite(spawn_position: Vector2) -> Node:
	if elite_enemy_scene == null:
		return null

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
		return enemy_node
	return null

func _track_event_elite(enemy: Node) -> void:
	if enemy == null:
		return
	active_event_elites.append(enemy)
	enemy.tree_exited.connect(_on_event_elite_exited.bind(enemy))

func _on_event_elite_exited(enemy: Node) -> void:
	active_event_elites.erase(enemy)
	print("Portal elite defeated. Remaining elites: %d" % active_event_elites.size())
	if active_event_elites.is_empty():
		print("Portal event completed: all elites defeated.")
		portal_event_completed.emit()

func _pick_portal_event_id() -> String:
	var events := ["double_elite", "power_for_hp_loss", "enemy_flood_20s"]
	return events[rng.randi_range(0, events.size() - 1)]
