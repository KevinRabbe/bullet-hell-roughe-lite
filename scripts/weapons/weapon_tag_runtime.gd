class_name WeaponTagRuntime
extends RefCounted

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

static func weapon_tags(weapon_data: WeaponData) -> Array[String]:
	if weapon_data == null:
		return []
	return normalize_tags(weapon_data.tags)

static func item_tags(item_data: ItemData) -> Array[String]:
	if item_data == null:
		return []
	return normalize_tags(item_data.tags)

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
