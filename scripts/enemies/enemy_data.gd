class_name EnemyData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var max_hp: float = 20.0
@export var move_speed: float = 140.0
@export var contact_damage: float = 6.0
@export var contact_range: float = 28.0
@export var damage_interval_seconds: float = 0.75

@export var is_elite: bool = false
@export var threat_tier: int = 1
