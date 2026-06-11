class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var projectile_texture: Texture2D

@export var family: String = ""
@export var tags: Array[String] = []
@export_enum("common", "rare", "epic", "legendary") var rarity: String = "common"

@export var damage_type: String = ""
@export var base_damage: float = 10.0
@export var cooldown: float = 0.6
@export var attack_speed: float = 1.0
@warning_ignore("shadowed_global_identifier")
@export var range: float = 1.0
@export var projectile_speed: float = 700.0
@export var projectile_lifetime: float = 2.0
@export var pierce: int = 0
@export var knockback: float = 0.0

@export var price: int = 0

@export var stat_scaling: Dictionary = {}

@export var special_effect_id: String = ""
@export var shop_enabled: bool = true
@export var on_hit_status_id: String = ""
@export var on_hit_status_duration: float = 0.0
@export var on_hit_status_tick_interval: float = 0.0
@export var on_hit_status_flat_damage: float = 0.0
@export var on_hit_status_max_hp_fraction: float = 0.0
@export var on_hit_status_max_stacks: int = 1
@export var on_hit_status_power_stat_id: String = ""
@export var bonus_damage_vs_status_id: String = ""
@export var bonus_damage_vs_status_multiplier: float = 1.0
@export var bonus_damage_vs_status_max_hp_fraction: float = 0.0
@export var bonus_damage_per_enemy_with_status_id: String = ""
@export var bonus_damage_per_enemy_with_status_amount: float = 0.0
@export var bonus_damage_per_enemy_with_status_max_enemies: int = 0
@export var bonus_damage_per_player_stat_id: String = ""
@export var bonus_damage_per_player_stat_amount: float = 0.0
@export var bonus_damage_per_player_stat_max_value: float = 0.0

# Legacy compatibility fields preserved for migrated resources.
@export var family_id: String = ""
@export var cooldown_seconds: float = 0.0
@export var damage: float = 0.0
@export var attack_range: float = 0.0
@export var projectile_lifetime_seconds: float = 0.0
@export var projectile_scene_path: String = ""

# Visual/orbit calibration fields (Stage 11 stabilization)
@export var orbit_radius_multiplier: float = 1.0
@export var orbit_scale_multiplier: float = 1.0
@export var aim_forward_sign: float = 1.0
@export var projectile_rotation_offset: float = 0.0
@export var kill_milestone_base_kills: int = 0
@export var kill_milestone_stat_id: String = ""
@export var kill_milestone_amount: float = 0.0
@export_enum("player", "weapon") var kill_milestone_scope: String = "player"

func get_family_value() -> String:
	if family != "":
		return family
	return family_id

func get_damage_value() -> float:
	if base_damage > 0.0:
		return base_damage
	if damage > 0.0:
		return damage
	return 0.0

func get_cooldown_value() -> float:
	if cooldown > 0.0:
		return cooldown
	if cooldown_seconds > 0.0:
		return cooldown_seconds
	return 0.0

func get_attack_range_value() -> float:
	if range > 0.0:
		return range
	if attack_range > 0.0:
		return attack_range
	return 0.0

func get_projectile_lifetime_value() -> float:
	if projectile_lifetime > 0.0:
		return projectile_lifetime
	if projectile_lifetime_seconds > 0.0:
		return projectile_lifetime_seconds
	return 2.0

func get_projectile_scene_path_value() -> String:
	return projectile_scene_path
