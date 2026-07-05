class_name ItemData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var category: String = "generic"
@export var rarity: String = "common"
@export var tags: Array[String] = []
@export var price: int = 3
@export var stack_limit: int = 1
@export var stat_modifiers: Dictionary = {}
@export var weapon_tag_stat_bonuses: Array[Dictionary] = []

func _init(
	new_id: String = "",
	new_name: String = "",
	new_description: String = "",
	new_category: String = "generic",
	new_rarity: String = "common",
	new_tags: Array[String] = [],
	new_price: int = 3,
	new_stack_limit: int = 1,
	new_stat_modifiers: Dictionary = {},
	new_weapon_tag_stat_bonuses: Array[Dictionary] = []
) -> void:
	id = new_id
	name = new_name
	description = new_description
	category = new_category
	rarity = new_rarity
	tags = new_tags.duplicate()
	price = new_price
	stack_limit = new_stack_limit
	stat_modifiers = new_stat_modifiers.duplicate(true)
	weapon_tag_stat_bonuses = new_weapon_tag_stat_bonuses.duplicate(true)
