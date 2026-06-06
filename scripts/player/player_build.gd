extends Node

@export var active_character_data: Resource
@export var active_character_id: String = ""
@export var equipped_weapon_ids: Array[String] = []
@export var owned_item_ids: Array[String] = []
@export var calculated_stats: Dictionary = {}

func _ready() -> void:
	if active_character_id != "":
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry != null and data_registry.has_method("get_default_selectable_character_id"):
		var resolved_character_id := str(data_registry.call("get_default_selectable_character_id"))
		if resolved_character_id != "":
			active_character_id = resolved_character_id
			return
	active_character_id = "gunslinger"

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
