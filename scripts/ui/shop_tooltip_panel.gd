extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const StandardTooltipScene = preload("res://scenes/ui/components/StandardTooltip.tscn")

@export var shop_controller_path: NodePath
@export var player_path: NodePath
@export var offer_button_paths: Array[NodePath] = []
@export var tooltip_panel_path: NodePath
@export var tooltip_title_path: NodePath
@export var tooltip_body_path: NodePath

var shop_controller: Node
var player: Node
var offer_buttons: Array[Button] = []
var tooltip_panel: Control
var tooltip_title: Label
var tooltip_body: Label
var _weapon_data_cache: Dictionary = {}

func _ready() -> void:
	_upgrade_tooltip_to_standard_component()
	if shop_controller_path != NodePath():
		shop_controller = get_node_or_null(shop_controller_path)
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if tooltip_panel_path != NodePath():
		tooltip_panel = get_node_or_null(tooltip_panel_path) as Control
	_resolve_tooltip_labels()
	for button_path in offer_button_paths:
		var button := get_node_or_null(button_path)
		if button is Button:
			offer_buttons.append(button)
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		button.mouse_entered.connect(_on_offer_hovered.bind(index))
		button.mouse_exited.connect(_hide_tooltip)
	_apply_presentation()
	_hide_tooltip()

func _upgrade_tooltip_to_standard_component() -> void:
	if tooltip_panel_path == NodePath():
		return
	var existing := get_node_or_null(tooltip_panel_path) as Control
	if existing == null or existing.has_method("show_at"):
		return
	var parent := existing.get_parent()
	if parent == null:
		return
	var insert_index := existing.get_index()
	var tooltip_variant: Variant = StandardTooltipScene.instantiate()
	if not (tooltip_variant is Control):
		return
	var standard_tooltip := tooltip_variant as Control
	standard_tooltip.name = existing.name
	standard_tooltip.position = existing.position
	standard_tooltip.visible = existing.visible
	parent.remove_child(existing)
	existing.queue_free()
	parent.add_child(standard_tooltip)
	parent.move_child(standard_tooltip, insert_index)

func _resolve_tooltip_labels() -> void:
	if tooltip_panel != null and tooltip_panel.has_method("get_title_label"):
		tooltip_title = tooltip_panel.call("get_title_label") as Label
		tooltip_body = tooltip_panel.call("get_body_label") as Label
		return
	if tooltip_title_path != NodePath():
		tooltip_title = get_node_or_null(tooltip_title_path) as Label
	if tooltip_body_path != NodePath():
		tooltip_body = get_node_or_null(tooltip_body_path) as Label

func _apply_presentation() -> void:
	if tooltip_panel != null and tooltip_panel.has_method("configure"):
		return
	InfernalUiStyleRef.apply_panel(tooltip_panel, InfernalUiStyleRef.PANEL_TOOLTIP)
	InfernalUiStyleRef.apply_text_role(tooltip_title, InfernalUiStyleRef.TEXT_CARD_TITLE)
	InfernalUiStyleRef.apply_text_role(tooltip_body, InfernalUiStyleRef.TEXT_BODY)

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
	if tooltip_panel != null and tooltip_panel.has_method("configure"):
		tooltip_panel.call("configure", title, body)
	elif tooltip_title != null and tooltip_body != null:
		tooltip_title.text = title
		tooltip_body.text = body
	if tooltip_panel != null:
		var mouse := get_viewport().get_mouse_position()
		if tooltip_panel.has_method("show_at"):
			tooltip_panel.call("show_at", mouse)
		else:
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
	var sections: Array[String] = [
		"Family: %s" % family,
		"Tags: %s" % tags_text,
		weapon_data.description
	]
	var player_snapshot := _get_player_snapshot()
	var passive_lines := _build_passive_weapon_synergy_lines(weapon_data, player_snapshot)
	if not passive_lines.is_empty():
		sections.append("Passive Synergy:\n%s" % "\n".join(passive_lines))
	var set_bonus_lines := _build_set_bonus_weapon_synergy_lines(weapon_data, player_snapshot)
	if not set_bonus_lines.is_empty():
		sections.append("Set Bonus Synergy:\n%s" % "\n".join(set_bonus_lines))
	var item_bonus_lines := _build_owned_item_weapon_bonus_lines(weapon_data, player_snapshot)
	if not item_bonus_lines.is_empty():
		sections.append("Owned Item Synergy:\n%s" % "\n".join(item_bonus_lines))
	return "\n".join(sections)

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

func _build_owned_item_weapon_bonus_lines(weapon_data: WeaponData, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var items_variant: Variant = player_snapshot.get("items", [])
	if not (items_variant is Array):
		return lines
	var weapon_tag_set: Dictionary = {}
	for tag in WeaponTagRuntime.weapon_tags(weapon_data):
		weapon_tag_set[tag] = true
	for item_variant in items_variant:
		if not (item_variant is ItemData):
			continue
		var item := item_variant as ItemData
		var matched_bonus_parts: Array[String] = []
		for rule_variant in item.weapon_tag_stat_bonuses:
			if not (rule_variant is Dictionary):
				continue
			var rule: Dictionary = rule_variant
			var rule_tag := WeaponTagRuntime.normalize_tag(str(rule.get("tag", "")))
			if rule_tag == "" or weapon_tag_set.get(rule_tag, false) != true:
				continue
			var stat_id := str(rule.get("stat_id", ""))
			if stat_id == "":
				continue
			var amount := float(rule.get("amount", 0.0))
			if is_zero_approx(amount):
				continue
			matched_bonus_parts.append("%s %s" % [rule_tag, _format_stat_bonus(stat_id, amount)])
		if not matched_bonus_parts.is_empty():
			lines.append("- %s: %s" % [item.name, ", ".join(matched_bonus_parts)])
	return lines

func _build_passive_weapon_synergy_lines(weapon_data: WeaponData, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var passive_rules_variant: Variant = player_snapshot.get("passive_weapon_synergies", [])
	if not (passive_rules_variant is Array):
		return lines
	var passive_rules: Array = passive_rules_variant
	for passive_rule_variant in passive_rules:
		if not (passive_rule_variant is Dictionary):
			continue
		var passive_rule: Dictionary = passive_rule_variant
		if not WeaponTagRuntime.weapon_matches_effect_tags(weapon_data, passive_rule):
			continue
		var effect_tags := WeaponTagRuntime.resolve_effect_tags(passive_rule.get("effect_tags", []))
		var stat_id := str(passive_rule.get("stat_id", ""))
		var amount := float(passive_rule.get("amount", 0.0))
		if effect_tags.is_empty() or stat_id == "" or is_zero_approx(amount):
			continue
		lines.append("- %s: %s via %s" % [str(passive_rule.get("label", "Passive")), _format_stat_bonus(stat_id, amount), ", ".join(effect_tags)])
	return lines

func _build_set_bonus_weapon_synergy_lines(weapon_data: WeaponData, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var set_bonus_rules_variant: Variant = player_snapshot.get("set_bonus_weapon_synergies", [])
	if not (set_bonus_rules_variant is Array):
		return lines
	var set_bonus_rules: Array = set_bonus_rules_variant
	for set_bonus_rule_variant in set_bonus_rules:
		if not (set_bonus_rule_variant is Dictionary):
			continue
		var set_bonus_rule: Dictionary = set_bonus_rule_variant
		if not WeaponTagRuntime.weapon_matches_effect_tags(weapon_data, set_bonus_rule):
			continue
		var effect_tags := WeaponTagRuntime.resolve_effect_tags(set_bonus_rule.get("effect_tags", []))
		var stat_id := str(set_bonus_rule.get("stat_id", ""))
		var amount := float(set_bonus_rule.get("amount", 0.0))
		if effect_tags.is_empty() or stat_id == "" or is_zero_approx(amount):
			continue
		lines.append("- %s: %s via %s" % [str(set_bonus_rule.get("label", "Set bonus")), _format_stat_bonus(stat_id, amount), ", ".join(effect_tags)])
	return lines

func _format_stat_bonus(stat_id: String, amount: float) -> String:
	match stat_id:
		"attack_speed", "attack_range", "projectile_speed", "damage":
			return "%+.0f%% %s" % [amount * 100.0, stat_id.replace("_", " ")]
		_:
			return "%+.2f %s" % [amount, stat_id.replace("_", " ")]

func _hide_tooltip() -> void:
	if tooltip_panel == null:
		return
	if tooltip_panel.has_method("hide_tooltip"):
		tooltip_panel.call("hide_tooltip")
	else:
		tooltip_panel.visible = false

func _get_player_snapshot() -> Dictionary:
	if player != null and player.has_method("get_ui_snapshot"):
		var snapshot_variant: Variant = player.call("get_ui_snapshot")
		if snapshot_variant is Dictionary:
			return snapshot_variant
	return {}

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
