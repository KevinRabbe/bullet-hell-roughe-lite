extends Node2D

@export var projectile_scene: PackedScene
@export var fire_interval_seconds: float = 0.45
@export var target_range: float = 900.0

var owner_player: Node2D
var cooldown_left: float = 0.0

func _ready() -> void:
	owner_player = get_parent() as Node2D
	_apply_weapon_data()

func _physics_process(delta: float) -> void:
	cooldown_left -= delta
	if cooldown_left > 0.0:
		return
	if projectile_scene == null:
		return
	if owner_player == null or not is_instance_valid(owner_player):
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	_fire_at(target)
	cooldown_left = fire_interval_seconds

func set_weapon_data(new_weapon_data: WeaponData) -> void:
	if new_weapon_data == null:
		return
	weapon_data = new_weapon_data
	_apply_weapon_data()
	print("AutoWeapon switched to: %s" % weapon_data.display_name)

func _apply_weapon_data() -> void:
	if weapon_data == null:
		return
	fire_interval_seconds = weapon_data.cooldown_seconds
	target_range = 900.0 * weapon_data.attack_range

func _find_nearest_enemy() -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance_sq := target_range * target_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and is_instance_valid(enemy):
			var enemy_node := enemy as Node2D
			var distance_sq := owner_player.global_position.distance_squared_to(enemy_node.global_position)
			if distance_sq < nearest_distance_sq:
				nearest_distance_sq = distance_sq
				nearest_enemy = enemy_node
	return nearest_enemy

func _fire_at(target: Node2D) -> void:
	var projectile_instance := projectile_scene.instantiate()
	if projectile_instance is Node2D:
		var projectile := projectile_instance as Node2D
		projectile.global_position = owner_player.global_position
		if weapon_data != null:
			projectile.set("damage", weapon_data.damage)
			projectile.set("speed", weapon_data.projectile_speed)
			projectile.set("lifetime_seconds", weapon_data.projectile_lifetime_seconds)
		var direction := target.global_position - owner_player.global_position
		if projectile.has_method("set_direction"):
			projectile.call("set_direction", direction)
		get_tree().current_scene.add_child(projectile)
