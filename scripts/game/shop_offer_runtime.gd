class_name ShopOfferRuntime
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")
const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")

const CONFIG_PATH := "res://data/shop/shop_config.json"
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]
const DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE: Array[Dictionary] = [
	{"max_wave": 2, "weights": {"common": 95.0, "rare": 5.0}},
	{"max_wave": 5, "weights": {"common": 80.0, "rare": 18.0, "epic": 2.0}},
	{"max_wave": 9, "weights": {"common": 60.0, "rare": 32.0, "epic": 8.0}},
	{"max_wave": 14, "weights": {"common": 45.0, "rare": 38.0, "epic": 15.0, "legendary": 2.0}},
	{"max_wave": 20, "weights": {"common": 32.0, "rare": 40.0, "epic": 23.0, "legendary": 5.0}},
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
	tags = WeaponTagRuntimeRef.weapon_tags(data)
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
		var item_price := item.price if item.price > 0 else default_item_price
		item_offer_pool.append({
			"type": "item",
			"id": item_id,
			"label": item_name,
			"price": item_price,
			"base_price": item_price,
			"rarity": item.rarity,
			"tags": WeaponTagRuntimeRef.item_tags(item)
		})
	return item_offer_pool

# The two family arguments remain in the signature only while callers migrate.
# They intentionally have no effect: character ownership no longer steers the
# weapon pool by thematic family.
static func roll_offers(
	weapon_offer_pool: Array[Dictionary],
	item_offer_pool: Array[Dictionary],
	wave_index: int,
	rng: RandomNumberGenerator,
	_preferred_family: String,
	_preferred_family_bias: float,
	rarity_luck: float = 0.0
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
				_preferred_family,
				_preferred_family_bias,
				wave_index,
				rarity_luck
			)
			active_offers.append(guaranteed_weapon_offer if not guaranteed_weapon_offer.is_empty() else sold_out_offer())
		for _slot in early_random_slots:
			var early_random_offer := pick_random_offer(
				combined_pool,
				rng,
				_preferred_family,
				_preferred_family_bias,
				wave_index,
				rarity_luck
			)
			active_offers.append(early_random_offer if not early_random_offer.is_empty() else sold_out_offer())
	else:
		for _slot in standard_offer_slots:
			var random_offer := pick_random_offer(
				combined_pool,
				rng,
				_preferred_family,
				_preferred_family_bias,
				wave_index,
				rarity_luck
			)
			active_offers.append(random_offer if not random_offer.is_empty() else sold_out_offer())
	return active_offers

static func pick_random_offer(
	pool: Array,
	rng: RandomNumberGenerator,
	_preferred_family: String,
	_preferred_family_bias: float,
	wave_index: int,
	rarity_luck: float = 0.0
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
		if str(source_offer.get("type", "")) == "item":
			weight *= _rarity_luck_weight(str(source_offer.get("rarity", "common")), rarity_luck)
		weighted_offers.append(source_offer)
		weights.append(weight)
	if weighted_offers.is_empty():
		return {}
	var selected: Variant = WeightedPicker.pick_value(rng, weighted_offers, weights)
	if not (selected is Dictionary):
		return {}
	var offer := (selected as Dictionary).duplicate(true)
	if str(offer.get("type", "")) == "weapon":
		var rolled_rarity := roll_weapon_rarity_for_wave(rng, wave_index, rarity_luck)
		var base_price := int(offer.get("base_price", int(offer.get("price", 0))))
		var scaled_price := scaled_weapon_price(base_price, rolled_rarity)
		offer["rolled_rarity"] = rolled_rarity
		offer["final_price"] = scaled_price
		offer["price"] = scaled_price
	return offer

static func sold_out_offer() -> Dictionary:
	return {"type": "sold_out", "id": "", "label": "Sold Out", "price": 0}

static func roll_weapon_rarity_for_wave(rng: RandomNumberGenerator, wave_index: int, rarity_luck: float = 0.0) -> String:
	var weights := rarity_weights_with_luck(rarity_weights_for_wave(wave_index), rarity_luck)
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

static func rarity_weights_with_luck(base_weights: Dictionary, rarity_luck: float) -> Dictionary:
	var resolved := base_weights.duplicate(true)
	for rarity_index in range(RARITY_ORDER.size()):
		var rarity_name := RARITY_ORDER[rarity_index]
		var base_weight := maxf(float(base_weights.get(rarity_name, 0.0)), 0.0)
		resolved[rarity_name] = base_weight * maxf(1.0 + (rarity_luck * 0.08 * float(rarity_index)), 0.1)
	return resolved

static func _rarity_luck_weight(rarity_name: String, rarity_luck: float) -> float:
	var rarity_index := RARITY_ORDER.find(rarity_name.to_lower())
	if rarity_index < 0:
		rarity_index = 0
	return maxf(1.0 + (rarity_luck * 0.08 * float(rarity_index)), 0.1)

static func rarity_weights_for_wave(wave_index: int) -> Dictionary:
	return rarity_weights_for_wave_in_config(get_shop_config(), wave_index)

static func rarity_weights_for_wave_in_config(config: Dictionary, wave_index: int) -> Dictionary:
	var bands_variant: Variant = config.get("weapon_rarity_weights_by_wave", DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE)
	if not (bands_variant is Array):
		return {"common": 100.0}
	var fallback_weights: Dictionary = {"common": 100.0}
	for band_variant in bands_variant:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		var resolved: Variant = band.get("weights", {})
		if not (resolved is Dictionary):
			continue
		fallback_weights = (resolved as Dictionary).duplicate(true)
		if wave_index <= int(band.get("max_wave", 9999)):
			return fallback_weights.duplicate(true)
	return fallback_weights.duplicate(true)

static func scaled_weapon_price(base_price: int, rolled_rarity: String) -> int:
	var safe_base := maxi(base_price, 1)
	var config := get_shop_config()
	var multipliers_variant: Variant = config.get("weapon_rarity_price_multiplier", DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER)
	var multipliers: Dictionary = multipliers_variant if multipliers_variant is Dictionary else DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER
	var multiplier := int(multipliers.get(rolled_rarity, 1))
	return safe_base * multiplier

static func read_shop_config(config_path: String = CONFIG_PATH) -> Dictionary:
	if not FileAccess.file_exists(config_path):
		push_warning("Shop config missing: %s" % config_path)
		return {}
	var config_text := FileAccess.get_file_as_string(config_path)
	var parsed: Variant = JSON.parse_string(config_text)
	if not (parsed is Dictionary):
		push_warning("Shop config invalid: %s" % config_path)
		return {}
	return (parsed as Dictionary).duplicate(true)

static func get_shop_config() -> Dictionary:
	if not _cached_shop_config.is_empty():
		return _cached_shop_config
	var config := read_shop_config(CONFIG_PATH)
	if config.is_empty():
		_cached_shop_config = DEFAULT_CONFIG.duplicate(true)
		push_warning("Using default Shop config: %s" % CONFIG_PATH)
	else:
		_cached_shop_config = normalize_shop_config(config)
	return _cached_shop_config

static func normalize_shop_config(source: Dictionary) -> Dictionary:
	var normalized := DEFAULT_CONFIG.duplicate(true)
	for int_key in ["default_item_price", "base_reroll_cost", "reroll_cost_step", "early_wave_max", "early_guaranteed_weapon_slots", "early_random_slots", "standard_offer_slots"]:
		if source.has(int_key):
			normalized[int_key] = int(source.get(int_key, normalized[int_key]))
	var bands_variant: Variant = source.get("weapon_rarity_weights_by_wave", DEFAULT_WEAPON_RARITY_WEIGHTS_BY_WAVE)
	if bands_variant is Array:
		var bands: Array = bands_variant
		var normalized_bands: Array[Dictionary] = []
		for band_variant in bands:
			if not (band_variant is Dictionary):
				continue
			var band: Dictionary = band_variant
			var weights_variant: Variant = band.get("weights", {})
			if not (weights_variant is Dictionary):
				continue
			var weights_dict: Dictionary = weights_variant
			var normalized_weights: Dictionary = {}
			for rarity_name in RARITY_ORDER:
				if weights_dict.has(rarity_name):
					normalized_weights[rarity_name] = float(weights_dict.get(rarity_name, 0.0))
			if normalized_weights.is_empty():
				continue
			normalized_bands.append({
				"max_wave": int(band.get("max_wave", 9999)),
				"weights": normalized_weights
			})
		if not normalized_bands.is_empty():
			normalized["weapon_rarity_weights_by_wave"] = normalized_bands
		else:
			push_warning("Shop config has invalid rarity weight bands; using defaults.")
	else:
		push_warning("Shop config has invalid rarity weight bands; using defaults.")
	var multipliers_variant: Variant = source.get("weapon_rarity_price_multiplier", DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER)
	if multipliers_variant is Dictionary:
		var multipliers_dict: Dictionary = multipliers_variant
		var normalized_multipliers := DEFAULT_WEAPON_RARITY_PRICE_MULTIPLIER.duplicate(true)
		for rarity_name in RARITY_ORDER:
			if multipliers_dict.has(rarity_name):
				normalized_multipliers[rarity_name] = maxi(int(multipliers_dict.get(rarity_name, 1)), 1)
		normalized["weapon_rarity_price_multiplier"] = normalized_multipliers
	else:
		push_warning("Shop config has invalid rarity price multipliers; using defaults.")
	return normalized
