extends RefCounted

static func get_prototype_items() -> Array[ItemData]:
	return [
		ItemData.new(
			"swift_boots",
			"Swift Boots",
			"Move faster.",
			{"movement_speed": 35.0}
		),
		ItemData.new(
			"glass_scope",
			"Glass Scope",
			"Projectiles travel farther and faster.",
			{"attack_range": 0.2, "projectile_speed": 0.25}
		),
		ItemData.new(
			"steel_heart",
			"Steel Heart",
			"Gain max HP and armor.",
			{"max_hp": 25.0, "armor": 2.0}
		),
		ItemData.new(
			"trigger_core",
			"Trigger Core",
			"Fire faster and hit harder.",
			{"attack_speed": 0.2, "damage": 0.2}
		),
		ItemData.new(
			"lucky_charm",
			"Lucky Charm",
			"Improve luck and dodge chance.",
			{"luck": 1.0, "dodge": 0.05}
		)
	]

static func get_random_item(rng: RandomNumberGenerator) -> ItemData:
	var items := get_prototype_items()
	if items.is_empty():
		return ItemData.new()
	return items[rng.randi_range(0, items.size() - 1)]

static func get_random_item_for_tier(tier: int, rng: RandomNumberGenerator) -> ItemData:
	var tier_ids: Array[String]
	match tier:
		3:
			tier_ids = ["steel_heart", "trigger_core"]
		2:
			tier_ids = ["glass_scope", "lucky_charm"]
		_:
			tier_ids = ["swift_boots", "lucky_charm"]

	var pool: Array[ItemData] = []
	for item in get_prototype_items():
		if tier_ids.has(item.id):
			pool.append(item)
	if pool.is_empty():
		return get_random_item(rng)
	return pool[rng.randi_range(0, pool.size() - 1)]
