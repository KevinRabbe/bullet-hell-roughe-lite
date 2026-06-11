class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var archetype: String = ""
@export var tags: Array[String] = []

@export var max_hp: float = 20.0
@export var move_speed: float = 140.0
@export var contact_damage: float = 6.0
@export var contact_range: float = 28.0
@export var damage_interval_seconds: float = 0.75
@export var ranged_damage: float = 0.0
@export var ranged_interval_seconds: float = 0.0
@export var ranged_attack_range: float = 0.0
@export var visual_texture_path: String = ""
@export var visual_scale: float = 0.09
@export var projectile_texture_path: String = ""
@export var projectile_rotation_offset: float = PI

@export var is_elite: bool = false
@export var is_boss: bool = false
@export var threat_tier: int = 1
@export var reward_gold: int = 1
@export var reward_xp: int = 1
