class_name WeaponTagRuntime
extends RefCounted

const CANONICAL_STYLE_TAGS: Array[String] = [
	"gun",
	"magic",
	"thrown",
	"melee",
	"orbit",
	"wave",
	"mine"
]

const CANONICAL_FLAVOR_TAGS: Array[String] = [
	"burn",
	"curse",
	"blood",
	"portal",
	"hellfire",
	"ritual",
	"necromancy"
]

const CANONICAL_FEEL_TAGS: Array[String] = [
	"rapid",
	"heavy",
	"precision",
	"spread",
	"close_range",
	"ranged"
]

const CANONICAL_GAMEPLAY_TAGS: Array[String] = [
	"gun",
	"magic",
	"thrown",
	"melee",
	"orbit",
	"wave",
	"mine",
	"burn",
	"curse",
	"blood",
	"portal",
	"hellfire",
	"ritual",
	"necromancy",
	"rapid",
	"heavy",
	"precision",
	"spread",
	"close_range",
	"ranged"
]

static func normalize_tag(raw_tag: String) -> String:
	var normalized := raw_tag.strip_edges().to_lower().replace("-", "_").replace(" ", "_")
	return normalized

static func normalize_tags(raw_tags: Array) -> Array[String]:
	var normalized_tags: Array[String] = []
	var seen: Dictionary = {}
	for raw_tag_variant in raw_tags:
		var tag := normalize_tag(str(raw_tag_variant))
		if tag == "" or seen.get(tag, false) == true:
			continue
		seen[tag] = true
		normalized_tags.append(tag)
	return normalized_tags

static func resolve_effect_tags(raw_tags_variant: Variant) -> Array[String]:
	if raw_tags_variant is Array:
		return normalize_tags(raw_tags_variant as Array)
	var normalized_tag := normalize_tag(str(raw_tags_variant))
	if normalized_tag == "":
		return []
	return [normalized_tag]

static func weapon_tags(weapon_data: WeaponData) -> Array[String]:
	if weapon_data == null:
		return []
	return normalize_tags(weapon_data.tags)

static func item_tags(item_data: ItemData) -> Array[String]:
	if item_data == null:
		return []
	return normalize_tags(item_data.tags)

static func is_canonical_gameplay_tag(tag: String) -> bool:
	var normalized_tag := normalize_tag(tag)
	if normalized_tag == "":
		return false
	return normalized_tag in CANONICAL_GAMEPLAY_TAGS

static func list_noncanonical_gameplay_tags(raw_tags: Array) -> Array[String]:
	var invalid_tags: Array[String] = []
	for tag_variant in normalize_tags(raw_tags):
		if not is_canonical_gameplay_tag(str(tag_variant)):
			invalid_tags.append(str(tag_variant))
	return invalid_tags

static func weapon_has_tag(weapon_data: WeaponData, tag: String) -> bool:
	var normalized_tag := normalize_tag(tag)
	if normalized_tag == "":
		return false
	return normalized_tag in weapon_tags(weapon_data)

static func build_weapon_tag_counts(weapon_entries: Array, weapon_resolver: Callable) -> Dictionary:
	var tag_counts: Dictionary = {}
	if not weapon_resolver.is_valid():
		return tag_counts
	for entry_variant in weapon_entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		var weapon_id := str(entry.get("id", ""))
		if weapon_id == "":
			continue
		var weapon_variant: Variant = weapon_resolver.call(weapon_id)
		if not (weapon_variant is WeaponData):
			continue
		for tag in weapon_tags(weapon_variant as WeaponData):
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
	return tag_counts

static func build_active_weapon_tags(weapon_entries: Array, weapon_resolver: Callable) -> Array[String]:
	var tag_counts := build_weapon_tag_counts(weapon_entries, weapon_resolver)
	var active_tags: Array[String] = []
	for tag_variant in tag_counts.keys():
		active_tags.append(str(tag_variant))
	active_tags.sort()
	return active_tags

static func count_equipped_weapons_with_tag(weapon_entries: Array, weapon_resolver: Callable, tag: String) -> int:
	var normalized_tag := normalize_tag(tag)
	if normalized_tag == "":
		return 0
	return int(build_weapon_tag_counts(weapon_entries, weapon_resolver).get(normalized_tag, 0))

static func build_item_tag_counts(items: Array) -> Dictionary:
	var tag_counts: Dictionary = {}
	for item_variant in items:
		if not (item_variant is ItemData):
			continue
		for tag in item_tags(item_variant as ItemData):
			tag_counts[tag] = int(tag_counts.get(tag, 0)) + 1
	return tag_counts

static func count_owned_items_with_tag(items: Array, tag: String) -> int:
	var normalized_tag := normalize_tag(tag)
	if normalized_tag == "":
		return 0
	return int(build_item_tag_counts(items).get(normalized_tag, 0))

static func build_weapon_tag_bonus_overrides(weapon_data: WeaponData, items: Array) -> Dictionary:
	var bonus_rules: Array[Dictionary] = []
	for item_variant in items:
		if not (item_variant is ItemData):
			continue
		var item := item_variant as ItemData
		for rule_variant in item.weapon_tag_stat_bonuses:
			if not (rule_variant is Dictionary):
				continue
			var rule: Dictionary = rule_variant
			var tag := normalize_tag(str(rule.get("tag", "")))
			if tag == "":
				continue
			bonus_rules.append({
				"effect_tags": [tag],
				"stat_id": str(rule.get("stat_id", "")),
				"amount": float(rule.get("amount", 0.0))
			})
	return build_matching_weapon_stat_overrides(weapon_data, bonus_rules)

static func weapon_matches_effect_tags(weapon_data: WeaponData, rule_entry: Dictionary, tag_field: String = "effect_tags") -> bool:
	if weapon_data == null:
		return false
	var effect_tags := resolve_effect_tags(rule_entry.get(tag_field, []))
	if effect_tags.is_empty():
		return true
	var weapon_tag_set: Dictionary = {}
	for tag in weapon_tags(weapon_data):
		weapon_tag_set[tag] = true
	for effect_tag in effect_tags:
		if weapon_tag_set.get(effect_tag, false) == true:
			return true
	return false

static func build_matching_weapon_stat_overrides(weapon_data: WeaponData, rule_entries: Array[Dictionary], tag_field: String = "effect_tags") -> Dictionary:
	var overrides: Dictionary = {}
	if weapon_data == null:
		return overrides
	for rule in rule_entries:
		if rule.is_empty() or not weapon_matches_effect_tags(weapon_data, rule, tag_field):
			continue
		var stat_id := str(rule.get("stat_id", ""))
		if stat_id == "":
			continue
		var amount := float(rule.get("amount", 0.0))
		if is_zero_approx(amount):
			continue
		overrides[stat_id] = float(overrides.get(stat_id, 0.0)) + amount
	return overrides
