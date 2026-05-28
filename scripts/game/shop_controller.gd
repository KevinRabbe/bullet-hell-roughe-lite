extends Node
signal continue_requested

@export var enemy_spawner_path: NodePath
@export var player_path: NodePath
@export var panel_path: NodePath
@export var title_label_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var reroll_button_path: NodePath
@export var continue_button_path: NodePath
@export var reroll_cost: int = 2
@export var enabled: bool = false

# Weapon IDs available in the shop pool. Prices/names read from WeaponData.
const SHOP_WEAPON_IDS: Array[String] = [
	"heavy_pistol",
	"gunslinger_smg",
	"gunslinger_shotgun",
	"gunslinger_revolver",
	"gunslinger_assault_rifle",
	"gunslinger_sniper_rifle",
]

# Stat offers stay hardcoded until StatData resources exist.
const STAT_OFFER_POOL: Array[Dictionary] = [
	{"type": "stat", "id": "damage", "value": 0.2, "label": "+20% Damage", "price": 3},
	{"type": "stat", "id": "attack_speed", "value": 0.2, "label": "+20% Attack Speed", "price": 3},
	{"type": "stat", "id": "movement_speed", "value": 25.0, "label": "+25 Move Speed", "price": 3},
	{"type": "stat", "id": "max_hp", "value": 20.0, "label": "+20 Max HP", "price": 3},
]

var enemy_spawner: Node
var player: Node
var panel: Control
var title_label: Label
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var reroll_count: int = 0
var rng: RandomNumberGenerator
var _weapon_offer_pool: Array[Dictionary] = []
var active_offers: Array[Dictionary] = []

func _ready() -> void:
	rng = _resolve_rng("shop")
	_build_weapon_offer_pool()
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
	for weapon_id in SHOP_WEAPON_IDS:
		var offer := _make_weapon_offer(weapon_id)
		if not offer.is_empty():
			_weapon_offer_pool.append(offer)

func _make_weapon_offer(weapon_id: String) -> Dictionary:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return {}
	var data := load(resource_path)
	var display_name: String = weapon_id.replace("_", " ").capitalize()
	var price: int = 5
	if data != null:
		if "display_name" in data and str(data.display_name) != "":
			display_name = str(data.display_name)
		if "price" in data and int(data.price) > 0:
			price = int(data.price)
	return {"type": "weapon", "id": weapon_id, "label": display_name, "price": price}

func _on_wave_completed(_wave_index: int) -> void:
	if not enabled:
		return
	reroll_count = 0
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()
	if title_label != null:
		title_label.text = "Shop — Pick one"
	if panel != null:
		panel.visible = true
	print("Shop opened with %d offers." % active_offers.size())

func _roll_offers() -> void:
	active_offers.clear()
	# Slots 1 & 2: guaranteed weapons
	for _slot in 2:
		var offer := _pick_random_offer(_weapon_offer_pool)
		if not offer.is_empty():
			active_offers.append(offer)
	# Slots 3 & 4: random (weapon or stat)
	var combined_pool: Array = _weapon_offer_pool.duplicate()
	for s in STAT_OFFER_POOL:
		combined_pool.append(s)
	for _slot in 2:
		var offer := _pick_random_offer(combined_pool)
		if not offer.is_empty():
			active_offers.append(offer)

func _refresh_offer_buttons() -> void:
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		if index < active_offers.size():
			var offer: Dictionary = active_offers[index]
			var price := int(offer.get("price", 0))
			button.text = "%s (%dG)" % [str(offer.get("label", "Offer")), price]
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
	var offer_price := int(offer.get("price", 0))
	var offer_type := str(offer.get("type", ""))
	var offer_id := str(offer.get("id", ""))

	if offer_type == "weapon":
		var loadout: Node = player.get_node_or_null("WeaponLoadout") if player.has_method("get_node_or_null") else null
		if loadout != null and loadout.has_method("has_space") and not bool(loadout.call("has_space")):
			print("Cannot buy weapon. Weapon loadout is full.")
			return

	if player.has_method("spend_gold"):
		var paid: bool = bool(player.call("spend_gold", offer_price))
		if not paid:
			return

	if offer_type == "weapon":
		if player.has_method("grant_weapon"):
			player.call("grant_weapon", offer_id)
	elif offer_type == "stat":
		if player.has_method("_debug_add_stat_bonus"):
			player.call("_debug_add_stat_bonus", offer_id, float(offer.get("value", 0.0)))

	print("Bought: %s for %dG" % [str(offer.get("label", "Offer")), offer_price])
	active_offers.remove_at(index)
	_refresh_offer_buttons()

func _on_reroll_pressed() -> void:
	var total_cost := _current_reroll_cost()
	if player != null and is_instance_valid(player) and player.has_method("spend_gold"):
		var paid: bool = bool(player.call("spend_gold", total_cost))
		if not paid:
			return
	reroll_count += 1
	print("Reroll shop. Cost: %d" % total_cost)
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()

func _update_reroll_button_text() -> void:
	if reroll_button == null:
		return
	reroll_button.text = "Reroll (%dG)" % _current_reroll_cost()

func _current_reroll_cost() -> int:
	return reroll_cost + reroll_count

func _pick_random_offer(pool: Array) -> Dictionary:
	if pool.is_empty():
		return {}
	var index := rng.randi_range(0, pool.size() - 1)
	var selected: Variant = pool[index]
	if selected is Dictionary:
		return (selected as Dictionary).duplicate(true)
	return {}

func _on_continue_pressed() -> void:
	if panel != null:
		panel.visible = false
	continue_requested.emit()

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
