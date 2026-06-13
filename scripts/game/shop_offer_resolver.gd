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

var rng: RandomNumberGenerator
var _weapon_data_cache: Dictionary = {}

func configure(configured_rng: RandomNumberGenerator) -> void:
	rng = configured_rng

func build_weapon_offer_pool(data_registry: Node) -> Array[Dictionary]:
	var weapon_offer_pool: Array[Dictionary] = []
	if data_registry != null and data_registry.get("weapons") is Dictionary:
		var weapon_map: Dictionary = data_registry.get("weapons")
		var weapon_ids: Array[String] = []
		for weapon_id_variant in weapon_map.keys():
			weapon_ids.append(str(weapon_id_variant))
		weapon_ids.sort()
		for weapon_id in weapon_ids:
			var offer := _make_weapon_offer(weapon_id)
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
		var offer := _make_weapon_offer(weapon_id)
		if not offer.is_empty():
			weapon_offer_pool.append(offer)
	return weapon_offer_pool

func build_item_offer_pool() -> Array[Dictionary]:
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

func roll_offers(
	weapon_offer_pool: Array[Dictionary],
	item_offer_pool: Array[Dictionary],
	wave_index: int,
	preferred_family: String,
	preferred_family_bias: float
) -> Array[Dictionary]:
	var rolled_offers: Array[Dictionary] = []
	var combined_pool: Array = weapon_offer_pool.duplicate(true)
	for item_offer in item_offer_pool:
		combined_pool.append(item_offer)
	if wave_index <= 2:
		for _slot in 2:
			var guaranteed_weapon_offer := _pick_random_offer(weapon_offer_pool, preferred_family, preferred_family_bias, wave_index)
			rolled_offers.append(guaranteed_weapon_offer if not guaranteed_weapon_offer.is_empty() else sold_out_offer())
		for _slot in 2:
			var random_offer := _pick_random_offer(combined_pool, preferred_family, preferred_family_bias, wave_index)
			rolled_offers.append(random_offer if not random_offer.is_empty() else sold_out_offer())
	else:
		for _slot in 4:
			var random_offer := _pick_random_offer(combined_pool, preferred_family, preferred_family_bias, wave_index)
			rolled_offers.append(random_offer if not random_offer.is_empty() else sold_out_offer())
	return rolled_offers

func sold_out_offer() -> Dictionary:
	return {"type": "sold_out", "id": "", "label": "Sold Out", "price": 0}

func _make_weapon_offer(weapon_id: String) -> Dictionary:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	var data := _load_weapon_data(resource_path)
	if data == null:
		return {}
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

func _pick_random_offer(pool: Array, preferred_family: String, preferred_family_bias: float, wave_index: int) -> Dictionary:
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
	if selected is Dictionary:
		var offer := (selected as Dictionary).duplicate(true)
		if str(offer.get("type", "")) == "weapon":
			var rolled_rarity := _roll_weapon_rarity_for_wave(wave_index)
			var base_price := int(offer.get("base_price", int(offer.get("price", 0))))
			var scaled_price := _scaled_weapon_price(base_price, rolled_rarity)
			offer["rolled_rarity"] = rolled_rarity
			offer["final_price"] = scaled_price
			offer["price"] = scaled_price
		return offer
	return {}

func _roll_weapon_rarity_for_wave(wave_index: int) -> String:
	var weights := _rarity_weights_for_wave(wave_index)
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

func _rarity_weights_for_wave(wave_index: int) -> Dictionary:
	for band_variant in WEAPON_RARITY_WEIGHTS_BY_WAVE:
		if not (band_variant is Dictionary):
			continue
		var band: Dictionary = band_variant
		if wave_index <= int(band.get("max_wave", 9999)):
			var resolved: Variant = band.get("weights", {})
			if resolved is Dictionary:
				return resolved
	return {"common": 100.0}

func _scaled_weapon_price(base_price: int, rolled_rarity: String) -> int:
	var safe_base := maxi(base_price, 1)
	var multiplier := int(WEAPON_RARITY_PRICE_MULTIPLIER.get(rolled_rarity, 1))
	return safe_base * multiplier

func _load_weapon_data(resource_path: String) -> WeaponData:
	if _weapon_data_cache.has(resource_path):
		var cached: Variant = _weapon_data_cache[resource_path]
		if cached is WeaponData:
			return cached
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path) as WeaponData
	if loaded != null:
		_weapon_data_cache[resource_path] = loaded
	return loaded
