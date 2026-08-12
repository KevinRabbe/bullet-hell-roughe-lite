class_name ItemStatConversionRuntime
extends RefCounted

const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")

static func build_global_stat_bonus(
	items: Array,
	target_stat_id: String,
	source_value_resolver: Callable
) -> float:
	if target_stat_id == "" or not source_value_resolver.is_valid():
		return 0.0
	var total := 0.0
	for item_variant in items:
		if not (item_variant is ItemData):
			continue
		var item := item_variant as ItemData
		for rule in item.stat_conversion_rules:
			if str(rule.get("target_stat_id", "")) != target_stat_id:
				continue
			if not WeaponTagRuntimeRef.resolve_effect_tags(rule.get("effect_tags", [])).is_empty():
				continue
			total += resolve_rule_amount(rule, source_value_resolver)
	return total

static func build_weapon_bonus_overrides(
	items: Array,
	weapon_data: WeaponData,
	source_value_resolver: Callable
) -> Dictionary:
	var resolved_rules: Array[Dictionary] = []
	if weapon_data == null or not source_value_resolver.is_valid():
		return {}
	for item_variant in items:
		if not (item_variant is ItemData):
			continue
		var item := item_variant as ItemData
		for rule in item.stat_conversion_rules:
			var effect_tags := WeaponTagRuntimeRef.resolve_effect_tags(rule.get("effect_tags", []))
			if effect_tags.is_empty():
				continue
			var amount := resolve_rule_amount(rule, source_value_resolver)
			if is_zero_approx(amount):
				continue
			resolved_rules.append({
				"effect_tags": effect_tags,
				"stat_id": str(rule.get("target_stat_id", "")),
				"amount": amount
			})
	return WeaponTagRuntimeRef.build_matching_weapon_stat_overrides(weapon_data, resolved_rules)

static func resolve_rule_amount(rule: Dictionary, source_value_resolver: Callable) -> float:
	if rule.is_empty() or not source_value_resolver.is_valid():
		return 0.0
	var source_stat_id := str(rule.get("source_stat_id", "")).strip_edges()
	var source_step := maxf(float(rule.get("source_step", 0.0)), 0.0)
	var amount_per_step := float(rule.get("amount_per_step", 0.0))
	var max_steps := maxi(int(rule.get("max_steps", 0)), 0)
	if source_stat_id == "" or source_step <= 0.0 or is_zero_approx(amount_per_step) or max_steps <= 0:
		return 0.0
	var source_value := maxf(float(source_value_resolver.call(source_stat_id)), 0.0)
	var resolved_steps := mini(int(floor((source_value + 0.00001) / source_step)), max_steps)
	return float(resolved_steps) * amount_per_step
