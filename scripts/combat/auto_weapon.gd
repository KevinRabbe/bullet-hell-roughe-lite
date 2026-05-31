extends Node2D

@export var projectile_scene: PackedScene
@export var weapon_data: WeaponData
@export var fire_interval_seconds: float = 0.45
@export var target_range: float = 900.0

var owner_player: Node2D
var cooldown_left: float = 0.0
var set_bonus_manager: Node
var weapon_loadout: Node
var current_rarity: String = "common"

const RARITY_DAMAGE_MULTIPLIER: Dictionary = {
	"common": 1.0,
	"rare": 1.15,
	"epic": 1.35,
	"legendary": 1.6
}
const RARITY_SPEED_MULTIPLIER: Dictionary = {
	"common": 1.0,
	"rare": 1.05,
	"epic": 1.12,
	"legendary": 1.2
}

func _ready() -> void:
	owner_player = get_parent() as Node2D
	if owner_player != null:
		weapon_loadout = owner_player.get_node_or_null("WeaponLoadout")
	_apply_weapon_data()
	set_bonus_manager = owner_player.get_node_or_null("SetBonusManager")

func _physics_process(delta: float) -> void:
	cooldown_left -= delta
	if cooldown_left > 0.0:
		return
	if projectile_scene == null:
		return
	if owner_player == null or not is_instance_valid(owner_player):
		return
	if set_bonus_manager != null and set_bonus_manager.has_method("evaluate_and_debug_print"):
		set_bonus_manager.call("evaluate_and_debug_print")

	var target := _find_nearest_enemy()
	if target == null:
		return
	var execution_shot := _should_use_execution_shot()
	if execution_shot:
		var strongest_target := _find_strongest_enemy()
		if strongest_target != null:
			target = strongest_target

	_fire_at(target, execution_shot)
	cooldown_left = fire_interval_seconds

func set_weapon_data(new_weapon_data: WeaponData) -> void:
	if new_weapon_data == null:
		return
	weapon_data = new_weapon_data
	current_rarity = _resolve_weapon_rarity()
	_apply_weapon_data()
	print("AutoWeapon switched to: %s (%s)" % [weapon_data.display_name, current_rarity])
func _apply_weapon_data() -> void:
	if weapon_data == null:
		return
	current_rarity = _resolve_weapon_rarity()
	if weapon_data.projectile_scene_path != "":
		var projectile_resource: Resource = load(weapon_data.projectile_scene_path)
		if projectile_resource is PackedScene:
			projectile_scene = projectile_resource as PackedScene
	var rarity_speed_multiplier := float(RARITY_SPEED_MULTIPLIER.get(current_rarity, 1.0))
	fire_interval_seconds = weapon_data.cooldown_seconds / rarity_speed_multiplier
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

func _fire_at(target: Node2D, execution_shot: bool) -> void:
	var projectile_instance := projectile_scene.instantiate()
	if projectile_instance is Node2D:
		var projectile := projectile_instance as Node2D
		projectile.global_position = owner_player.global_position
		if projectile.has_method("set_shooter"):
			projectile.call("set_shooter", owner_player)
		if weapon_data != null:
			var rarity_damage_multiplier := float(RARITY_DAMAGE_MULTIPLIER.get(current_rarity, 1.0))
			var rarity_speed_multiplier := float(RARITY_SPEED_MULTIPLIER.get(current_rarity, 1.0))
			projectile.set("damage", weapon_data.damage * rarity_damage_multiplier)
			projectile.set("speed", weapon_data.projectile_speed * rarity_speed_multiplier)
			projectile.set("lifetime_seconds", weapon_data.projectile_lifetime_seconds)
		var total_damage_multiplier := 1.0
		if set_bonus_manager != null and set_bonus_manager.has_method("get_damage_multiplier_bonus"):
			total_damage_multiplier += float(set_bonus_manager.call("get_damage_multiplier_bonus"))
		if execution_shot and set_bonus_manager != null and set_bonus_manager.has_method("get_execution_damage_multiplier"):
			total_damage_multiplier *= float(set_bonus_manager.call("get_execution_damage_multiplier"))
			print("Set Bonus 6-piece: fired execution shot.")
		if projectile.has_method("set"):
			projectile.set("damage_multiplier", total_damage_multiplier)
			var can_pierce := set_bonus_manager != null and set_bonus_manager.has_method("can_pierce_shot") and bool(set_bonus_manager.call("can_pierce_shot"))
			projectile.set("pierce_count", 1 if can_pierce else 0)
			if can_pierce:
				print("Set Bonus 4-piece: pierce shot proc.")
		var direction := target.global_position - owner_player.global_position
		if projectile.has_method("set_direction"):
			projectile.call("set_direction", direction)
		get_tree().current_scene.add_child(projectile)

func _resolve_weapon_rarity() -> String:
	if weapon_data == null:
		return "common"
	if weapon_loadout != null and weapon_loadout.has_method("get_weapon_rarity"):
		return str(weapon_loadout.call("get_weapon_rarity", weapon_data.id))
	return "common"

func _should_use_execution_shot() -> bool:
	if set_bonus_manager == null:
		return false
	if not set_bonus_manager.has_method("should_fire_execution_shot"):
		return false
	return bool(set_bonus_manager.call("should_fire_execution_shot"))

func _find_strongest_enemy() -> Node2D:
	var strongest_enemy: Node2D
	var strongest_hp := -INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and is_instance_valid(enemy):
			var enemy_hp := float(enemy.get("current_hp"))
			if enemy_hp > strongest_hp:
				strongest_hp = enemy_hp
				strongest_enemy = enemy
	return strongest_enemy
