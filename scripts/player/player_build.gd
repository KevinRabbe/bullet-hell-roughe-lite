extends Node

@export var active_character_data: Resource
@export var active_character_id: String = "gunslinger"
@export var equipped_weapon_ids: Array[String] = []
@export var owned_item_ids: Array[String] = []
@export var calculated_stats: Dictionary = {}

func add_weapon_id(weapon_id: String) -> void:
	if weapon_id == "":
		return
	equipped_weapon_ids.append(weapon_id)

func add_item_id(item_id: String) -> void:
	if item_id == "":
		return
	owned_item_ids.append(item_id)

func set_active_character(character_id: String) -> void:
	if character_id == "":
		return
	active_character_id = character_id
