class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var archetype: String = ""
@export var tags: Array[String] = []
@export_enum("chaser", "ranged_slow", "ranged_hold") var movement_profile: String = "chaser"
@export_enum("standard", "committed_charger", "area_denier", "support_commander") var combat_profile: String = "standard"

@export var max_hp: float = 20.0
@export var move_speed: float = 140.0
@export_range(8.0, 72.0, 1.0) var collision_radius: float = 14.0
@export var contact_damage: float = 6.0
@export var contact_range: float = 28.0
@export var damage_interval_seconds: float = 0.75
@export var ranged_damage: float = 0.0
@export var ranged_interval_seconds: float = 0.0
@export var ranged_attack_range: float = 0.0
@export_range(1, 7, 1) var projectile_count: int = 1
@export_range(0.0, 90.0, 1.0) var projectile_spread_degrees: float = 0.0
@export var projectile_speed: float = 360.0
@export var projectile_lifetime_seconds: float = 2.0
@export var visual_texture_path: String = ""
@export var visual_scale: float = 0.09
@export var directional_locomotion_texture_path: String = ""
@export var directional_locomotion_scale: float = 0.09
@export_range(1, 4, 1) var directional_locomotion_columns: int = 2
@export_range(1, 4, 1) var directional_locomotion_rows: int = 4
@export_range(1.0, 20.0, 0.5) var directional_locomotion_fps: float = 7.0
@export var directional_locomotion_frame_offsets: Array[Vector2] = []
@export var projectile_texture_path: String = ""
@export var projectile_rotation_offset: float = PI

@export var is_elite: bool = false
@export var is_boss: bool = false
@export var threat_tier: int = 1
@export var reward_gold: int = 1
@export var reward_xp: int = 1
