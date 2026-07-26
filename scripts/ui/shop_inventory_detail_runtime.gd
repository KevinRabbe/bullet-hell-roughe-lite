class_name ShopInventoryDetailRuntime
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")

static var _weapon_cache: Dictionary = {}

static func build_item_detail(item_id: String) -> Dictionary:
	var item := ItemDatabase.get_item_by_id(item_id)
	if item == null:
		return {"title": "ITEM", "body": "No item data found."}
	var lines: Array[String] = []
	lines.append("%s · %s" % [str(item.rarity).to_upper(), str(item.category).replace("_", " ").to_upper()])
	if item.description.strip_edges() != "":
		lines.append(item.description.strip_edges())
	var stat_lines := _format_item_stat_modifiers(item.stat_modifiers)
	if not stat_lines.is_empty():
		lines.append("STATS")
		lines.append_array(stat_lines)
	var tag_bonus_lines := _format_item_tag_bonuses(item.weapon_tag_stat_bonuses)
	if not tag_bonus_lines.is_empty():
		lines.append("WEAPON TAG BONUSES")
		lines.append_array(tag_bonus_lines)
	if not item.tags.is_empty():
		lines.append("TAGS · %s" % ", ".join(item.tags))
	return {
		"title": item.name,
		"body": "\n".join(lines)
	}

static func build_weapon_detail(weapon_id: String, rarity: String = "common") -> Dictionary:
	var weapon_data := WeaponRuntimeUtil.load_weapon_data(_weapon_cache, weapon_id)
	if weapon_data == null:
		return {"title": "WEAPON", "body": "No weapon data found."}
	var display_name := weapon_data.display_name if weapon_data.display_name != "" else weapon_id.replace("_", " ").capitalize()
	var family := weapon_data.get_family_value() if weapon_data.has_method("get_family_value") else weapon_data.family
	var lines: Array[String] = [
		"%s · %s" % [rarity.to_upper(), str(family).replace("_", " ").to_upper()],
		"DMG %.1f" % weapon_data.get_damage_value(),
		"CD %.2fs" % weapon_data.get_cooldown_value(),
		"RANGE x%.2f" % weapon_data.get_attack_range_value()
	]
	if weapon_data.description.strip_edges() != "":
		lines.append(weapon_data.description.strip_edges())
	if not weapon_data.tags.is_empty():
		lines.append("TAGS · %s" % ", ".join(weapon_data.tags))
	return {
		"title": display_name,
		"body": "\n".join(lines)
	}

static func _format_item_stat_modifiers(stat_modifiers: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	var keys: Array = stat_modifiers.keys()
	keys.sort()
	for key_variant in keys:
		var stat_id := str(key_variant)
		var amount := float(stat_modifiers.get(key_variant, 0.0))
		if is_zero_approx(amount):
			continue
		lines.append("%s %s" % [_signed_value(stat_id, amount), stat_id.replace("_", " ").to_upper()])
	return lines

static func _format_item_tag_bonuses(rules: Array[Dictionary]) -> Array[String]:
	var lines: Array[String] = []
	for rule_variant in rules:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var tag := str(rule.get("tag", "")).replace("_", " ").to_upper()
		var stat_id := str(rule.get("stat_id", ""))
		var amount := float(rule.get("amount", 0.0))
		if tag == "" or stat_id == "" or is_zero_approx(amount):
			continue
		lines.append("%s · %s %s" % [tag, _signed_value(stat_id, amount), stat_id.replace("_", " ").to_upper()])
	return lines

static func _signed_value(stat_id: String, amount: float) -> String:
	match stat_id:
		"damage", "attack_speed", "attack_range", "projectile_speed", "xp_gain", "coin_gain", "portal_frequency", "portal_reward_multiplier", "burn_damage", "poison_damage", "bleed_damage", "frost_power":
			return "%+.0f%%" % (amount * 100.0)
		_:
			if is_equal_approx(amount, round(amount)):
				return "%+d" % int(round(amount))
			return "%+.2f" % amount
