class_name ShopViewModel
extends RefCounted

var shop_controller: Node
var player: Node
var weapon_loadout: Node

func configure(shop_controller_node: Node, player_node: Node, weapon_loadout_node: Node) -> void:
	shop_controller = shop_controller_node
	player = player_node
	weapon_loadout = weapon_loadout_node

func get_snapshot() -> Dictionary:
	var player_snapshot := _get_player_snapshot()
	return {
		"wave_index": _get_wave_index(),
		"gold": int(player_snapshot.get("gold", _get_gold())),
		"reroll_cost": _get_reroll_cost(),
		"offers": _get_offers(),
		"items_text": _get_items_text(player_snapshot),
		"weapon_count": _get_weapon_count(),
		"weapon_entries": _get_weapon_entries(),
		"stats_text": _get_stats_text(player_snapshot),
		"is_shop_open": _is_shop_open()
	}

func get_weapon_offer_block_reason(weapon_id: String, rolled_rarity: String = "common") -> String:
	if player == null:
		return "Need empty slot or valid same-rarity merge."
	var loadout: Node = player.get_node_or_null("WeaponLoadout")
	if loadout == null:
		return "Need empty slot or valid same-rarity merge."
	if loadout.has_method("get_grant_block_reason"):
		var reason := str(loadout.call("get_grant_block_reason", weapon_id, rolled_rarity))
		if reason != "":
			return reason
	return "Need empty slot or valid same-rarity merge."

func _get_wave_index() -> int:
	if shop_controller != null and shop_controller.has_method("get_current_wave_index"):
		return int(shop_controller.call("get_current_wave_index"))
	return 1

func _get_gold() -> int:
	if player != null:
		return int(player.get("current_gold"))
	return 0

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
		items_variant = player.get("owned_items")
	if items_variant == null:
		return "-"
	if not (items_variant is Array):
		return "-"
	var lines: Array[String] = []
	for item_variant in items_variant:
		if item_variant is ItemData:
			var item := item_variant as ItemData
			lines.append("- %s" % item.name)
	if lines.is_empty():
		return "None"
	return "\n".join(lines)

func _get_weapon_count() -> int:
	var entries := _get_weapon_entries()
	var count := 0
	for entry in entries:
		if str(entry.get("id", "")) != "":
			count += 1
	return count

func _get_weapon_entries() -> Array[Dictionary]:
	if weapon_loadout != null and weapon_loadout.has_method("get_weapon_entries"):
		var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
		if entries_variant is Array:
			var copied: Array[Dictionary] = []
			for entry_variant in entries_variant:
				if entry_variant is Dictionary:
					copied.append((entry_variant as Dictionary).duplicate(true))
			return copied
	return []

func _get_stats_text(player_snapshot: Dictionary) -> String:
	if player_snapshot.is_empty():
		player_snapshot = _get_player_snapshot()
	if player_snapshot.is_empty():
		return "No stats"
	return \
		"HP: [b]%.0f[/b]\nDamage: [b]%.2f[/b]\nAtk Speed: [b]%.2f[/b]\nMove: [b]%.1f[/b]\nRange: [b]%.2f[/b]\nArmor: [b]%.1f[/b]\nCrit: [b]%.1f[/b]\n\nPortal Luck: [b]%.2f[/b]\nPortal Freq: [b]%.2f[/b]\nPortal Instability: [b]%.2f[/b]" % [
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
	if player != null and player.has_method("get_ui_snapshot"):
		var snapshot_variant: Variant = player.call("get_ui_snapshot")
		if snapshot_variant is Dictionary:
			return snapshot_variant
	return {}

func _is_shop_open() -> bool:
	if shop_controller != null and shop_controller.has_method("is_shop_open"):
		return bool(shop_controller.call("is_shop_open"))
	return false
