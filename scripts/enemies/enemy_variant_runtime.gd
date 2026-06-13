class_name EnemyVariantRuntime
extends RefCounted

const IMP_RUNNER_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_brute.png")
const HUSK_BRUTE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/final_boss_shadow_assassin.png")
const SPIT_FIEND_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/hell_lantern_mage.png")
const SKELETON_RIFLEMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/skeleton_marshal.png")
const ARCHMAGE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_archmage.png")
const MARKSMAN_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/demon_marksman.png")
const SKULL_FIREBALL_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/skull_fireball.png")
const RIFT_SHARD_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemies/hell_arcane_shot.png")

const FALLBACK_VARIANT_STATS: Dictionary = {
	"imp_runner": {
		"move_speed": 190.0,
		"max_hp": 16.0,
		"contact_damage": 5.0,
		"damage_interval_seconds": 0.65,
		"visual_scale": Vector2(0.085, 0.085),
	},
	"husk_brute": {
		"move_speed": 95.0,
		"max_hp": 40.0,
		"contact_damage": 10.0,
		"damage_interval_seconds": 1.0,
		"visual_scale": Vector2(0.1, 0.1),
	},
	"spit_fiend": {
		"move_speed": 120.0,
		"max_hp": 24.0,
		"contact_damage": 3.0,
		"damage_interval_seconds": 1.2,
		"ranged_damage": 4.0,
		"ranged_interval_seconds": 1.1,
		"ranged_attack_range": 230.0,
		"visual_scale": Vector2(0.09, 0.09),
	},
	"skeleton_rifleman": {
		"move_speed": 130.0,
		"max_hp": 28.0,
		"contact_damage": 2.0,
		"damage_interval_seconds": 1.25,
		"ranged_damage": 6.0,
		"ranged_interval_seconds": 1.35,
		"ranged_attack_range": 290.0,
		"visual_scale": Vector2(0.09, 0.09),
	},
}

static func apply_enemy_data(owner: Node, data: EnemyData, visual_sprite: Sprite2D, texture_loader: Callable) -> void:
	owner.max_hp = data.max_hp
	owner.move_speed = data.move_speed
	owner.contact_damage = data.contact_damage
	owner.contact_range = data.contact_range
	owner.damage_interval_seconds = data.damage_interval_seconds
	owner.ranged_damage = data.ranged_damage
	owner.ranged_interval_seconds = data.ranged_interval_seconds
	owner.ranged_attack_range = data.ranged_attack_range
	owner.is_elite = data.is_elite
	owner.is_boss = data.is_boss
	owner.reward_gold = data.reward_gold
	owner.reward_xp = data.reward_xp
	if visual_sprite != null and data.visual_texture_path != "" and ResourceLoader.exists(data.visual_texture_path):
		visual_sprite.texture = texture_loader.call(data.visual_texture_path)
		visual_sprite.scale = Vector2.ONE * data.visual_scale

static func apply_fallback_variant(
	owner: Node,
	variant_id: String,
	elite_role: String,
	visual: CanvasItem,
	visual_sprite: Sprite2D
) -> void:
	var stats_variant: Variant = FALLBACK_VARIANT_STATS.get(variant_id, {})
	if not (stats_variant is Dictionary):
		return
	var stats: Dictionary = stats_variant
	owner.move_speed = float(stats.get("move_speed", owner.move_speed))
	owner.max_hp = float(stats.get("max_hp", owner.max_hp))
	owner.contact_damage = float(stats.get("contact_damage", owner.contact_damage))
	owner.damage_interval_seconds = float(stats.get("damage_interval_seconds", owner.damage_interval_seconds))
	owner.ranged_damage = float(stats.get("ranged_damage", owner.ranged_damage))
	owner.ranged_interval_seconds = float(stats.get("ranged_interval_seconds", owner.ranged_interval_seconds))
	owner.ranged_attack_range = float(stats.get("ranged_attack_range", owner.ranged_attack_range))
	if visual != null:
		visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if visual_sprite != null:
		visual_sprite.texture = _resolve_visual_texture(variant_id, elite_role)
		visual_sprite.scale = stats.get("visual_scale", visual_sprite.scale)

static func resolve_movement_velocity(
	variant_id: String,
	move_speed: float,
	ranged_attack_range: float,
	current_position: Vector2,
	target_position: Vector2
) -> Vector2:
	var direction := (target_position - current_position).normalized()
	var velocity := direction * move_speed
	if variant_id == "spit_fiend":
		var distance_to_player := current_position.distance_to(target_position)
		if distance_to_player <= ranged_attack_range:
			velocity *= 0.25
	elif variant_id == "skeleton_rifleman":
		var skeleton_distance := current_position.distance_to(target_position)
		var keep_distance_min := ranged_attack_range * 0.58
		var keep_distance_max := ranged_attack_range * 0.92
		if skeleton_distance < keep_distance_min:
			velocity = -direction * move_speed
		elif skeleton_distance <= keep_distance_max:
			velocity = Vector2.ZERO
	return velocity

static func supports_ranged_attack(variant_id: String) -> bool:
	return variant_id == "spit_fiend" or variant_id == "skeleton_rifleman"

static func resolve_projectile_speed(variant_id: String, elite_role: String) -> float:
	if variant_id == "skeleton_rifleman":
		return 560.0
	if elite_role == "rift_caller":
		return 300.0
	return 390.0

static func resolve_projectile_lifetime(variant_id: String, elite_role: String) -> float:
	if variant_id == "skeleton_rifleman":
		return 1.7
	if elite_role == "rift_caller":
		return 2.3
	return 1.9

static func resolve_projectile_texture(
	data: EnemyData,
	variant_id: String,
	elite_role: String,
	texture_loader: Callable
) -> Texture2D:
	if data != null and data.projectile_texture_path != "" and ResourceLoader.exists(data.projectile_texture_path):
		return texture_loader.call(data.projectile_texture_path)
	if variant_id == "skeleton_rifleman" or elite_role == "rift_caller":
		return RIFT_SHARD_TEXTURE
	return SKULL_FIREBALL_TEXTURE

static func resolve_projectile_rotation_offset(data: EnemyData) -> float:
	if data != null:
		return data.projectile_rotation_offset
	return PI

static func _resolve_visual_texture(variant_id: String, elite_role: String) -> Texture2D:
	match variant_id:
		"imp_runner":
			return IMP_RUNNER_TEXTURE
		"husk_brute":
			return HUSK_BRUTE_TEXTURE
		"spit_fiend":
			if elite_role == "rift_caller":
				return ARCHMAGE_TEXTURE
			return SPIT_FIEND_TEXTURE
		"skeleton_rifleman":
			if elite_role == "marksman":
				return MARKSMAN_TEXTURE
			return SKELETON_RIFLEMAN_TEXTURE
	return null
