class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D

@export var family: String = ""
@export var tags: Array[String] = []
@export_enum("common", "rare", "epic", "legendary") var rarity: String = "common"

@export var damage_type: String = ""
@export var base_damage: float = 10.0
@export var cooldown: float = 0.6
@export var attack_speed: float = 1.0
@export var range: float = 1.0
@export var projectile_speed: float = 700.0
@export var pierce: int = 0
@export var knockback: float = 0.0

@export var price: int = 0

@export var stat_scaling: Dictionary = {}

@export var special_effect_id: String = ""

# Existing fields preserved to avoid breaking gameplay
@export var family_id: String = ""
@export var cooldown_seconds: float = 0.6
@export var damage: float = 10.0
@export var attack_range: float = 1.0
@export var projectile_lifetime_seconds: float = 2.0
@export var projectile_scene_path: String = ""
