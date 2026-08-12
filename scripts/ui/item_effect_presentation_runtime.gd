class_name ItemEffectPresentationRuntime
extends RefCounted

const PERCENT_STAT_IDS: Array[String] = [
	"damage",
	"attack_speed",
	"attack_range",
	"projectile_speed",
	"crit_chance",
	"dodge",
	"xp_gain",
	"coin_gain",
	"shop_discount",
	"reroll_cost",
	"portal_frequency",
	"portal_reward_multiplier",
	"burn_damage",
	"poison_damage",
	"bleed_damage",
	"fear_chance",
	"frost_power"
]

const STAT_LABELS: Dictionary = {
	"max_hp": "MAX HP",
	"hp_regen": "HP REGEN",
	"movement_speed": "MOVE SPEED",
	"pickup_range": "PICKUP RANGE",
	"crit_chance": "CRIT CHANCE",
	"crit_damage": "CRIT DAMAGE",
	"coin_gain": "GOLD GAIN",
	"shop_discount": "SHOP DISCOUNT",
	"reroll_cost": "REROLL COST",
	"portal_luck": "PORTAL LUCK",
	"portal_frequency": "PORTAL FREQUENCY",
	"portal_instability": "PORTAL INSTABILITY",
	"portal_reward_multiplier": "PORTAL REWARD",
	"corruption": "CORRUPTION"
}

static func build_stat_lines(stat_modifiers_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (stat_modifiers_variant is Dictionary):
		return lines
	var stat_modifiers: Dictionary = stat_modifiers_variant
	var stat_ids: Array[String] = []
	for stat_id_variant in stat_modifiers.keys():
		stat_ids.append(str(stat_id_variant))
	stat_ids.sort()
	for stat_id in stat_ids:
		var amount := float(stat_modifiers.get(stat_id, 0.0))
		if is_zero_approx(amount):
			continue
		lines.append("%s %s" % [format_amount(stat_id, amount), stat_label(stat_id)])
	return lines

static func build_tag_bonus_lines(bonus_rules_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (bonus_rules_variant is Array):
		return lines
	for rule_variant in bonus_rules_variant:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var tag := str(rule.get("tag", "")).strip_edges()
		var stat_id := str(rule.get("stat_id", "")).strip_edges()
		var amount := float(rule.get("amount", 0.0))
		if tag == "" or stat_id == "" or is_zero_approx(amount):
			continue
		lines.append(
			"%s WEAPONS / %s %s"
			% [tag.replace("_", " ").to_upper(), format_amount(stat_id, amount), stat_label(stat_id)]
		)
	return lines

static func build_runtime_rule_lines(runtime_rules_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (runtime_rules_variant is Array):
		return lines
	for rule_variant in runtime_rules_variant:
		if not (rule_variant is Dictionary):
			continue
		var display_text := str((rule_variant as Dictionary).get("display_text", "")).strip_edges()
		if display_text != "":
			lines.append(display_text)
	return lines

static func build_conversion_rule_lines(conversion_rules_variant: Variant) -> Array[String]:
	var lines: Array[String] = []
	if not (conversion_rules_variant is Array):
		return lines
	for rule_variant in conversion_rules_variant:
		if not (rule_variant is Dictionary):
			continue
		var display_text := str((rule_variant as Dictionary).get("display_text", "")).strip_edges()
		if display_text != "":
			lines.append(display_text)
	return lines

static func format_amount(stat_id: String, amount: float) -> String:
	if stat_id in PERCENT_STAT_IDS:
		return "%+.0f%%" % (amount * 100.0)
	if is_equal_approx(amount, round(amount)):
		return "%+d" % int(round(amount))
	return "%+.2f" % amount

static func stat_label(stat_id: String) -> String:
	return str(STAT_LABELS.get(stat_id, stat_id.replace("_", " ").to_upper()))
