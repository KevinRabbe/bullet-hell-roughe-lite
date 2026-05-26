extends Node

@export var enemy_spawner_path: NodePath
@export var player_path: NodePath
@export var panel_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var reroll_button_path: NodePath
@export var continue_button_path: NodePath
@export var reroll_cost: int = 1

var enemy_spawner: Node
var player: Node
var panel: Control
var offer_buttons: Array[Button] = []
var reroll_button: Button
var continue_button: Button
var reroll_count: int = 0
var rng: RandomNumberGenerator
var offer_pool := [
	{"type": "weapon", "id": "heavy_pistol", "label": "Heavy Pistol (Weapon)"},
	{"type": "weapon", "id": "gunslinger_smg", "label": "SMG (Weapon)"},
	{"type": "stat", "id": "damage", "value": 0.2, "label": "+20% Damage"},
	{"type": "stat", "id": "attack_speed", "value": 0.2, "label": "+20% Attack Speed"},
	{"type": "stat", "id": "movement_speed", "value": 25.0, "label": "+25 Move Speed"},
	{"type": "stat", "id": "max_hp", "value": 20.0, "label": "+20 Max HP"}
]
var active_offers: Array = []

func _ready() -> void:
	rng = RunRng.get_rng("shop")
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if panel_path != NodePath():
		panel = get_node_or_null(panel_path)
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

func _on_wave_completed(_wave_index: int) -> void:
	reroll_count = 0
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()
	if panel != null:
		panel.visible = true
	print("Shop opened with %d offers." % active_offers.size())

func _roll_offers() -> void:
	active_offers.clear()
	var pool_copy: Array = offer_pool.duplicate(true)
	for _idx in 4:
		if pool_copy.is_empty():
			break
		var pick_index := rng.randi_range(0, pool_copy.size() - 1)
		active_offers.append(pool_copy[pick_index])
		pool_copy.remove_at(pick_index)

func _refresh_offer_buttons() -> void:
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		if index < active_offers.size():
			button.text = str(active_offers[index].get("label", "Offer"))
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
	if str(offer.get("type", "")) == "weapon":
		if player.has_method("_debug_add_gunslinger_weapon_by_id"):
			player.call("_debug_add_gunslinger_weapon_by_id", str(offer.get("id", "")))
	elif str(offer.get("type", "")) == "stat":
		if player.has_method("_debug_add_stat_bonus"):
			player.call("_debug_add_stat_bonus", str(offer.get("id", "")), float(offer.get("value", 0.0)))
	print("Bought offer: %s" % str(offer.get("label", "Offer")))
	for button in offer_buttons:
		button.disabled = true

func _on_reroll_pressed() -> void:
	reroll_count += 1
	var total_cost := reroll_cost * reroll_count
	print("Reroll shop offers. Cost (debug): %d" % total_cost)
	_roll_offers()
	_refresh_offer_buttons()
	_update_reroll_button_text()

func _update_reroll_button_text() -> void:
	if reroll_button == null:
		return
	var next_cost := reroll_cost * (reroll_count + 1)
	reroll_button.text = "Reroll (Cost: %d)" % next_cost

func _on_continue_pressed() -> void:
	if panel != null:
		panel.visible = false
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")
