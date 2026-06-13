extends Node2D

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")

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
var _weapon_data_cache: Dictionary = {}
var _projectile_scene_cache: Dictionary = {}

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
	orbit_weapon_hud = get_tree().current_scene.get_node_or_null("WeaponOrbitHUD")
	_apply_weapon_data()
	set_bonus_manager = owner_player.get_node_or_null("SetBonusManager")

func _physics_process(delta: float) -> void:
	if owner_player == null or not is_instance_valid(owner_player):
		return
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
		var weapon_bonus_overrides := _get_entry_weapon_bonus_overrides(entry)
		var weapon_range := _get_weapon_range(entry_data)
		weapon_range += float(weapon_bonus_overrides.get("attack_range", 0.0)) * 900.0
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
		_fire_at_with_data(target, execution_shot, entry_data, rarity, fire_spawn_position, fire_direction, projectile_rotation_offset, weapon_id, index, weapon_bonus_overrides)
		slot_cooldowns[index] = _get_effective_cooldown(entry_data, rarity, weapon_bonus_overrides)

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
	_fire_at_with_data(target, execution_shot, weapon_data, current_rarity, owner_player.global_position, fallback_direction, _get_slot_projectile_rotation_offset(-1), weapon_data.id, -1)
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
	var projectile_scene_path := weapon_data.get_projectile_scene_path_value() if weapon_data.has_method("get_projectile_scene_path_value") else weapon_data.projectile_scene_path
	if projectile_scene_path != "":
		var projectile_resource: Resource = _projectile_scene_cache.get(projectile_scene_path)
		if projectile_resource == null:
			projectile_resource = load(projectile_scene_path)
			if projectile_resource != null:
				_projectile_scene_cache[projectile_scene_path] = projectile_resource
		if projectile_resource is PackedScene:
			projectile_scene = projectile_resource as PackedScene
	fire_interval_seconds = _get_effective_cooldown(weapon_data, current_rarity)
	target_range = _get_weapon_range(weapon_data)

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

func _fire_at_with_data(_target: Node2D, execution_shot: bool, entry_data: WeaponData, rarity: String, spawn_position: Vector2, aim_direction: Vector2, projectile_rotation_offset: float, weapon_id: String, slot_index: int, weapon_bonus_overrides: Dictionary = {}) -> void:
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
		_get_weapon_damage(entry_data, weapon_bonus_overrides) * rarity_damage_multiplier * _get_player_damage_multiplier(),
		_get_weapon_projectile_speed(entry_data, weapon_bonus_overrides) * rarity_speed_multiplier * _get_player_projectile_speed_multiplier(),
		_get_weapon_lifetime(entry_data),
		projectile_rotation_offset
	)
	if projectile == null:
		return
	if entry_data.projectile_texture != null and projectile.has_method("set_visual_texture"):
		projectile.call("set_visual_texture", entry_data.projectile_texture)
	if projectile.has_method("set_source_weapon_data"):
		projectile.call("set_source_weapon_data", entry_data)
	if projectile.has_method("set_shooter"):
		projectile.call("set_shooter", owner_player)
	if projectile.has_method("set_source_context"):
		projectile.call("set_source_context", weapon_id, slot_index)
	var total_damage_multiplier := 1.0
	if set_bonus_manager != null and set_bonus_manager.has_method("get_damage_multiplier_bonus"):
		total_damage_multiplier += float(set_bonus_manager.call("get_damage_multiplier_bonus"))
	if execution_shot and set_bonus_manager != null and set_bonus_manager.has_method("get_execution_damage_multiplier"):
		total_damage_multiplier *= float(set_bonus_manager.call("get_execution_damage_multiplier"))
		if _should_log_set_bonus_events():
			print("Set Bonus 6-piece: fired execution shot.")
	if projectile.has_method("set"):
		projectile.set("damage_multiplier", total_damage_multiplier)
		var can_pierce: bool = set_bonus_manager != null and set_bonus_manager.has_method("can_pierce_shot") and set_bonus_manager.call("can_pierce_shot") == true
		projectile.set("pierce_count", 1 if can_pierce else 0)
		if can_pierce:
			if _should_log_set_bonus_events():
				print("Set Bonus 4-piece: pierce shot proc.")

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
	var projectile_scene_path := ""
	if entry_data != null:
		projectile_scene_path = entry_data.get_projectile_scene_path_value() if entry_data.has_method("get_projectile_scene_path_value") else entry_data.projectile_scene_path
	if projectile_scene_path != "":
		var projectile_resource: Resource = _projectile_scene_cache.get(projectile_scene_path)
		if projectile_resource == null:
			projectile_resource = load(projectile_scene_path)
			if projectile_resource != null:
				_projectile_scene_cache[projectile_scene_path] = projectile_resource
		if projectile_resource is PackedScene:
			return projectile_resource as PackedScene
	return projectile_scene

func _get_weapon_damage(entry_data: WeaponData, weapon_bonus_overrides: Dictionary = {}) -> float:
	if entry_data == null:
		return float(weapon_bonus_overrides.get("damage", 0.0))
	var base_damage := entry_data.get_damage_value() if entry_data.has_method("get_damage_value") else entry_data.base_damage
	return base_damage + float(weapon_bonus_overrides.get("damage", 0.0))

func _get_weapon_projectile_speed(entry_data: WeaponData, weapon_bonus_overrides: Dictionary = {}) -> float:
	if entry_data.projectile_speed > 0.0:
		return entry_data.projectile_speed + float(weapon_bonus_overrides.get("projectile_speed", 0.0))
	return 700.0 + float(weapon_bonus_overrides.get("projectile_speed", 0.0))

func _get_weapon_lifetime(entry_data: WeaponData) -> float:
	if entry_data != null and entry_data.has_method("get_projectile_lifetime_value"):
		return entry_data.get_projectile_lifetime_value()
	return 2.0

func _get_weapon_range(entry_data: WeaponData) -> float:
	var range_multiplier := entry_data.get_attack_range_value() if entry_data != null and entry_data.has_method("get_attack_range_value") else 1.0
	if range_multiplier <= 0.0:
		range_multiplier = 1.0
	return 900.0 * range_multiplier * _get_player_attack_range_multiplier()

func _get_effective_cooldown(entry_data: WeaponData, rarity: String, weapon_bonus_overrides: Dictionary = {}) -> float:
	var base_cooldown := entry_data.get_cooldown_value() if entry_data != null and entry_data.has_method("get_cooldown_value") else 0.6
	if base_cooldown <= 0.0:
		base_cooldown = 0.6
	var rarity_speed_multiplier := float(RARITY_SPEED_MULTIPLIER.get(rarity, 1.0))
	var weapon_attack_speed_multiplier := maxf(1.0 + float(weapon_bonus_overrides.get("attack_speed", 0.0)), 0.01)
	var player_attack_speed_multiplier := maxf(_get_player_attack_speed_multiplier(), 0.01)
	return base_cooldown / (rarity_speed_multiplier * player_attack_speed_multiplier * weapon_attack_speed_multiplier)

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

func _get_entry_weapon_bonus_overrides(entry: Dictionary) -> Dictionary:
	var overrides_variant: Variant = entry.get("weapon_bonus_overrides", {})
	if overrides_variant is Dictionary:
		return (overrides_variant as Dictionary).duplicate(true)
	return {}

func _load_weapon_data(weapon_id: String) -> WeaponData:
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, weapon_id)

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
	return set_bonus_manager.call("should_fire_execution_shot") == true

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

func _should_log_set_bonus_events() -> bool:
	if set_bonus_manager == null:
		return false
	return set_bonus_manager.get("log_set_bonus_changes") == true

func _get_player_damage_multiplier() -> float:
	if owner_player != null and owner_player.has_method("get_damage_stat_multiplier"):
		return maxf(float(owner_player.call("get_damage_stat_multiplier")), 0.0)
	return 1.0

func _get_player_attack_speed_multiplier() -> float:
	if owner_player != null and owner_player.has_method("get_attack_speed_multiplier"):
		return maxf(float(owner_player.call("get_attack_speed_multiplier")), 0.01)
	return 1.0

func _get_player_attack_range_multiplier() -> float:
	if owner_player != null and owner_player.has_method("get_attack_range_multiplier"):
		return maxf(float(owner_player.call("get_attack_range_multiplier")), 0.01)
	return 1.0

func _get_player_projectile_speed_multiplier() -> float:
	if owner_player != null and owner_player.has_method("get_projectile_speed_multiplier"):
		return maxf(float(owner_player.call("get_projectile_speed_multiplier")), 0.01)
	return 1.0
