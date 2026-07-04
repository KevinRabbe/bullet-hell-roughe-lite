class_name ShopViewModel
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")

var shop_controller: Node
var player: Node
var weapon_loadout: Node
var _weapon_cache: Dictionary = {}

func configure(shop_controller_node: Node, player_node: Node, weapon_loadout_node: Node) -> void:
	shop_controller = shop_controller_node
	player = player_node
	weapon_loadout = weapon_loadout_node

func get_snapshot() -> Dictionary:
	var player_snapshot := _get_player_snapshot()
	var offers := _get_offers()
	return _build_snapshot(player_snapshot, offers)

func _build_snapshot(player_snapshot: Dictionary, offers: Array[Dictionary]) -> Dictionary:
	var wave_index := _get_wave_index()
	return {
		"wave_index": wave_index,
		"gold": _get_snapshot_gold(player_snapshot),
		"reroll_cost": _get_reroll_cost(),
		"title": _build_shop_title(wave_index),
		"offers": offers,
		"offer_cards": _build_offer_cards(offers),
		"items_text": _get_items_text(player_snapshot),
		"weapon_count": _get_weapon_count(),
		"weapon_entries": _get_weapon_entries(player_snapshot),
		"weapon_slots": _build_weapon_slots(player_snapshot),
		"stats_text": _get_stats_text(player_snapshot),
		"is_shop_open": _is_shop_open()
	}

func _get_snapshot_gold(player_snapshot: Dictionary) -> int:
	return int(player_snapshot.get("gold", _get_gold()))

func _build_shop_title(wave_index: int) -> String:
	return "Shop (Wave %d)" % wave_index

func get_weapon_offer_block_reason(weapon_id: String, incoming_rarity: String = "common") -> String:
	if player == null:
		return "Need empty slot or valid same-rarity merge."
	var loadout: Node = player.get_node_or_null("WeaponLoadout")
	if loadout == null:
		return "Need empty slot or valid same-rarity merge."
	if loadout.has_method("get_grant_block_reason"):
		var reason := str(loadout.call("get_grant_block_reason", weapon_id, incoming_rarity))
		if reason != "":
			return reason
	return "Need empty slot or valid same-rarity merge."

func get_merge_slot_state(slot_index: int) -> Dictionary:
	if slot_index < 0:
		return {"state": "merge_blocked", "can_merge": false, "message": "Select weapon"}
	if weapon_loadout != null and weapon_loadout.has_method("get_merge_slot_state"):
		var state_variant: Variant = weapon_loadout.call("get_merge_slot_state", slot_index)
		if state_variant is Dictionary:
			return (state_variant as Dictionary).duplicate(true)
	var fallback_can_merge := false
	if weapon_loadout != null and weapon_loadout.has_method("can_merge_slot"):
		fallback_can_merge = weapon_loadout.call("can_merge_slot", slot_index) == true
	return {
		"state": "merge_available" if fallback_can_merge else "merge_blocked",
		"can_merge": fallback_can_merge,
		"message": "Merge selected" if fallback_can_merge else "No valid merge"
	}

func _get_wave_index() -> int:
	if shop_controller != null and shop_controller.has_method("get_current_wave_index"):
		return int(shop_controller.call("get_current_wave_index"))
	return 1

func _get_gold() -> int:
	return int(_get_player_property("current_gold", 0))

func _get_reroll_cost() -> int:
	if shop_controller != null and shop_controller.has_method("get_current_reroll_cost"):
		return int(shop_controller.call("get_current_reroll_cost"))
	return 0

func _get_offers() -> Array[Dictionary]:
	if shop_controller != null and shop_controller.has_method("get_active_offers"):
		var offers_variant: Variant = shop_controller.call("get_active_offers")
		if offers_variant is Array:
			var copied: Array[Dictionary] = []
			for offer in offers_variant:
				if offer is Dictionary:
					copied.append((offer as Dictionary).duplicate(true))
			return copied
	return []

func _get_items_text(player_snapshot: Dictionary) -> String:
	var items_variant: Variant = player_snapshot.get("items", null)
	if items_variant == null and player != null:
		items_variant = _get_player_property("owned_items", null)
	if items_variant == null:
		return "None"
	if not (items_variant is Array):
		return "None"
	var lines := _build_item_lines(items_variant)
	if lines.is_empty():
		return "None"
	return "\n".join(lines)

func _build_item_lines(items_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if items_variant == null or not (items_variant is Array):
		return lines
	for item_variant in items_variant:
		if item_variant is ItemData:
			var item := item_variant as ItemData
			lines.append("- %s" % item.name)
	return lines

func _get_weapon_count() -> int:
	var entries := _get_weapon_entries()
	var count := 0
	for entry in entries:
		if str(entry.get("id", "")) != "":
			count += 1
	return count

func _get_weapon_entries(player_snapshot: Dictionary = {}) -> Array[Dictionary]:
	var snapshot_entries_variant: Variant = player_snapshot.get("weapon_entries", [])
	if snapshot_entries_variant is Array:
		var snapshot_entries: Array[Dictionary] = []
		for entry_variant in snapshot_entries_variant:
			if entry_variant is Dictionary:
				snapshot_entries.append((entry_variant as Dictionary).duplicate(true))
		if not snapshot_entries.is_empty():
			return snapshot_entries
	if weapon_loadout != null and weapon_loadout.has_method("get_weapon_entries"):
		var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
		if entries_variant is Array:
			var copied: Array[Dictionary] = []
			for entry_variant in entries_variant:
				if entry_variant is Dictionary:
					copied.append((entry_variant as Dictionary).duplicate(true))
			return copied
	return []

func _build_offer_cards(offers: Array[Dictionary]) -> Array[Dictionary]:
	var cards: Array[Dictionary] = []
	var player_snapshot := _get_player_snapshot()
	for offer in offers:
		var card := _create_offer_card_base(offer)
		var offer_type := str(offer.get("type", ""))
		if offer_type == "sold_out":
			_apply_sold_out_card(card)
		elif offer_type == "weapon":
			var weapon_id := str(offer.get("id", ""))
			var weapon_data := _load_weapon_data(weapon_id)
			_apply_weapon_offer_card(card, offer, weapon_data, player_snapshot)
		elif offer_type == "item":
			_apply_item_offer_card(card, offer, player_snapshot)
		cards.append(card)
	return cards

func _create_offer_card_base(offer: Dictionary) -> Dictionary:
	return {
		"title": str(offer.get("label", "Offer")),
		"type_label": str(offer.get("type", "")).capitalize(),
		"description": "",
		"button_text": "%dG" % int(offer.get("price", 0)),
		"button_disabled": false,
		"kind": str(offer.get("type", "")),
		"block_reason": ""
	}

func _apply_sold_out_card(card: Dictionary) -> void:
	card["type_label"] = "Sold Out"
	card["description"] = "[color=gray]Already purchased.[/color]"
	card["button_text"] = "Sold Out"
	card["button_disabled"] = true

func _apply_weapon_offer_card(card: Dictionary, offer: Dictionary, weapon_data: WeaponData, player_snapshot: Dictionary) -> void:
	var weapon_id := str(offer.get("id", ""))
	card["description"] = _build_weapon_offer_description(offer, weapon_data, player_snapshot)
	if _can_buy_weapon_offer(offer):
		return
	card["button_text"] = "Blocked"
	card["button_disabled"] = true
	card["block_reason"] = get_weapon_offer_block_reason(weapon_id, _get_offer_weapon_rarity(offer, weapon_data))

func _apply_item_offer_card(card: Dictionary, offer: Dictionary, player_snapshot: Dictionary) -> void:
	card["description"] = _build_item_offer_description(str(offer.get("id", "")), player_snapshot)

func _build_weapon_slots(player_snapshot: Dictionary = {}) -> Array[Dictionary]:
	var entries := _get_weapon_entries(player_snapshot)
	var slots: Array[Dictionary] = []
	for index in range(6):
		if index < entries.size():
			slots.append(_build_occupied_weapon_slot(entries[index]))
		else:
			slots.append(_build_empty_weapon_slot())
	return slots

func _build_occupied_weapon_slot(entry: Dictionary) -> Dictionary:
	var weapon_id := str(entry.get("id", ""))
	var rarity := str(entry.get("rarity", "common"))
	var weapon_data := _load_weapon_data(weapon_id)
	return {
		"id": weapon_id,
		"rarity": rarity,
		"icon": weapon_data.icon if weapon_data != null else null,
		"label": _build_weapon_slot_label(entry, weapon_data, weapon_id, rarity),
		"occupied": weapon_id != ""
	}

func _build_empty_weapon_slot() -> Dictionary:
	return {
		"id": "",
		"rarity": "",
		"icon": null,
		"label": "-",
		"occupied": false
	}

func _get_stats_text(player_snapshot: Dictionary) -> String:
	if player_snapshot.is_empty():
		player_snapshot = _get_player_snapshot()
	if player_snapshot.is_empty():
		return "No stats"
	return _build_stats_text(player_snapshot)

func _build_stats_text(player_snapshot: Dictionary) -> String:
	return "HP: [b]%.0f[/b]\nDamage: [b]%.2f[/b]\nAtk Speed: [b]%.2f[/b]\nMove: [b]%.1f[/b]\nRange: [b]%.2f[/b]\nArmor: [b]%.1f[/b]\nCrit: [b]%.1f[/b]\n\nPortal Luck: [b]%.2f[/b]\nPortal Freq: [b]%.2f[/b]\nPortal Instability: [b]%.2f[/b]" % _build_stats_format_values(player_snapshot)

func _build_stats_format_values(player_snapshot: Dictionary) -> Array:
	return [
		float(player_snapshot.get("hp", 0.0)),
		float(player_snapshot.get("damage", 0.0)),
		float(player_snapshot.get("attack_speed", 0.0)),
		float(player_snapshot.get("move_speed", 0.0)),
		float(player_snapshot.get("attack_range", 0.0)),
		float(player_snapshot.get("armor", 0.0)),
		float(player_snapshot.get("crit", 0.0)),
		float(player_snapshot.get("portal_luck", 0.0)),
		float(player_snapshot.get("portal_frequency", 1.0)),
		float(player_snapshot.get("portal_instability", 0.0))
	]

func _get_player_snapshot() -> Dictionary:
	if _player_has_method("get_ui_snapshot"):
		var snapshot_variant: Variant = player.call("get_ui_snapshot")
		if snapshot_variant is Dictionary:
			return snapshot_variant
	return {}

func _build_weapon_offer_description(offer: Dictionary, weapon_data: WeaponData, player_snapshot: Dictionary) -> String:
	if weapon_data == null:
		return "Weapon"
	var rarity_text := _get_offer_weapon_rarity(offer, weapon_data).capitalize()
	var desc_text := weapon_data.description
	if desc_text == "":
		desc_text = "No description."
	var lines: Array[String] = [
		"[color=#7fd0ff]Rarity: %s[/color]" % rarity_text,
		desc_text,
		"DMG %.1f" % weapon_data.get_damage_value(),
		"CD %.2fs" % weapon_data.get_cooldown_value(),
		"Range x%.2f" % weapon_data.get_attack_range_value()
	]
	lines.append_array(_build_weapon_offer_synergy_lines(weapon_data, player_snapshot))
	return "\n".join(lines)

func _build_item_offer_description(item_id: String, player_snapshot: Dictionary) -> String:
	var item_data := _find_item(item_id)
	if item_data == null:
		return "Item"
	var item_desc := item_data.description
	if item_desc == "":
		item_desc = "No description."
	var lines: Array[String] = [
		"[color=#b5ff9a]Rarity: %s[/color]" % str(item_data.rarity).capitalize(),
		item_desc
	]
	lines.append_array(_build_item_offer_synergy_lines(item_data, player_snapshot))
	return "\n".join(lines)

func _build_weapon_offer_synergy_lines(weapon_data: WeaponData, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var matched_tags := _build_matching_loadout_tags(WeaponTagRuntime.weapon_tags(weapon_data), player_snapshot)
	if not matched_tags.is_empty():
		lines.append("[color=#ffd36b]Matches loadout tags: %s[/color]" % ", ".join(matched_tags))
	var passive_bonus_lines := _build_passive_weapon_synergy_lines(weapon_data, player_snapshot)
	if not passive_bonus_lines.is_empty():
		lines.append("[color=#ff9af1]Passive synergy:[/color]")
		lines.append_array(passive_bonus_lines)
	var item_bonus_lines := _build_owned_item_weapon_bonus_lines(weapon_data, player_snapshot)
	if not item_bonus_lines.is_empty():
		lines.append("[color=#9affae]Boosted by owned items:[/color]")
		lines.append_array(item_bonus_lines)
	return lines

func _build_item_offer_synergy_lines(item_data: ItemData, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var active_tag_counts := _get_snapshot_dictionary(player_snapshot, "weapon_tag_counts")
	var tag_bonus_lines := _build_item_tag_bonus_match_lines(item_data, active_tag_counts)
	if not tag_bonus_lines.is_empty():
		lines.append("[color=#9affae]Boosts current loadout:[/color]")
		lines.append_array(tag_bonus_lines)
	return lines

func _build_matching_loadout_tags(offer_tags: Array[String], player_snapshot: Dictionary) -> Array[String]:
	var active_tags_variant: Variant = player_snapshot.get("active_weapon_tags", [])
	if not (active_tags_variant is Array):
		return []
	var active_tag_set: Dictionary = {}
	for active_tag_variant in active_tags_variant:
		var normalized_tag := WeaponTagRuntime.normalize_tag(str(active_tag_variant))
		if normalized_tag != "":
			active_tag_set[normalized_tag] = true
	var matches: Array[String] = []
	for offer_tag in offer_tags:
		var normalized_offer_tag := WeaponTagRuntime.normalize_tag(offer_tag)
		if normalized_offer_tag == "" or active_tag_set.get(normalized_offer_tag, false) != true:
			continue
		matches.append(normalized_offer_tag)
	matches.sort()
	return matches

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
			matched_bonus_parts.append("%s %s" % [rule_tag, _format_tag_stat_bonus(stat_id, amount)])
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
		lines.append(
			"- %s: %s via %s"
			% [
				str(passive_rule.get("label", "Passive")),
				_format_tag_stat_bonus(stat_id, amount),
				", ".join(effect_tags)
			]
		)
	return lines

func _build_item_tag_bonus_match_lines(item_data: ItemData, active_tag_counts: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	for rule_variant in item_data.weapon_tag_stat_bonuses:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var rule_tag := WeaponTagRuntime.normalize_tag(str(rule.get("tag", "")))
		if rule_tag == "" or int(active_tag_counts.get(rule_tag, 0)) <= 0:
			continue
		var stat_id := str(rule.get("stat_id", ""))
		if stat_id == "":
			continue
		var amount := float(rule.get("amount", 0.0))
		if is_zero_approx(amount):
			continue
		lines.append("- %s (%dx): %s" % [rule_tag, int(active_tag_counts.get(rule_tag, 0)), _format_tag_stat_bonus(stat_id, amount)])
	return lines

func _format_tag_stat_bonus(stat_id: String, amount: float) -> String:
	match stat_id:
		"damage", "attack_speed", "attack_range", "projectile_speed":
			return "%+.0f%% %s" % [amount * 100.0, stat_id.replace("_", " ")]
		_:
			return "%+.2f %s" % [amount, stat_id.replace("_", " ")]

func _get_snapshot_dictionary(player_snapshot: Dictionary, key: String) -> Dictionary:
	var value: Variant = player_snapshot.get(key, {})
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}

func _build_weapon_slot_label(entry: Dictionary, weapon_data: WeaponData, weapon_id: String, rarity: String) -> String:
	var base_label := ""
	if weapon_data != null and weapon_data.display_name != "":
		var short_name := weapon_data.display_name.substr(0, mini(3, weapon_data.display_name.length()))
		base_label = "%s %s" % [short_name, rarity.capitalize().substr(0, 1)]
	else:
		base_label = "%s %s" % [weapon_id.substr(0, mini(3, weapon_id.length())), rarity.capitalize().substr(0, 1)]
	var kill_requirement := int(entry.get("kill_requirement", 0))
	var kill_progress := int(entry.get("kill_progress", 0))
	if kill_requirement > 0:
		var milestone_summary := _format_milestone_summary(entry)
		return "%s\n%d/%d%s" % [base_label, kill_progress, kill_requirement, milestone_summary]
	return base_label

func _load_weapon_data(weapon_id: String) -> WeaponData:
	return WeaponRuntimeUtil.load_weapon_data(_weapon_cache, weapon_id)

func _find_item(item_id: String) -> ItemData:
	for item in ItemDatabase.get_prototype_items():
		if item != null and item.id == item_id:
			return item
	return null

func _can_buy_weapon_offer(offer: Dictionary) -> bool:
	if player == null:
		return false
	var loadout: Node = player.get_node_or_null("WeaponLoadout")
	if loadout == null:
		return false
	var weapon_id := str(offer.get("id", ""))
	var incoming_rarity := _get_offer_weapon_rarity(offer)
	if weapon_id == "":
		return false
	if loadout.has_method("can_grant_weapon"):
		return loadout.call("can_grant_weapon", weapon_id, incoming_rarity) == true
	if loadout.has_method("has_space"):
		return loadout.call("has_space") == true
	return true

func _get_offer_weapon_rarity(offer: Dictionary, weapon_data: WeaponData = null) -> String:
	var rolled_rarity := str(offer.get("rolled_rarity", ""))
	if rolled_rarity != "":
		return rolled_rarity
	if weapon_data != null and weapon_data.rarity != "":
		return weapon_data.rarity
	return "common"

func _format_milestone_summary(entry: Dictionary) -> String:
	var stat_id := str(entry.get("milestone_stat_id", ""))
	var amount := float(entry.get("milestone_amount", 0.0))
	if stat_id == "" or is_zero_approx(amount):
		return ""
	var stat_label := _milestone_stat_short_label(stat_id)
	if stat_label == "":
		return ""
	var amount_text := _format_milestone_amount(amount)
	return "\n+%s %s" % [amount_text, stat_label]

func _milestone_stat_short_label(stat_id: String) -> String:
	match stat_id:
		"damage":
			return "DMG"
		"attack_speed":
			return "AS"
		"attack_range":
			return "RNG"
		"max_hp":
			return "HP"
		_:
			return stat_id.capitalize()

func _format_milestone_amount(amount: float) -> String:
	if is_equal_approx(amount, round(amount)):
		return str(int(round(amount)))
	return "%.2f" % amount

func _is_shop_open() -> bool:
	if shop_controller != null and shop_controller.has_method("is_shop_open"):
		return shop_controller.call("is_shop_open") == true
	return false

func _get_player_property(property_name: StringName, default_value: Variant) -> Variant:
	if player == null:
		return default_value
	var value: Variant = player.get(property_name)
	return default_value if value == null else value

func _player_has_method(method_name: StringName) -> bool:
	return player != null and player.has_method(method_name)
