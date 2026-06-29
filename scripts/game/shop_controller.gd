extends Node

signal continue_requested
signal shop_opened(wave_index: int)
signal shop_closed
signal offers_changed
signal reroll_cost_changed(new_cost: int)
signal offer_purchased(index: int, offer: Dictionary)

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const ShopOfferRuntime = preload("res://scripts/game/shop_offer_runtime.gd")

@export var enemy_spawner_path: NodePath
@export var player_path: NodePath
@export var panel_path: NodePath
@export var title_label_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var reroll_button_path: NodePath
@export var continue_button_path: NodePath
@export var reroll_cost: int = 2
@export var enabled: bool = false

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
	_resolve_references()
	_connect_buttons()
	_initialize_panel_state()

func _resolve_references() -> void:
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

func _connect_buttons() -> void:
	for index in offer_buttons.size():
		offer_buttons[index].pressed.connect(_on_offer_pressed.bind(index))
	if reroll_button != null:
		reroll_button.pressed.connect(_on_reroll_pressed)
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)

func _initialize_panel_state() -> void:
	if panel != null:
		panel.visible = false
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)

func _build_weapon_offer_pool() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	_weapon_offer_pool = ShopOfferRuntime.build_weapon_offer_pool(
		data_registry,
		Callable(self, "_load_weapon_data")
	)

func _build_item_offer_pool() -> void:
	_item_offer_pool = ShopOfferRuntime.build_item_offer_pool()

func _on_wave_completed(wave_index: int) -> void:
	if not enabled:
		return
	_current_wave_index = maxi(wave_index, 1)
	reroll_count = 0
	_open_shop_for_wave()
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
	active_offers = ShopOfferRuntime.roll_offers(
		_weapon_offer_pool,
		_item_offer_pool,
		_current_wave_index,
		rng,
		_get_preferred_weapon_family(),
		_get_preferred_weapon_family_bias()
	)

func _refresh_offer_buttons() -> void:
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		if index < active_offers.size():
			_apply_offer_button_state(button, active_offers[index])
		else:
			_apply_empty_offer_button_state(button)

func _apply_offer_button_state(button: Button, offer: Dictionary) -> void:
	var offer_type := str(offer.get("type", ""))
	if offer_type == "sold_out":
		button.text = "Sold Out"
		button.disabled = true
		return
	button.text = _build_offer_button_text(offer)
	button.disabled = false

func _apply_empty_offer_button_state(button: Button) -> void:
	button.text = "N/A"
	button.disabled = true

func _build_offer_button_text(offer: Dictionary) -> String:
	var rarity_badge := ""
	var offer_type := str(offer.get("type", ""))
	if offer_type == "weapon":
		rarity_badge = "[%s] " % str(offer.get("rolled_rarity", "common")).capitalize()
	return "%s%s (%dG)" % [
		rarity_badge,
		str(offer.get("label", "Offer")),
		int(offer.get("price", 0))
	]

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

	if not _can_purchase_offer(offer_type, offer_id, offer):
		return

	if player.has_method("spend_gold"):
		var paid: bool = player.call("spend_gold", offer_price) == true
		if not paid:
			return

	if not _grant_purchased_offer(offer_type, offer_id, offer, offer_price):
		return

	print("Bought: %s for %dG" % [str(offer.get("label", "Offer")), offer_price])
	active_offers[index] = ShopOfferRuntime.sold_out_offer()
	_refresh_offer_buttons()
	offer_purchased.emit(index, offer.duplicate(true))
	offers_changed.emit()

func _can_purchase_offer(offer_type: String, offer_id: String, offer: Dictionary) -> bool:
	if offer_type != "weapon":
		return true
	var loadout: Node = player.get_node_or_null("WeaponLoadout")
	var rolled_rarity := str(offer.get("rolled_rarity", "common"))
	if loadout == null:
		return true
	if loadout.has_method("can_grant_weapon"):
		if loadout.call("can_grant_weapon", offer_id, rolled_rarity) != true:
			print("Cannot buy weapon. No loadout slot or combine upgrade available for %s." % offer_id)
			return false
	elif loadout.has_method("has_space") and loadout.call("has_space") != true:
		print("Cannot buy weapon. Weapon loadout is full.")
		return false
	return true

func _grant_purchased_offer(offer_type: String, offer_id: String, offer: Dictionary, offer_price: int) -> bool:
	if offer_type == "weapon":
		return _grant_purchased_weapon(offer_id, str(offer.get("rolled_rarity", "common")), offer_price)
	if offer_type == "item":
		return _grant_purchased_item(offer_id, offer_price)
	return true

func _grant_purchased_weapon(weapon_id: String, rolled_rarity: String, offer_price: int) -> bool:
	if not player.has_method("grant_weapon"):
		return false
	var granted: bool = player.call("grant_weapon", weapon_id, rolled_rarity) == true
	if granted:
		return true
	if player.has_method("add_gold"):
		player.call("add_gold", offer_price)
	print("Weapon purchase rejected: %s" % weapon_id)
	return false

func _grant_purchased_item(item_id: String, offer_price: int) -> bool:
	var item_data := _find_item_data(item_id)
	if item_data != null and player.has_method("grant_item"):
		player.call("grant_item", item_data)
		return true
	if player.has_method("add_gold"):
		player.call("add_gold", offer_price)
	print("Item purchase failed: %s" % item_id)
	return false

func _on_reroll_pressed() -> void:
	var total_cost := _current_reroll_cost()
	if player != null and is_instance_valid(player) and player.has_method("spend_gold"):
		var paid: bool = player.call("spend_gold", total_cost) == true
		if not paid:
			return
	reroll_count += 1
	print("Reroll shop. Cost: %d" % total_cost)
	_refresh_shop_offers()

func _update_reroll_button_text() -> void:
	if reroll_button == null:
		return
	reroll_button.text = "Reroll (%dG)" % _current_reroll_cost()

func _current_reroll_cost() -> int:
	var config := ShopOfferRuntime.get_shop_config()
	var base_cost := int(config.get("base_reroll_cost", reroll_cost))
	var reroll_step := int(config.get("reroll_cost_step", 1))
	return base_cost + (reroll_count * reroll_step)

func _open_shop_for_wave() -> void:
	_refresh_shop_offers()
	if title_label != null:
		title_label.text = "Shop - Pick one"
	if panel != null:
		panel.visible = true
	shop_opened.emit(_current_wave_index)

func _refresh_shop_offers() -> void:
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()
	offers_changed.emit()
	reroll_cost_changed.emit(_current_reroll_cost())

func _get_preferred_weapon_family() -> String:
	if _player_has_method("get_preferred_weapon_family_id"):
		return str(player.call("get_preferred_weapon_family_id"))
	return ""

func _get_preferred_weapon_family_bias() -> float:
	if _player_has_method("get_shop_weapon_family_bias"):
		return maxf(float(player.call("get_shop_weapon_family_bias")), 0.0)
	return 0.0

func _find_item_data(item_id: String) -> ItemData:
	return _find_item_data_in_pool(ItemDatabase.get_prototype_items(), item_id)

func _find_item_data_in_pool(items: Array, item_id: String) -> ItemData:
	for item in items:
		if item != null and item.id == item_id:
			return item
	return null

func _player_has_method(method_name: StringName) -> bool:
	return player != null and player.has_method(method_name)

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

func _load_weapon_data_by_id(weapon_id: String) -> WeaponData:
	return _load_weapon_data("res://data/weapons/%s.tres" % weapon_id)
