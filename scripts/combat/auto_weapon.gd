extends Node2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")

@export var projectile_scene: PackedScene
@export var weapon_data: WeaponData
@export var fire_interval_seconds: float = 0.45
@export var target_range: float = 900.0

var owner_player: Node2D
var cooldown_left: float = 0.0
var set_bonus_manager: Node
var weapon_loadout: Node
var orbit_weapon_hud: Node
var current_rarity: String = "common"
var slot_cooldowns: Array[float] = []

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
const WEAPON_PROJECTILE_TEXTURE_PATHS: Dictionary = {
	"scrap_pistol": "res://assets/sprites/projectiles/harvester/harvester_projectile_03.png",
	"bone_knife": "res://assets/sprites/projectiles/harvester/harvester_projectile_02.png",
	"heart_collector": "res://assets/sprites/projectiles/harvester/harvester_projectile_01.png",
	"rusted_smg": "res://assets/sprites/projectiles/harvester/harvester_projectile_06.png",
	"grave_rifle": "res://assets/sprites/projectiles/harvester/harvester_projectile_05.png",
	"butcher_tool": "res://assets/sprites/projectiles/harvester/harvester_projectile_04.png"
}
const WEAPON_PROJECTILE_SCALE: Dictionary = {
	"scrap_pistol": Vector2(0.06, 0.06),
	"bone_knife": Vector2(0.055, 0.055),
	"heart_collector": Vector2(0.07, 0.07),
	"rusted_smg": Vector2(0.055, 0.055),
	"grave_rifle": Vector2(0.062, 0.062),
	"butcher_tool": Vector2(0.065, 0.065)
}
const WEAPON_PROJECTILE_TRAIL_COLORS: Dictionary = {
	"scrap_pistol": Color(1.0, 0.45, 0.65, 0.9),
	"bone_knife": Color(0.95, 0.35, 0.55, 0.9),
	"heart_collector": Color(1.0, 0.25, 0.45, 0.9),
	"rusted_smg": Color(1.0, 0.5, 0.72, 0.9),
	"grave_rifle": Color(0.9, 0.4, 0.95, 0.9),
	"butcher_tool": Color(1.0, 0.3, 0.38, 0.9)
}

func _ready() -> void:
	owner_player = get_parent() as Node2D
	if owner_player != null:
		weapon_loadout = owner_player.get_node_or_null("WeaponLoadout")
	orbit_weapon_hud = get_tree().current_scene.get_node_or_null("WeaponOrbitHUD")
	_apply_weapon_data()
	set_bonus_manager = owner_player.get_node_or_null("SetBonusManager")

func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
	if set_bonus_manager != null and set_bonus_manager.has_method("evaluate_and_debug_print"):
		set_bonus_manager.call("evaluate_and_debug_print")
	_tick_slot_cooldowns(delta)
	var entries := _get_weapon_entries()
	if entries.is_empty():
		_process_fallback_weapon(delta)
		return
	_ensure_slot_cooldowns_size(entries.size())
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var weapon_id := str(entry.get("id", ""))
		var rarity := str(entry.get("rarity", "common"))
		var entry_data := _load_weapon_data(weapon_id)
		if entry_data == null:
			continue
		var weapon_range := _get_weapon_range(entry_data)
		var muzzle_position := _get_slot_muzzle_position(index)
		var target := _find_nearest_enemy_for_origin(muzzle_position, weapon_range)
		var aim_direction := _get_slot_aim_direction(index)
		if target != null:
			aim_direction = (target.global_position - muzzle_position).normalized()
			_set_slot_aim_direction(index, aim_direction)
		if slot_cooldowns[index] > 0.0:
			continue
		if aim_direction.length_squared() <= 0.0001:
			continue
		var execution_shot := _should_use_execution_shot()
		if execution_shot:
			var strongest_target := _find_strongest_enemy()
			if strongest_target != null:
				target = strongest_target
				aim_direction = (target.global_position - muzzle_position).normalized()
				_set_slot_aim_direction(index, aim_direction)
		if target == null:
			continue
		var fire_direction := _get_slot_fire_direction(index, aim_direction)
		var fire_spawn_position := _get_slot_muzzle_position(index)
		var projectile_rotation_offset := _get_slot_projectile_rotation_offset(index)
		_fire_at_with_data(target, execution_shot, entry_data, rarity, fire_spawn_position, fire_direction, projectile_rotation_offset)
		slot_cooldowns[index] = _get_effective_cooldown(entry_data, rarity)

func _process_fallback_weapon(delta: float) -> void:
	cooldown_left = maxf(cooldown_left - delta, 0.0)
	if cooldown_left > 0.0:
		return
	if projectile_scene == null:
		return
	if weapon_data == null:
		return
	var target := _find_nearest_enemy(target_range)
	if target == null:
		return
	var execution_shot := _should_use_execution_shot()
	if execution_shot:
		var strongest_target := _find_strongest_enemy()
		if strongest_target != null:
			target = strongest_target
	var fallback_direction := (target.global_position - owner_player.global_position).normalized()
	_fire_at_with_data(target, execution_shot, weapon_data, current_rarity, owner_player.global_position, fallback_direction, _get_slot_projectile_rotation_offset(-1))
	cooldown_left = _get_effective_cooldown(weapon_data, current_rarity)

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

func _find_nearest_enemy(search_range: float) -> Node2D:
	return _find_nearest_enemy_for_origin(owner_player.global_position, search_range)

func _find_nearest_enemy_for_origin(origin: Vector2, search_range: float) -> Node2D:
	var nearest_enemy: Node2D
	var nearest_distance_sq := search_range * search_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy is Node2D and is_instance_valid(enemy):
			var enemy_node := enemy as Node2D
			var distance_sq := origin.distance_squared_to(enemy_node.global_position)
			if distance_sq < nearest_distance_sq:
				nearest_distance_sq = distance_sq
				nearest_enemy = enemy_node
	return nearest_enemy

func _fire_at_with_data(_target: Node2D, execution_shot: bool, entry_data: WeaponData, rarity: String, spawn_position: Vector2, aim_direction: Vector2, projectile_rotation_offset: float) -> void:
	var resolved_projectile_scene := _resolve_projectile_scene(entry_data)
	if resolved_projectile_scene == null:
		return
	var rarity_damage_multiplier := float(RARITY_DAMAGE_MULTIPLIER.get(rarity, 1.0))
	var rarity_speed_multiplier := float(RARITY_SPEED_MULTIPLIER.get(rarity, 1.0))
	var projectile := ProjectileSpawnUtil.spawn_projectile(
		resolved_projectile_scene,
		get_tree().current_scene,
		spawn_position,
		aim_direction,
		_get_weapon_damage(entry_data) * rarity_damage_multiplier,
		_get_weapon_projectile_speed(entry_data) * rarity_speed_multiplier,
		_get_weapon_lifetime(entry_data),
		projectile_rotation_offset
	)
	if projectile == null:
		return
	_apply_projectile_visual(projectile, entry_data.id)
	if projectile.has_method("set_shooter"):
		projectile.call("set_shooter", owner_player)
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

func _apply_projectile_visual(projectile: Node, weapon_id: String) -> void:
	if weapon_id == "":
		return
	var texture_path := str(WEAPON_PROJECTILE_TEXTURE_PATHS.get(weapon_id, ""))
	if texture_path == "":
		return
	if not ResourceLoader.exists(texture_path):
		return
	var visual := projectile.get_node_or_null("Visual")
	if not (visual is Sprite2D):
		return
	var projectile_sprite := visual as Sprite2D
	var texture_resource := load(texture_path)
	if texture_resource is Texture2D:
		projectile_sprite.texture = texture_resource
	var desired_scale_variant: Variant = WEAPON_PROJECTILE_SCALE.get(weapon_id, Vector2(0.055, 0.055))
	if desired_scale_variant is Vector2:
		projectile_sprite.scale = desired_scale_variant
	var trail_color_variant: Variant = WEAPON_PROJECTILE_TRAIL_COLORS.get(weapon_id, Color(1.0, 0.35, 0.55, 0.9))
	if trail_color_variant is Color:
		projectile.set("trail_color", trail_color_variant)

func _get_slot_muzzle_position(slot_index: int) -> Vector2:
	var fire_direction := _get_slot_fire_direction(slot_index, _get_slot_aim_direction(slot_index))
	if orbit_weapon_hud != null and orbit_weapon_hud.has_method("get_slot_muzzle_world_position"):
		var position_variant: Variant = orbit_weapon_hud.call("get_slot_muzzle_world_position", slot_index)
		if position_variant is Vector2:
			return (position_variant as Vector2) + (fire_direction * 12.0)
	return owner_player.global_position + (fire_direction * 12.0)

func _set_slot_aim_direction(slot_index: int, direction: Vector2) -> void:
	if orbit_weapon_hud != null and orbit_weapon_hud.has_method("set_slot_aim_direction"):
		orbit_weapon_hud.call("set_slot_aim_direction", slot_index, direction)

func _get_slot_aim_direction(slot_index: int) -> Vector2:
	if orbit_weapon_hud != null and orbit_weapon_hud.has_method("get_slot_aim_direction"):
		var direction_variant: Variant = orbit_weapon_hud.call("get_slot_aim_direction", slot_index)
		if direction_variant is Vector2:
			return direction_variant
	return Vector2.RIGHT

func _get_slot_fire_direction(slot_index: int, fallback_direction: Vector2) -> Vector2:
	if orbit_weapon_hud != null and orbit_weapon_hud.has_method("get_slot_fire_direction"):
		var direction_variant: Variant = orbit_weapon_hud.call("get_slot_fire_direction", slot_index)
		if direction_variant is Vector2:
			var direction := direction_variant as Vector2
			if direction.length_squared() > 0.0001:
				return direction.normalized()
	if fallback_direction.length_squared() > 0.0001:
		return fallback_direction.normalized()
	return Vector2.RIGHT

func _get_slot_projectile_rotation_offset(slot_index: int) -> float:
	if orbit_weapon_hud != null and orbit_weapon_hud.has_method("get_slot_projectile_rotation_offset"):
		var offset_variant: Variant = orbit_weapon_hud.call("get_slot_projectile_rotation_offset", slot_index)
		return float(offset_variant)
	return 0.0

func _resolve_projectile_scene(entry_data: WeaponData) -> PackedScene:
	if entry_data != null and entry_data.projectile_scene_path != "":
		var projectile_resource: Resource = load(entry_data.projectile_scene_path)
		if projectile_resource is PackedScene:
			return projectile_resource as PackedScene
	return projectile_scene

func _get_weapon_damage(entry_data: WeaponData) -> float:
	if entry_data.damage > 0.0:
		return entry_data.damage
	return entry_data.base_damage

func _get_weapon_projectile_speed(entry_data: WeaponData) -> float:
	if entry_data.projectile_speed > 0.0:
		return entry_data.projectile_speed
	return 700.0

func _get_weapon_lifetime(entry_data: WeaponData) -> float:
	if entry_data.projectile_lifetime_seconds > 0.0:
		return entry_data.projectile_lifetime_seconds
	return 2.0

func _get_weapon_range(entry_data: WeaponData) -> float:
	var range_multiplier := entry_data.attack_range
	if range_multiplier <= 0.0:
		range_multiplier = entry_data.range
	if range_multiplier <= 0.0:
		range_multiplier = 1.0
	return 900.0 * range_multiplier

func _get_effective_cooldown(entry_data: WeaponData, rarity: String) -> float:
	var base_cooldown := entry_data.cooldown_seconds
	if base_cooldown <= 0.0:
		base_cooldown = entry_data.cooldown
	if base_cooldown <= 0.0:
		base_cooldown = 0.6
	var rarity_speed_multiplier := float(RARITY_SPEED_MULTIPLIER.get(rarity, 1.0))
	return base_cooldown / rarity_speed_multiplier

func _tick_slot_cooldowns(delta: float) -> void:
	for index in range(slot_cooldowns.size()):
		slot_cooldowns[index] = maxf(slot_cooldowns[index] - delta, 0.0)

func _ensure_slot_cooldowns_size(size: int) -> void:
	if size < 0:
		size = 0
	if slot_cooldowns.size() == size:
		return
	if slot_cooldowns.size() > size:
		slot_cooldowns.resize(size)
		return
	while slot_cooldowns.size() < size:
		slot_cooldowns.append(0.0)

func _get_weapon_entries() -> Array[Dictionary]:
	if weapon_loadout == null or not weapon_loadout.has_method("get_weapon_entries"):
		return []
	var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
	if not (entries_variant is Array):
		return []
	var normalized_entries: Array[Dictionary] = []
	for entry_variant in entries_variant:
		if entry_variant is Dictionary:
			normalized_entries.append((entry_variant as Dictionary).duplicate(true))
	return normalized_entries

func _load_weapon_data(weapon_id: String) -> WeaponData:
	if weapon_id == "":
		return null
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as WeaponData

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
