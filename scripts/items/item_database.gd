extends RefCounted

const ITEM_RESOURCE_PATHS: Array[String] = [
	"res://data/items/swift_boots.tres",
	"res://data/items/glass_scope.tres",
	"res://data/items/steel_heart.tres",
	"res://data/items/trigger_core.tres",
	"res://data/items/lucky_charm.tres",
	"res://data/items/demon_powder.tres",
	"res://data/items/rapid_loader.tres",
	"res://data/items/blood_talisman.tres",
	"res://data/items/rune_prism.tres",
	"res://data/items/void_rounds.tres",
	"res://data/items/harvest_emblem.tres",
	"res://data/items/obsidian_mail.tres",
	"res://data/items/rift_compass.tres",
	"res://data/items/hellfire_idol.tres",
]

static func get_prototype_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for resource_path in ITEM_RESOURCE_PATHS:
		if not ResourceLoader.exists(resource_path):
			continue
		var item_resource := load(resource_path)
		if item_resource is ItemData:
			items.append(item_resource as ItemData)
	return items

static func get_random_item(rng: RandomNumberGenerator) -> ItemData:
	var items := get_prototype_items()
	if items.is_empty():
		return ItemData.new()
	return items[rng.randi_range(0, items.size() - 1)]

static func get_random_item_for_tier(tier: int, rng: RandomNumberGenerator) -> ItemData:
	var tier_ids: Array[String]
	match tier:
		3:
			tier_ids = ["steel_heart", "trigger_core", "obsidian_mail", "hellfire_idol"]
		2:
			tier_ids = ["glass_scope", "lucky_charm", "rune_prism", "void_rounds", "harvest_emblem", "rift_compass"]
		_:
			tier_ids = ["swift_boots", "lucky_charm", "demon_powder", "rapid_loader", "blood_talisman"]

	var pool: Array[ItemData] = []
	for item in get_prototype_items():
		if tier_ids.has(item.id):
			pool.append(item)
	if pool.is_empty():
		return get_random_item(rng)
	return pool[rng.randi_range(0, pool.size() - 1)]
