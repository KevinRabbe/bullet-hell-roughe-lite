extends RefCounted

const ItemData = preload("res://scripts/items/item_data.gd")

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
			{"range": 0.2, "projectile_speed": 0.25}
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
