extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeaponTagRuntime = preload("res://scripts/weapons/weapon_tag_runtime.gd")

@export var shop_controller_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var tooltip_panel_path: NodePath
@export var tooltip_title_path: NodePath
@export var tooltip_body_path: NodePath

var shop_controller: Node
var offer_buttons: Array[Button] = []
var tooltip_panel: Panel
var tooltip_title: Label
var tooltip_body: Label
var _weapon_data_cache: Dictionary = {}

func _ready() -> void:
	if shop_controller_path != NodePath():
		shop_controller = get_node_or_null(shop_controller_path)
	if tooltip_panel_path != NodePath():
		tooltip_panel = get_node_or_null(tooltip_panel_path)
	if tooltip_title_path != NodePath():
		tooltip_title = get_node_or_null(tooltip_title_path)
	if tooltip_body_path != NodePath():
		tooltip_body = get_node_or_null(tooltip_body_path)
	for button_path in offer_button_paths:
		var button := get_node_or_null(button_path)
		if button is Button:
			offer_buttons.append(button)
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		button.mouse_entered.connect(_on_offer_hovered.bind(index))
		button.mouse_exited.connect(_hide_tooltip)
	if tooltip_panel != null:
		tooltip_panel.visible = false

func _on_offer_hovered(index: int) -> void:
	var offer := _get_offer(index)
	if offer.is_empty():
		_hide_tooltip()
		return
	var offer_type := str(offer.get("type", ""))
	if offer_type == "sold_out":
		_hide_tooltip()
		return
	var title := str(offer.get("label", "Offer"))
	var body := ""
	if offer_type == "weapon":
		body = _build_weapon_tooltip(str(offer.get("id", "")))
	elif offer_type == "item":
		body = _build_item_tooltip(str(offer.get("id", "")))
	if tooltip_title != null:
		tooltip_title.text = title
	if tooltip_body != null:
		tooltip_body.text = body
	if tooltip_panel != null:
		var mouse := get_viewport().get_mouse_position()
		tooltip_panel.position = mouse + Vector2(16.0, 16.0)
		tooltip_panel.visible = true

func _get_offer(index: int) -> Dictionary:
	if shop_controller == null:
		return {}
	var offers_variant: Variant = shop_controller.get("active_offers")
	if not (offers_variant is Array):
		return {}
	var offers: Array = offers_variant
	if index < 0 or index >= offers.size():
		return {}
	if offers[index] is Dictionary:
		return offers[index]
	return {}

func _build_weapon_tooltip(weapon_id: String) -> String:
	var weapon_data := _load_weapon_data(weapon_id)
	if weapon_data == null:
		return "No WeaponData found."
	var family := weapon_data.get_family_value() if weapon_data.has_method("get_family_value") else weapon_data.family
	var tags_text := ", ".join(weapon_data.tags)
	if tags_text == "":
		tags_text = "-"
	return "Family: %s\nTags: %s\n%s" % [family, tags_text, weapon_data.description]

func _build_item_tooltip(item_id: String) -> String:
	var item := ItemDatabase.get_item_by_id(item_id)
	if item != null:
		return _format_item_tooltip(item)
	return "No ItemData found."

func _format_item_tooltip(item: ItemData) -> String:
	var sections: Array[String] = []
	var item_tags := WeaponTagRuntime.item_tags(item)
	var tags_text := ", ".join(item_tags)
	if tags_text == "":
		tags_text = "-"
	sections.append("Tags: %s" % tags_text)
	sections.append(item.description)
	var bonus_lines := _build_item_weapon_tag_bonus_lines(item)
	if not bonus_lines.is_empty():
		sections.append("Weapon Tag Bonuses:\n%s" % "\n".join(bonus_lines))
	return "\n".join(sections)

func _build_item_weapon_tag_bonus_lines(item: ItemData) -> Array[String]:
	var lines: Array[String] = []
	for rule_variant in item.weapon_tag_stat_bonuses:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var tag := WeaponTagRuntime.normalize_tag(str(rule.get("tag", "")))
		var stat_id := str(rule.get("stat_id", ""))
		if tag == "" or stat_id == "":
			continue
		var amount := float(rule.get("amount", 0.0))
		if is_zero_approx(amount):
			continue
		lines.append("- %s: %s" % [tag, _format_stat_bonus(stat_id, amount)])
	return lines

func _format_stat_bonus(stat_id: String, amount: float) -> String:
	match stat_id:
		"attack_speed", "attack_range", "projectile_speed", "damage":
			return "%+.0f%% %s" % [amount * 100.0, stat_id.replace("_", " ")]
		_:
			return "%+.2f %s" % [amount, stat_id.replace("_", " ")]

func _hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false

func _load_weapon_data(weapon_id: String) -> WeaponData:
	if weapon_id == "":
		return null
	if _weapon_data_cache.has(weapon_id):
		return _weapon_data_cache[weapon_id] as WeaponData
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path) as WeaponData
	if loaded != null:
		_weapon_data_cache[weapon_id] = loaded
	return loaded
