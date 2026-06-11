extends Node

signal continue_requested
signal shop_opened(wave_index: int)
signal shop_closed
signal offers_changed
signal reroll_cost_changed(new_cost: int)
signal offer_purchased(index: int, offer: Dictionary)

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const WeightedPicker = preload("res://scripts/core/weighted_picker.gd")

@export var enemy_spawner_path: NodePath
@export var player_path: NodePath
@export var panel_path: NodePath
@export var title_label_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var reroll_button_path: NodePath
@export var continue_button_path: NodePath
@export var reroll_cost: int = 2
@export var enabled: bool = false

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

var enemy_spawner: Node
var player: Node
var panel: Control
var title_label: Label
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var reroll_count: int = 0
var rng: RandomNumberGenerator
var _current_wave_index: int = 1
var _weapon_offer_pool: Array[Dictionary] = []
var _item_offer_pool: Array[Dictionary] = []
var active_offers: Array[Dictionary] = []
var _weapon_data_cache: Dictionary = {}

func _ready() -> void:
	rng = _resolve_rng("shop")
	_build_weapon_offer_pool()
	_build_item_offer_pool()
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if panel_path != NodePath():
		panel = get_node_or_null(panel_path)
	if title_label_path != NodePath():
		title_label = get_node_or_null(title_label_path)
	if reroll_button_path != NodePath():
		reroll_button = get_node_or_null(reroll_button_path)
	if continue_button_path != NodePath():
		continue_button = get_node_or_null(continue_button_path)

	for button_path in offer_button_paths:
		var button := get_node_or_null(button_path)
		if button is Button:
			offer_buttons.append(button)

	for index in offer_buttons.size():
		offer_buttons[index].pressed.connect(_on_offer_pressed.bind(index))
	if reroll_button != null:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)

	if panel != null:
		panel.visible = false
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)

func _build_weapon_offer_pool() -> void:
	_weapon_offer_pool.clear()
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry != null and data_registry.get("weapons") is Dictionary:
		var weapon_map: Dictionary = data_registry.get("weapons")
		var weapon_ids: Array[String] = []
		for weapon_id_variant in weapon_map.keys():
			weapon_ids.append(str(weapon_id_variant))
		weapon_ids.sort()
		for weapon_id in weapon_ids:
			var offer := _make_weapon_offer(weapon_id)
			if not offer.is_empty():
				_weapon_offer_pool.append(offer)
	if not _weapon_offer_pool.is_empty():
		return
	var directory := DirAccess.open("res://data/weapons")
	if directory == null:
		return
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
			_weapon_offer_pool.append(offer)

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

func _build_item_offer_pool() -> void:
	_item_offer_pool.clear()
	for item in ItemDatabase.get_prototype_items():
		if item == null:
			continue
		var item_id := str(item.id)
		if item_id == "":
			continue
		var item_name := item_id.replace("_", " ").capitalize()
		if str(item.name) != "":
			item_name = str(item.name)
		_item_offer_pool.append({
			"type": "item",
			"id": item_id,
			"label": item_name,
			"price": DEFAULT_ITEM_PRICE
		})

func _on_wave_completed(wave_index: int) -> void:
	if not enabled:
		return
	_current_wave_index = maxi(wave_index, 1)
	reroll_count = 0
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()
	if title_label != null:
		title_label.text = "Shop - Pick one"
	if panel != null:
		panel.visible = true
	shop_opened.emit(_current_wave_index)
	offers_changed.emit()
	reroll_cost_changed.emit(_current_reroll_cost())
	print("Shop opened with %d offers." % active_offers.size())

func get_active_offers() -> Array[Dictionary]:
	var copied: Array[Dictionary] = []
	for offer in active_offers:
		if offer is Dictionary:
			copied.append((offer as Dictionary).duplicate(true))
	return copied

func get_current_reroll_cost() -> int:
	return _current_reroll_cost()

func is_shop_open() -> bool:
	return panel != null and panel.visible

func get_current_wave_index() -> int:
	return _current_wave_index

func _roll_offers() -> void:
	active_offers.clear()
	var combined_pool: Array = _weapon_offer_pool.duplicate(true)
	for item_offer in _item_offer_pool:
		combined_pool.append(item_offer)
	if _current_wave_index <= 2:
		for _slot in 2:
			var guaranteed_weapon_offer := _pick_random_offer(_weapon_offer_pool)
			active_offers.append(guaranteed_weapon_offer if not guaranteed_weapon_offer.is_empty() else _sold_out_offer())
		for _slot in 2:
			var random_offer := _pick_random_offer(combined_pool)
			active_offers.append(random_offer if not random_offer.is_empty() else _sold_out_offer())
	else:
		for _slot in 4:
			var random_offer := _pick_random_offer(combined_pool)
			active_offers.append(random_offer if not random_offer.is_empty() else _sold_out_offer())

func _refresh_offer_buttons() -> void:
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		if index < active_offers.size():
			var offer: Dictionary = active_offers[index]
			var price := int(offer.get("price", 0))
			var offer_type := str(offer.get("type", ""))
			if offer_type == "sold_out":
				button.text = "Sold Out"
				button.disabled = true
			else:
				var rarity_badge := ""
				if offer_type == "weapon":
					rarity_badge = "[%s] " % str(offer.get("rolled_rarity", "common")).capitalize()
				button.text = "%s%s (%dG)" % [rarity_badge, str(offer.get("label", "Offer")), price]
				button.disabled = false
		else:
			button.text = "N/A"
			button.disabled = true

func _on_offer_pressed(index: int) -> void:
	if index < 0 or index >= active_offers.size():
		return
	if player == null or not is_instance_valid(player):
		return
	var offer: Dictionary = active_offers[index]
	if str(offer.get("type", "")) == "sold_out":
		return
	var offer_price := int(offer.get("price", 0))
	var offer_type := str(offer.get("type", ""))
	var offer_id := str(offer.get("id", ""))

	if offer_type == "weapon":
		var loadout: Node = player.get_node_or_null("WeaponLoadout")
		var rolled_rarity := str(offer.get("rolled_rarity", "common"))
		if loadout != null:
			if loadout.has_method("can_grant_weapon"):
				if loadout.call("can_grant_weapon", offer_id, rolled_rarity) != true:
					print("Cannot buy weapon. No loadout slot or combine upgrade available for %s." % offer_id)
					return
			elif loadout.has_method("has_space") and loadout.call("has_space") != true:
				print("Cannot buy weapon. Weapon loadout is full.")
				return

	if player.has_method("spend_gold"):
		var paid: bool = player.call("spend_gold", offer_price) == true
		if not paid:
			return

	if offer_type == "weapon":
		var rolled_rarity := str(offer.get("rolled_rarity", "common"))
		if player.has_method("grant_weapon"):
			var granted: bool = player.call("grant_weapon", offer_id, rolled_rarity) == true
			if not granted:
				if player.has_method("add_gold"):
					player.call("add_gold", offer_price)
				print("Weapon purchase rejected: %s" % offer_id)
				return
	elif offer_type == "item":
		var item_data := _find_item_data(offer_id)
		if item_data != null and player.has_method("grant_item"):
			player.call("grant_item", item_data)
		else:
			if player.has_method("add_gold"):
				player.call("add_gold", offer_price)
			print("Item purchase failed: %s" % offer_id)
			return

	print("Bought: %s for %dG" % [str(offer.get("label", "Offer")), offer_price])
	active_offers[index] = _sold_out_offer()
	_refresh_offer_buttons()
	offer_purchased.emit(index, offer.duplicate(true))
	offers_changed.emit()

func _on_reroll_pressed() -> void:
	var total_cost := _current_reroll_cost()
	if player != null and is_instance_valid(player) and player.has_method("spend_gold"):
		var paid: bool = player.call("spend_gold", total_cost) == true
		if not paid:
			return
	reroll_count += 1
	print("Reroll shop. Cost: %d" % total_cost)
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()
	offers_changed.emit()
	reroll_cost_changed.emit(_current_reroll_cost())

func _update_reroll_button_text() -> void:
	if reroll_button == null:
		return
	reroll_button.text = "Reroll (%dG)" % _current_reroll_cost()

func _current_reroll_cost() -> int:
	return reroll_cost + reroll_count

func _pick_random_offer(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var preferred_family := _get_preferred_weapon_family()
	var preferred_family_bias := _get_preferred_weapon_family_bias()
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
			var rolled_rarity := _roll_weapon_rarity_for_wave(_current_wave_index)
			var base_price := int(offer.get("base_price", int(offer.get("price", 0))))
			var scaled_price := _scaled_weapon_price(base_price, rolled_rarity)
			offer["rolled_rarity"] = rolled_rarity
			offer["final_price"] = scaled_price
			offer["price"] = scaled_price
		return offer
	return {}

func _get_preferred_weapon_family() -> String:
	if player != null and player.has_method("get_preferred_weapon_family_id"):
		return str(player.call("get_preferred_weapon_family_id"))
	return ""

func _get_preferred_weapon_family_bias() -> float:
	if player != null and player.has_method("get_shop_weapon_family_bias"):
		return maxf(float(player.call("get_shop_weapon_family_bias")), 0.0)
	return 0.0

func _find_item_data(item_id: String) -> ItemData:
	for item in ItemDatabase.get_prototype_items():
		if item != null and item.id == item_id:
			return item
	return null

func _sold_out_offer() -> Dictionary:
	return {"type": "sold_out", "id": "", "label": "Sold Out", "price": 0}

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

func _on_continue_pressed() -> void:
	if panel != null:
		panel.visible = false
	shop_closed.emit()
	continue_requested.emit()

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "ShopController")

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
