class_name WeaponData
extends Resource

const ATTACK_MOTION_PROFILES: Array[String] = [
	"auto",
	"recoil",
	"thrust",
	"slash_arc",
	"spin_throw",
	"charge_release",
	"pulse_cast",
	"deploy"
]

const WEAPON_CLASSES: Array[String] = [
	"firearm",
	"blade",
	"thrown",
	"bow",
	"launcher",
	"focus",
	"relic",
	"claw"
]

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_multiline var signature_attack_summary: String = ""
@export_enum("auto", "recoil", "thrust", "slash_arc", "spin_throw", "charge_release", "pulse_cast", "deploy") var attack_motion_profile: String = "auto"
@export var icon: Texture2D
@export var projectile_texture: Texture2D

# Neutral physical/functional categories. A weapon may belong to more than one
# class (for example, a chakram can be both Blade and Thrown). Classes describe
# what a weapon is; attack_pattern describes how it attacks; tags describe
# mechanical/thematic synergy.
@export var classes: Array[String] = []
@export var tags: Array[String] = []
@export_enum("common", "rare", "epic", "legendary") var rarity: String = "common"

# Transitional only while existing resources/UI are migrated. Do not author new
# content against family/family_id; both fields are removed after the resource
# migration is complete.
@export var family: String = ""

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

# Canonical attack-pattern contract. These fields turn weapon identity into
# shared combat behavior instead of requiring one script per weapon.
@export_enum("projectile", "spread", "melee_arc", "mine", "wave", "orbit", "returning") var attack_pattern: String = "projectile"
@export_range(1, 7, 1) var projectiles_per_attack: int = 1
@export_range(0.0, 90.0, 1.0) var spread_degrees: float = 0.0
@export_range(0.05, 2.0, 0.05) var per_projectile_damage_multiplier: float = 1.0
@export_range(2.0, 64.0, 1.0) var projectile_hit_radius: float = 5.0
@export_range(32.0, 180.0, 1.0) var melee_reach: float = 72.0
@export_range(20.0, 220.0, 1.0) var melee_arc_degrees: float = 100.0
@export_range(0.08, 0.6, 0.01) var melee_duration: float = 0.22
@export_range(0.0, 2.0, 0.05) var mine_arm_seconds: float = 0.4
@export_range(16.0, 160.0, 1.0) var mine_trigger_radius: float = 52.0
@export_range(16.0, 220.0, 1.0) var effect_radius: float = 96.0
@export_range(24.0, 240.0, 1.0) var mine_placement_distance: float = 92.0
@export_range(24.0, 180.0, 1.0) var orbit_radius: float = 72.0
@export_range(0.5, 14.0, 0.1) var orbit_angular_speed: float = 5.0
@export_range(0.05, 2.0, 0.05) var repeat_hit_interval: float = 0.45
@export_range(1, 64, 1) var max_targets: int = 8
@export_range(0.1, 2.0, 0.05) var return_after_seconds: float = 0.65
@export_range(0.5, 3.0, 0.05) var return_speed_multiplier: float = 1.0
@export_range(0.1, 2.0, 0.05) var return_damage_multiplier: float = 0.75

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
@export var on_hit_status_release_threshold: int = 0
@export var on_hit_status_release_damage_multiplier: float = 1.0
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

func get_class_values() -> Array[String]:
	var resolved: Array[String] = []
	for class_variant in classes:
		var class_id := str(class_variant).strip_edges().to_lower()
		if class_id == "" or resolved.has(class_id):
			continue
		resolved.append(class_id)
	return resolved

func has_class(class_id: String) -> bool:
	return get_class_values().has(class_id.strip_edges().to_lower())

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
