class_name ItemData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var category: String = "generic"
@export var rarity: String = "common"
@export var tags: Array[String] = []
@export var icon: Texture2D
@export var price: int = 3
@export var stack_limit: int = 1
@export_range(1, 3, 1) var reward_tier: int = 1
@export var stat_modifiers: Dictionary = {}
@export var weapon_tag_stat_bonuses: Array[Dictionary] = []
@export var stat_conversion_rules: Array[Dictionary] = []
@export var runtime_rules: Array[Dictionary] = []

func _init(
	new_id: String = "",
	new_name: String = "",
	new_description: String = "",
	new_category: String = "generic",
	new_rarity: String = "common",
	new_tags: Array[String] = [],
	new_price: int = 3,
	new_stack_limit: int = 1,
	new_reward_tier: int = 1,
	new_stat_modifiers: Dictionary = {},
	new_weapon_tag_stat_bonuses: Array[Dictionary] = [],
	new_stat_conversion_rules: Array[Dictionary] = [],
	new_runtime_rules: Array[Dictionary] = [],
	new_icon: Texture2D = null
) -> void:
	id = new_id
	name = new_name
	description = new_description
	category = new_category
	rarity = new_rarity
	tags = new_tags.duplicate()
	icon = new_icon
	price = new_price
	stack_limit = new_stack_limit
	reward_tier = new_reward_tier
	stat_modifiers = new_stat_modifiers.duplicate(true)
	weapon_tag_stat_bonuses = new_weapon_tag_stat_bonuses.duplicate(true)
	stat_conversion_rules = new_stat_conversion_rules.duplicate(true)
	runtime_rules = new_runtime_rules.duplicate(true)
