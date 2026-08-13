class_name ShopInventoryDetailRuntime
extends RefCounted

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const ItemEffectPresentationRuntimeRef = preload("res://scripts/ui/item_effect_presentation_runtime.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const WeaponAttackPatternRuntimeRef = preload("res://scripts/weapons/weapon_attack_pattern_runtime.gd")

static func build_item_detail(item_id: String) -> Dictionary:
	var item := ItemDatabase.get_item_by_id(item_id)
	if item == null:
		return {"title": "ITEM", "body": "No item data found."}
	var lines: Array[String] = []
	lines.append("%s · %s" % [str(item.rarity).to_upper(), str(item.category).replace("_", " ").to_upper()])
	if item.description.strip_edges() != "":
		lines.append(item.description.strip_edges())
	var stat_lines := ItemEffectPresentationRuntimeRef.build_stat_lines(item.stat_modifiers)
	if not stat_lines.is_empty():
		lines.append("STATS")
		lines.append_array(stat_lines)
	var tag_bonus_lines := ItemEffectPresentationRuntimeRef.build_tag_bonus_lines(item.weapon_tag_stat_bonuses)
	if not tag_bonus_lines.is_empty():
		lines.append("WEAPON TAG BONUSES")
		lines.append_array(tag_bonus_lines)
	var conversion_rule_lines := ItemEffectPresentationRuntimeRef.build_conversion_rule_lines(item.stat_conversion_rules)
	if not conversion_rule_lines.is_empty():
		lines.append("LIVE CONVERSIONS")
		lines.append_array(conversion_rule_lines)
	var runtime_rule_lines := ItemEffectPresentationRuntimeRef.build_runtime_rule_lines(item.runtime_rules)
	if not runtime_rule_lines.is_empty():
		lines.append("TRIGGERED EFFECTS")
		lines.append_array(runtime_rule_lines)
	if not item.tags.is_empty():
		lines.append("TAGS · %s" % ", ".join(item.tags))
	return {
		"title": item.name,
		"body": "\n".join(lines)
	}

static func build_weapon_detail(weapon_id: String, rarity: String = "common") -> Dictionary:
	var resource_path := WeaponRuntimeUtil.resource_path_for_id(weapon_id)
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return {"title": "WEAPON", "body": "No weapon data found."}
	var weapon_data := load(resource_path) as WeaponData
	if weapon_data == null:
		return {"title": "WEAPON", "body": "No weapon data found."}
	var display_name := weapon_data.display_name if weapon_data.display_name != "" else weapon_id.replace("_", " ").capitalize()
	var class_labels: Array[String] = []
	for class_id in weapon_data.get_class_values():
		class_labels.append(class_id.replace("_", " ").to_upper())
	var taxonomy_label := " · ".join(class_labels) if not class_labels.is_empty() else "WEAPON"
	var lines: Array[String] = [
		"%s · %s" % [rarity.to_upper(), taxonomy_label],
		"DMG %.1f" % weapon_data.get_damage_value(),
		"CD %.2fs" % weapon_data.get_cooldown_value(),
		_format_multiplier_delta("RANGE", weapon_data.get_attack_range_value())
	]
	lines.append_array(WeaponAttackPatternRuntimeRef.build_behavior_lines(weapon_data))
	if weapon_data.description.strip_edges() != "":
		lines.append(weapon_data.description.strip_edges())
	if not weapon_data.tags.is_empty():
		lines.append("TAGS · %s" % ", ".join(weapon_data.tags))
	return {
		"title": display_name,
		"body": "\n".join(lines)
	}

static func _format_multiplier_delta(label: String, multiplier: float) -> String:
	return "%s %+.0f%%" % [label, (multiplier - 1.0) * 100.0]
