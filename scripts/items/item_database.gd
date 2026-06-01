extends RefCounted

const ITEM_RESOURCE_PATHS: Array[String] = [
	"res://data/items/swift_boots.tres",
	"res://data/items/glass_scope.tres",
	"res://data/items/steel_heart.tres",
	"res://data/items/trigger_core.tres",
	"res://data/items/lucky_charm.tres",
	"res://data/items/blood_emblem.tres",
	"res://data/items/rapid_chamber.tres",
	"res://data/items/deadeye_lens.tres",
	"res://data/items/long_barrel.tres",
	"res://data/items/overcharged_powder.tres",
	"res://data/items/iron_spike_rounds.tres",
	"res://data/items/gale_sash.tres",
	"res://data/items/bastion_plating.tres",
	"res://data/items/cursed_idol.tres",
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
	var allowed_rarities: Array[String] = ["common"]
	match tier:
		3:
			allowed_rarities = ["rare", "epic", "legendary"]
		2:
			allowed_rarities = ["common", "rare"]
		_:
			allowed_rarities = ["common"]

	var pool: Array[ItemData] = []
	for item in get_prototype_items():
		if allowed_rarities.has(item.rarity):
			pool.append(item)
	if pool.is_empty():
		return get_random_item(rng)
	return pool[rng.randi_range(0, pool.size() - 1)]
