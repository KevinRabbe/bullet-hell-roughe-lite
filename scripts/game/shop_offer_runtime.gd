class_name ShopOfferRuntime
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")

const DEFAULT_ITEM_PRICE: int = 3
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]
const WEAPON_RARITY_WEIGHTS_BY_WAVE: Array[Dictionary] = [
	{"max_wave": 2, "weights": {"common": 95.0, "rare": 5.0}},
	{"max_wave": 5, "weights": {"common": 80.0, "rare": 18.0, "epic": 2.0}},
	{"max_wave": 9, "weights": {"common": 60.0, "rare": 32.0, "epic": 8.0}},
	{"max_wave": 9999, "weights": {"common": 45.0, "rare": 38.0, "epic": 15.0, "legendary": 2.0}},
]
const WEAPON_RARITY_PRICE_MULTIPLIER: Dictionary = {
	"common": 1,
	"rare": 2,
	"epic": 4,
	"legendary": 8,
}
const DEFAULT_EARLY_GUARANTEED_WEAPON_SLOTS: int = 2
const DEFAULT_EARLY_RANDOM_SLOTS: int = 2
const DEFAULT_STANDARD_OFFER_SLOTS: int = 4

static func build_weapon_offer_pool(data_registry: Node, weapon_loader: Callable) -> Array[Dictionary]:
	var weapon_offer_pool: Array[Dictionary] = []
	if data_registry != null and data_registry.get("weapons") is Dictionary:
		var weapon_map: Dictionary = data_registry.get("weapons")
		var weapon_ids: Array[String] = []
		for weapon_id_variant in weapon_map.keys():
			weapon_ids.append(str(weapon_id_variant))
		weapon_ids.sort()
		for weapon_id in weapon_ids:
			var offer := make_weapon_offer(weapon_id, weapon_loader)
			if not offer.is_empty():
				weapon_offer_pool.append(offer)
	if not weapon_offer_pool.is_empty():
		return weapon_offer_pool
	var directory := DirAccess.open("res://data/weapons")
	if directory == null:
		return weapon_offer_pool
	var file_names: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	file_names.sort()
	for sorted_file_name in file_names:
		var weapon_id := sorted_file_name.trim_suffix(".tres")
		var fallback_offer := make_weapon_offer(weapon_id, weapon_loader)
		if not fallback_offer.is_empty():
			weapon_offer_pool.append(fallback_offer)
	return weapon_offer_pool

static func make_weapon_offer(weapon_id: String, weapon_loader: Callable) -> Dictionary:
	if not weapon_loader.is_valid():
		return {}
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	var loaded_weapon: Variant = weapon_loader.call(resource_path)
	if not (loaded_weapon is WeaponData):
		return {}
	var data := loaded_weapon as WeaponData
	if not data.shop_enabled:
		return {}

	var resolved_id := weapon_id
	var display_name: String = weapon_id.replace("_", " ").capitalize()
	var price: int = 5
	var family: String = ""
	var tags: Array[String] = []
	var rarity_name: String = "common"
	if data.id != "":
		resolved_id = data.id
	if data.display_name != "":
		display_name = data.display_name
	if data.price > 0:
		price = data.price
	family = data.get_family_value() if data.has_method("get_family_value") else data.family
	tags = data.tags.duplicate()
	rarity_name = data.rarity
	return {
		"type": "weapon",
		"id": resolved_id,
		"label": display_name,
		"price": price,
		"family": family,
		"tags": tags,
		"rarity": rarity_name,
		"base_price": price
	}

static func build_item_offer_pool() -> Array[Dictionary]:
	var item_offer_pool: Array[Dictionary] = []
	for item in ItemDatabase.get_prototype_items():
		if item == null:
			continue
		var item_id := str(item.id)
		if item_id == "":
			continue
		var item_name := item_id.replace("_", " ").capitalize()
		if str(item.name) != "":
			item_name = str(item.name)
		item_offer_pool.append({
			"type": "item",
			"id": item_id,
			"label": item_name,
			"price": DEFAULT_ITEM_PRICE
		})
	return item_offer_pool

static func roll_offers(
	weapon_offer_pool: Array[Dictionary],
	item_offer_pool: Array[Dictionary],
	wave_index: int,
	rng: RandomNumberGenerator,
	preferred_family: String,
	preferred_family_bias: float,
	shop_config: Dictionary = {}
) -> Array[Dictionary]:
	var active_offers: Array[Dictionary] = []
	var combined_pool: Array = weapon_offer_pool.duplicate(true)
	for item_offer in item_offer_pool:
		combined_pool.append(item_offer)
	var guaranteed_weapon_slots := _configured_int(
		shop_config,
		["offer_layout", "early_wave_guaranteed_weapon_slots"],
		DEFAULT_EARLY_GUARANTEED_WEAPON_SLOTS
	)
	var early_random_slots := _configured_int(
		shop_config,
		["offer_layout", "early_wave_random_slots"],
		DEFAULT_EARLY_RANDOM_SLOTS
	)
	var standard_offer_slots := _configured_int(
		shop_config,
		["offer_layout", "standard_offer_slots"],
		DEFAULT_STANDARD_OFFER_SLOTS
	)
	if wave_index <= 2:
		for _slot in guaranteed_weapon_slots:
			var guaranteed_weapon_offer := pick_random_offer(
				weapon_offer_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index,
				shop_config
			)
			active_offers.append(guaranteed_weapon_offer if not guaranteed_weapon_offer.is_empty() else sold_out_offer())
		for _slot in early_random_slots:
			var early_random_offer := pick_random_offer(
				combined_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index,
				shop_config
			)
			active_offers.append(early_random_offer if not early_random_offer.is_empty() else sold_out_offer())
	else:
		for _slot in standard_offer_slots:
			var random_offer := pick_random_offer(
				combined_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index,
				shop_config
			)
			active_offers.append(random_offer if not random_offer.is_empty() else sold_out_offer())
	return active_offers

static func pick_random_offer(
	pool: Array,
	rng: RandomNumberGenerator,
	preferred_family: String,
	preferred_family_bias: float,
	wave_index: int,
	shop_config: Dictionary = {}
) -> Dictionary:
	if pool.is_empty():
		return {}
	var weighted_offers: Array = []
	var weights: Array[float] = []
	for selected_variant in pool:
		if not (selected_variant is Dictionary):
			continue
		var source_offer: Dictionary = selected_variant
		var weight := 1.0
		if str(source_offer.get("type", "")) == "weapon" and preferred_family != "":
			var family_id := str(source_offer.get("family", ""))
			if family_id == preferred_family:
				weight += preferred_family_bias
		weighted_offers.append(source_offer)
		weights.append(weight)
	if weighted_offers.is_empty():
		return {}
	var selected: Variant = WeightedPicker.pick_value(rng, weighted_offers, weights)
	if not (selected is Dictionary):
		return {}
	var offer := (selected as Dictionary).duplicate(true)
	if str(offer.get("type", "")) == "weapon":
		var rolled_rarity := roll_weapon_rarity_for_wave(rng, wave_index, shop_config)
		var base_price := int(offer.get("base_price", int(offer.get("price", 0))))
		var scaled_price := scaled_weapon_price(base_price, rolled_rarity, shop_config)
		offer["rolled_rarity"] = rolled_rarity
		offer["final_price"] = scaled_price
		offer["price"] = scaled_price
	return offer

static func sold_out_offer() -> Dictionary:
	return {"type": "sold_out", "id": "", "label": "Sold Out", "price": 0}

static func roll_weapon_rarity_for_wave(rng: RandomNumberGenerator, wave_index: int, shop_config: Dictionary = {}) -> String:
	var weights := rarity_weights_for_wave(wave_index, shop_config)
	var total_weight := 0.0
	for rarity_name in RARITY_ORDER:
		total_weight += float(weights.get(rarity_name, 0.0))
	if total_weight <= 0.0:
		return "common"
	var roll := rng.randf_range(0.0, total_weight)
	var threshold := 0.0
	for rarity_name in RARITY_ORDER:
		threshold += float(weights.get(rarity_name, 0.0))
		if roll <= threshold:
			return rarity_name
	return "common"

static func rarity_weights_for_wave(wave_index: int, shop_config: Dictionary = {}) -> Dictionary:
	var configured_bands := _configured_array(shop_config, ["weapon_rarity_weights_by_wave"])
	var weight_bands := configured_bands if not configured_bands.is_empty() else WEAPON_RARITY_WEIGHTS_BY_WAVE
	for band_variant in weight_bands:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		if wave_index <= int(band.get("max_wave", 9999)):
			var resolved: Variant = band.get("weights", {})
			if resolved is Dictionary:
				return resolved
	return {"common": 100.0}

static func scaled_weapon_price(base_price: int, rolled_rarity: String, shop_config: Dictionary = {}) -> int:
	var safe_base := maxi(base_price, 1)
	var configured_multipliers := _configured_dictionary(shop_config, ["weapon_rarity_price_multiplier"])
	var multiplier_source := configured_multipliers if not configured_multipliers.is_empty() else WEAPON_RARITY_PRICE_MULTIPLIER
	var multiplier := int(multiplier_source.get(rolled_rarity, 1))
	return safe_base * multiplier

static func _configured_dictionary(config: Dictionary, path: Array[String]) -> Dictionary:
	var resolved: Variant = _configured_value(config, path, {})
	if resolved is Dictionary:
		return resolved
	return {}

static func _configured_array(config: Dictionary, path: Array[String]) -> Array:
	var resolved: Variant = _configured_value(config, path, [])
	if resolved is Array:
		return resolved
	return []

static func _configured_int(config: Dictionary, path: Array[String], fallback: int) -> int:
	return int(_configured_value(config, path, fallback))

static func _configured_value(config: Dictionary, path: Array[String], fallback: Variant) -> Variant:
	if config.is_empty():
		return fallback
	var current: Variant = config
	for key in path:
		if not (current is Dictionary):
			return fallback
		var current_dict: Dictionary = current
		if not current_dict.has(key):
			return fallback
		current = current_dict.get(key)
	return current
