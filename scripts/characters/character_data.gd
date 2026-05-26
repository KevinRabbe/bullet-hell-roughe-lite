class_name CharacterData
extends Resource

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""

@export var base_max_hp: float = 100.0
@export var base_move_speed: float = 300.0
@export var base_damage: float = 1.0
@export var base_attack_speed: float = 1.0
@export var base_attack_range: float = 1.0

@export var starting_weapon_ids: Array[String] = []
@export var passive_effect_tags: Array[String] = []
