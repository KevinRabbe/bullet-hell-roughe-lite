class_name EnemyCombatRuntime
extends RefCounted

const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")
const EnemyVariantRuntimeUtil = preload("res://scripts/enemies/enemy_variant_runtime.gd")

static func resolve_player_target(current_target: Node2D, tree: SceneTree) -> Node2D:
	if current_target != null and is_instance_valid(current_target):
		return current_target
	var players := tree.get_nodes_in_group("players")
	if players.is_empty():
		return null
	if players[0] is Node2D:
		return players[0] as Node2D
	return null

static func try_damage_player(
	owner: Node2D,
	target: Node2D,
	enemy_variant: String,
	damage_cooldown_left: float,
	contact_range: float,
	contact_damage: float,
	damage_interval_seconds: float,
	log_combat_events: bool
) -> float:
	if enemy_variant == "spit_fiend":
		return damage_cooldown_left
	if damage_cooldown_left > 0.0:
		return damage_cooldown_left
	if target == null or not is_instance_valid(target):
		return damage_cooldown_left
	if not target.has_method("take_damage"):
		return damage_cooldown_left

	var distance_to_player := owner.global_position.distance_to(target.global_position)
	if distance_to_player > contact_range:
		return damage_cooldown_left

	if log_combat_events:
		print("ENEMY HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, contact_damage])
	target.call("take_damage", contact_damage)
	if target.has_method("notify_damaged_by_enemy"):
		target.call("notify_damaged_by_enemy", owner)
	return damage_interval_seconds

static func try_ranged_damage_player(
	owner: Node2D,
	target: Node2D,
	enemy_variant: String,
	elite_role: String,
	ranged_cooldown_left: float,
	ranged_attack_range: float,
	ranged_damage: float,
	ranged_interval_seconds: float,
	enemy_projectile_scene: PackedScene,
	enemy_data: EnemyData,
	texture_loader: Callable,
	log_combat_events: bool
) -> float:
	if not EnemyVariantRuntimeUtil.supports_ranged_attack(enemy_variant):
		return ranged_cooldown_left
	if ranged_cooldown_left > 0.0:
		return ranged_cooldown_left
	if target == null or not is_instance_valid(target):
		return ranged_cooldown_left
	if not target.has_method("take_damage"):
		return ranged_cooldown_left

	var distance_to_player := owner.global_position.distance_to(target.global_position)
	if distance_to_player > ranged_attack_range:
		return ranged_cooldown_left

	var projectile_speed := EnemyVariantRuntimeUtil.resolve_projectile_speed(enemy_variant, elite_role)
	var projectile_lifetime := EnemyVariantRuntimeUtil.resolve_projectile_lifetime(enemy_variant, elite_role)
	var projectile := ProjectileSpawnUtil.spawn_projectile(
		enemy_projectile_scene,
		owner.get_tree().current_scene,
		owner.global_position,
		target.global_position - owner.global_position,
		ranged_damage,
		projectile_speed,
		projectile_lifetime,
		PI
	)
	if projectile != null:
		if projectile.has_method("set_source_enemy"):
			projectile.call("set_source_enemy", owner)
		var projectile_visual := projectile.get_node_or_null("Visual")
		if projectile_visual is Sprite2D:
			var projectile_sprite := projectile_visual as Sprite2D
			projectile_sprite.texture = EnemyVariantRuntimeUtil.resolve_projectile_texture(
				enemy_data,
				enemy_variant,
				elite_role,
				texture_loader
			)
			projectile_sprite.rotation = (
				target.global_position - owner.global_position
			).angle() + EnemyVariantRuntimeUtil.resolve_projectile_rotation_offset(enemy_data)
	if log_combat_events:
		print("%s SHOT PROJECTILE | distance %.1f | damage %.1f" % [enemy_variant.to_upper(), distance_to_player, ranged_damage])
	return ranged_interval_seconds
