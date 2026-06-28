class_name ShopOfferRuntime
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")

const CONFIG_PATH := "res://data/shop/shop_config.json"
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]
const DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE: Array[Dictionary] = [
	{"max_wave": 2, "weights": {"common": 95.0, "rare": 5.0}},
	{"max_wave": 5, "weights": {"common": 80.0, "rare": 18.0, "epic": 2.0}},
	{"max_wave": 9, "weights": {"common": 60.0, "rare": 32.0, "epic": 8.0}},
	{"max_wave": 9999, "weights": {"common": 45.0, "rare": 38.0, "epic": 15.0, "legendary": 2.0}},
]
const DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER: Dictionary = {
	"common": 1,
	"rare": 2,
	"epic": 4,
	"legendary": 8,
}
const DEFAULT_CONFIG: Dictionary = {
	"default_item_price": 3,
	"base_reroll_cost": 2,
	"reroll_cost_step": 1,
	"early_wave_max": 2,
	"early_guaranteed_weapon_slots": 2,
	"early_random_slots": 2,
	"standard_offer_slots": 4,
	"weapon_rarity_weights_by_wave": DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE,
	"weapon_rarity_price_multiplier": DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER
}

static var _cached_shop_config: Dictionary = {}

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
	var config := get_shop_config()
	var default_item_price := int(config.get("default_item_price", int(DEFAULT_CONFIG.get("default_item_price", 3))))
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
			"price": default_item_price
		})
	return item_offer_pool

static func roll_offers(
	weapon_offer_pool: Array[Dictionary],
	item_offer_pool: Array[Dictionary],
	wave_index: int,
	rng: RandomNumberGenerator,
	preferred_family: String,
	preferred_family_bias: float
) -> Array[Dictionary]:
	var active_offers: Array[Dictionary] = []
	var combined_pool: Array = weapon_offer_pool.duplicate(true)
	var config := get_shop_config()
	var early_wave_max := int(config.get("early_wave_max", int(DEFAULT_CONFIG.get("early_wave_max", 2))))
	var early_guaranteed_weapon_slots := maxi(int(config.get("early_guaranteed_weapon_slots", int(DEFAULT_CONFIG.get("early_guaranteed_weapon_slots", 2)))), 0)
	var early_random_slots := maxi(int(config.get("early_random_slots", int(DEFAULT_CONFIG.get("early_random_slots", 2)))), 0)
	var standard_offer_slots := maxi(int(config.get("standard_offer_slots", int(DEFAULT_CONFIG.get("standard_offer_slots", 4)))), 1)
	for item_offer in item_offer_pool:
		combined_pool.append(item_offer)
	if wave_index <= early_wave_max:
		for _slot in early_guaranteed_weapon_slots:
			var guaranteed_weapon_offer := pick_random_offer(
				weapon_offer_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index
			)
			active_offers.append(guaranteed_weapon_offer if not guaranteed_weapon_offer.is_empty() else sold_out_offer())
		for _slot in early_random_slots:
			var early_random_offer := pick_random_offer(
				combined_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index
			)
			active_offers.append(early_random_offer if not early_random_offer.is_empty() else sold_out_offer())
	else:
		for _slot in standard_offer_slots:
			var random_offer := pick_random_offer(
				combined_pool,
				rng,
				preferred_family,
				preferred_family_bias,
				wave_index
			)
			active_offers.append(random_offer if not random_offer.is_empty() else sold_out_offer())
	return active_offers

static func pick_random_offer(
	pool: Array,
	rng: RandomNumberGenerator,
	preferred_family: String,
	preferred_family_bias: float,
	wave_index: int
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
		var rolled_rarity := roll_weapon_rarity_for_wave(rng, wave_index)
		var base_price := int(offer.get("base_price", int(offer.get("price", 0))))
		var scaled_price := scaled_weapon_price(base_price, rolled_rarity)
		offer["rolled_rarity"] = rolled_rarity
		offer["final_price"] = scaled_price
		offer["price"] = scaled_price
	return offer

static func sold_out_offer() -> Dictionary:
	return {"type": "sold_out", "id": "", "label": "Sold Out", "price": 0}

static func roll_weapon_rarity_for_wave(rng: RandomNumberGenerator, wave_index: int) -> String:
	var weights := rarity_weights_for_wave(wave_index)
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

static func rarity_weights_for_wave(wave_index: int) -> Dictionary:
	var config := get_shop_config()
	var bands_variant: Variant = config.get("weapon_rarity_weights_by_wave", DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE)
	if not (bands_variant is Array):
		return {"common": 100.0}
	for band_variant in bands_variant:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		if wave_index <= int(band.get("max_wave", 9999)):
			var resolved: Variant = band.get("weights", {})
			if resolved is Dictionary:
				return resolved
	return {"common": 100.0}

static func scaled_weapon_price(base_price: int, rolled_rarity: String) -> int:
	var safe_base := maxi(base_price, 1)
	var config := get_shop_config()
	var multipliers_variant: Variant = config.get("weapon_rarity_price_multiplier", DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER)
	var multipliers: Dictionary = multipliers_variant if multipliers_variant is Dictionary else DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER
	var multiplier := int(multipliers.get(rolled_rarity, 1))
	return safe_base * multiplier

static func get_shop_config() -> Dictionary:
	if not _cached_shop_config.is_empty():
		return _cached_shop_config
	if not FileAccess.file_exists(CONFIG_PATH):
		_cached_shop_config = DEFAULT_CONFIG.duplicate(true)
		push_warning("Shop config missing, using defaults: %s" % CONFIG_PATH)
		return _cached_shop_config
	var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
	if file == null:
		_cached_shop_config = DEFAULT_CONFIG.duplicate(true)
		push_warning("Shop config could not be opened, using defaults: %s" % CONFIG_PATH)
		return _cached_shop_config
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_cached_shop_config = _normalize_shop_config(parsed as Dictionary)
		return _cached_shop_config
	_cached_shop_config = DEFAULT_CONFIG.duplicate(true)
	push_warning("Shop config invalid, using defaults: %s" % CONFIG_PATH)
	return _cached_shop_config

static func _normalize_shop_config(source: Dictionary) -> Dictionary:
	var normalized := DEFAULT_CONFIG.duplicate(true)
	for key_variant in source.keys():
		var key := str(key_variant)
		match key:
			"default_item_price", "base_reroll_cost", "reroll_cost_step", "early_wave_max", "early_guaranteed_weapon_slots", "early_random_slots", "standard_offer_slots":
				normalized[key] = int(source.get(key, normalized[key]))
			"weapon_rarity_weights_by_wave":
				var bands_variant: Variant = source.get(key, normalized[key])
				if bands_variant is Array:
					normalized[key] = bands_variant
				else:
					push_warning("Shop config has invalid rarity weight bands; using defaults.")
			"weapon_rarity_price_multiplier":
				var multipliers_variant: Variant = source.get(key, normalized[key])
				if multipliers_variant is Dictionary:
					normalized[key] = multipliers_variant
				else:
					push_warning("Shop config has invalid rarity price multipliers; using defaults.")
	return normalized
