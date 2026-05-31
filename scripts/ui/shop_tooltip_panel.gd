extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")

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
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		return "No WeaponData found."
	var weapon_data := load(resource_path) as WeaponData
	if weapon_data == null:
		return "No WeaponData found."
	var family := weapon_data.family
	if family == "":
		family = weapon_data.family_id
	var tags_text := ", ".join(weapon_data.tags)
	if tags_text == "":
		tags_text = "-"
	return "Family: %s\nTags: %s\n%s" % [family, tags_text, weapon_data.description]

func _build_item_tooltip(item_id: String) -> String:
	for item in ItemDatabase.get_prototype_items():
		if item != null and item.id == item_id:
			return item.description
	return "No ItemData found."

func _hide_tooltip() -> void:
	if tooltip_panel != null:
		tooltip_panel.visible = false
