class_name WeaponData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var family_id: String = ""
@export var cooldown_seconds: float = 0.6
@export var damage: float = 10.0
@export var projectile_speed: float = 700.0
@export var attack_range: float = 1.0
@export var projectile_lifetime_seconds: float = 2.0

@export var projectile_scene_path: String = ""
