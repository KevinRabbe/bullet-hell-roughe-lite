extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const WeaponTagRuntime = preload("res://scripts/weapons/weapon_tag_runtime.gd")
const ENEMY_RESOURCE_DIR: String = "res://data/enemies"
const WEAPON_RESOURCE_DIR: String = "res://data/weapons"
const ITEM_RESOURCE_DIR: String = "res://data/items"
const PORTAL_EVENT_DIR: String = "res://data/portal_events"
const SET_BONUS_DIR: String = "res://data/set_bonuses"

var characters: Dictionary = {}
var weapons: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var portal_events: Dictionary = {}
var set_bonuses: Dictionary = {}

func _ready() -> void:
	_register_defaults()
	print("DataRegistry ready: %d characters, %d weapons, %d items, %d enemies, %d portal events, %d set bonuses" % [
		characters.size(),
		weapons.size(),
		items.size(),
		enemies.size(),
		portal_events.size(),
		set_bonuses.size()
	])

func _register_defaults() -> void:
	_load_character_json_data("res://data/characters")
	_register_by_id(weapons, _load_resource_directory(WEAPON_RESOURCE_DIR))
	_register_by_id(items, _load_resource_directory(ITEM_RESOURCE_DIR))
	if items.is_empty():
		_register_by_id(items, ItemDatabase.get_prototype_items())
	_register_by_id(enemies, _load_enemy_resources())
	_load_json_directory_into(portal_events, PORTAL_EVENT_DIR)
	_load_json_directory_into(set_bonuses, SET_BONUS_DIR)
	_validate_registry_entries()

func _load_enemy_resources() -> Array:
	return _load_resource_directory(ENEMY_RESOURCE_DIR)

func _load_character_json_data(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("Character data directory missing: %s" % directory_path)
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			var full_path := "%s/%s" % [directory_path, file_name]
			var data := _load_json_dictionary(full_path)
			var character_id := str(data.get("id", ""))
			if character_id != "":
				characters[character_id] = data
			else:
				push_warning("Character data file is missing id and was skipped: %s" % full_path)
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_json_directory_into(target: Dictionary, directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		push_warning("JSON data directory missing: %s" % directory_path)
		return
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			var full_path := "%s/%s" % [directory_path, file_name]
			var data := _load_json_dictionary(full_path)
			var entry_id := str(data.get("id", ""))
			if entry_id != "":
				target[entry_id] = data
			else:
				push_warning("JSON data file is missing id and was skipped: %s" % full_path)
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("JSON data file missing: %s" % path)
		return {}
	var json_text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed is Dictionary:
		return parsed
	push_warning("JSON data file is invalid or not a dictionary: %s" % path)
	return {}

func _register_by_id(target: Dictionary, entries: Array) -> void:
	for entry in entries:
		if entry == null:
			continue
		if not entry.has_method("get"):
			continue
		var entry_id := str(entry.get("id"))
		if entry_id == "":
			continue
		target[entry_id] = entry

func _load_resource_directory(directory_path: String) -> Array:
	var loaded: Array = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return loaded
	var file_names: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	file_names.sort()
	for sorted_file_name in file_names:
		var full_path := "%s/%s" % [directory_path, sorted_file_name]
		if ResourceLoader.exists(full_path):
			var resource := load(full_path)
			if resource != null:
				loaded.append(resource)
	return loaded

func _validate_registry_entries() -> void:
	_validate_character_entries()
	for weapon_id in weapons.keys():
		var weapon: Variant = weapons[weapon_id]
		if weapon == null:
			push_warning("Weapon entry '%s' is null." % str(weapon_id))
			continue
		if weapon is WeaponData:
			var weapon_resource: WeaponData = weapon
			if weapon_resource.display_name == "":
				push_warning("Weapon '%s' is missing display_name." % str(weapon_id))
			_validate_weapon_tags(str(weapon_id), weapon_resource.tags)
			var shop_enabled: bool = weapon_resource.shop_enabled == true
			if shop_enabled and not _is_placeholder_weapon(weapon_resource) and weapon_resource.price <= 0:
				push_warning("Weapon '%s' has non-positive price; shop fallback may be used." % str(weapon_id))
		elif weapon is Dictionary:
			var weapon_dict: Dictionary = weapon
			if str(weapon_dict.get("display_name", "")) == "":
				push_warning("Weapon '%s' is missing display_name." % str(weapon_id))
			_validate_weapon_tags(str(weapon_id), weapon_dict.get("tags", []))
			var shop_enabled_dict: bool = weapon_dict.get("shop_enabled", false) == true
			if shop_enabled_dict and not _is_placeholder_weapon(weapon_dict) and int(weapon_dict.get("price", 0)) <= 0:
				push_warning("Weapon '%s' has non-positive price; shop fallback may be used." % str(weapon_id))
		else:
			push_warning("Weapon entry '%s' has unsupported type." % str(weapon_id))
	for item_id in items.keys():
		var item: Variant = items[item_id]
		if item == null:
			push_warning("Item entry '%s' is null." % str(item_id))
			continue
		if item is ItemData:
			var item_resource: ItemData = item
			if item_resource.name == "":
				push_warning("Item '%s' is missing name." % str(item_id))
			_validate_item_weapon_tag_bonus_rules(str(item_id), item_resource.weapon_tag_stat_bonuses)
		elif item is Dictionary:
			var item_dict: Dictionary = item
			if str(item_dict.get("name", "")) == "":
				push_warning("Item '%s' is missing name." % str(item_id))
			_validate_item_weapon_tag_bonus_rules(str(item_id), item_dict.get("weapon_tag_stat_bonuses", []))
		else:
			push_warning("Item entry '%s' has unsupported type." % str(item_id))
	for enemy_id in enemies.keys():
		var enemy: Variant = enemies[enemy_id]
		if enemy == null:
			push_warning("Enemy entry '%s' is null." % str(enemy_id))
			continue
		if enemy is EnemyData:
			var enemy_resource: EnemyData = enemy
			if enemy_resource.max_hp <= 0.0:
				push_warning("Enemy '%s' has invalid max_hp." % str(enemy_id))
		elif enemy is Dictionary:
			var enemy_dict: Dictionary = enemy
			if float(enemy_dict.get("max_hp", 0.0)) <= 0.0:
				push_warning("Enemy '%s' has invalid max_hp." % str(enemy_id))
		else:
			push_warning("Enemy entry '%s' has unsupported type." % str(enemy_id))
	for portal_event_id in portal_events.keys():
		var portal_event_variant: Variant = portal_events[portal_event_id]
		if not (portal_event_variant is Dictionary):
			push_warning("Portal event entry '%s' is invalid." % str(portal_event_id))
			continue
		var portal_event: Dictionary = portal_event_variant
		if str(portal_event.get("title", "")) == "":
			push_warning("Portal event '%s' is missing title." % str(portal_event_id))
		if float(portal_event.get("base_weight", 0.0)) <= 0.0:
			push_warning("Portal event '%s' has non-positive base_weight." % str(portal_event_id))
	_validate_set_bonus_entries()

func _validate_character_entries() -> void:
	for character_id in characters.keys():
		var character_variant: Variant = characters[character_id]
		if not (character_variant is Dictionary):
			push_warning("Character entry '%s' is invalid." % str(character_id))
			continue
		var character_data: Dictionary = character_variant
		if str(character_data.get("display_name", "")) == "":
			push_warning("Character '%s' is missing display_name." % str(character_id))
		var visual_path := str(character_data.get("visual_path", ""))
		if visual_path != "" and not ResourceLoader.exists(visual_path):
			push_warning("Character '%s' is missing visual resource: %s" % [str(character_id), visual_path])
		var selectable: bool = character_data.get("selectable", true) != false
		_validate_character_presentation(str(character_id), character_data.get("presentation", {}), selectable)
		if not selectable:
			continue
		_validate_character_weapon_list(str(character_id), "starting_weapon_ids", character_data.get("starting_weapon_ids", []))
		_validate_character_weapon_list(str(character_id), "family_weapon_ids", character_data.get("family_weapon_ids", []))
		_validate_character_passive_runtime_tags(str(character_id), character_data.get("passive_runtime_rules", []))

func _validate_character_weapon_list(character_id: String, field_name: String, weapon_ids_variant: Variant) -> void:
	if not (weapon_ids_variant is Array):
		push_warning("Character '%s' has invalid %s payload." % [character_id, field_name])
		return
	var weapon_ids: Array = weapon_ids_variant
	if weapon_ids.is_empty():
		push_warning("Character '%s' has no entries in %s." % [character_id, field_name])
		return
	for weapon_id_variant in weapon_ids:
		var weapon_id := str(weapon_id_variant)
		if weapon_id == "":
			push_warning("Character '%s' has an empty weapon id in %s." % [character_id, field_name])
			continue
		var resource_path := "%s/%s.tres" % [WEAPON_RESOURCE_DIR, weapon_id]
		if not ResourceLoader.exists(resource_path):
			push_warning("Character '%s' references missing weapon '%s' in %s." % [character_id, weapon_id, field_name])

func _validate_character_passive_runtime_tags(character_id: String, rules_variant: Variant) -> void:
	if not (rules_variant is Array):
		return
	var passive_rules: Array = rules_variant
	for rule_variant in passive_rules:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var modifiers_variant: Variant = rule.get("modifiers", [])
		if not (modifiers_variant is Array):
			continue
		var modifiers: Array = modifiers_variant
		for modifier_variant in modifiers:
			if not (modifier_variant is Dictionary):
				continue
			var modifier: Dictionary = modifier_variant
			var invalid_tags := WeaponTagRuntime.list_noncanonical_gameplay_tags(
				WeaponTagRuntime.resolve_effect_tags(modifier.get("effect_tags", []))
			)
			if invalid_tags.is_empty():
				continue
			push_warning(
				"Character '%s' passive rule '%s' uses non-canonical gameplay tags: %s"
				% [character_id, str(rule.get("id", "")), ", ".join(invalid_tags)]
			)

func _validate_character_presentation(character_id: String, presentation_variant: Variant, selectable: bool) -> void:
	if not (presentation_variant is Dictionary):
		if selectable:
			push_warning("Character '%s' is missing presentation metadata." % character_id)
		return
	var presentation: Dictionary = presentation_variant
	if selectable and str(presentation.get("headline", "")) == "":
		push_warning("Character '%s' presentation is missing headline." % character_id)
	if selectable and str(presentation.get("passive_name", "")) == "":
		push_warning("Character '%s' presentation is missing passive_name." % character_id)
	if selectable and str(presentation.get("passive_summary", "")) == "":
		push_warning("Character '%s' presentation is missing passive_summary." % character_id)
	var difficulty := str(presentation.get("difficulty", "medium"))
	if difficulty not in ["easy", "medium", "hard"]:
		push_warning("Character '%s' presentation has invalid difficulty '%s'." % [character_id, difficulty])
	var playstyle_tags_variant: Variant = presentation.get("playstyle_tags", [])
	if playstyle_tags_variant is Array:
		for tag_variant in playstyle_tags_variant:
			if str(tag_variant) == "":
				push_warning("Character '%s' presentation contains an empty playstyle tag." % character_id)

func _validate_set_bonus_entries() -> void:
	var required_thresholds: Array[int] = [2, 4, 6]
	for family_id in set_bonuses.keys():
		var definition_variant: Variant = set_bonuses[family_id]
		if not (definition_variant is Dictionary):
			push_warning("Set bonus entry '%s' is invalid." % str(family_id))
			continue
		var definition: Dictionary = definition_variant
		var thresholds_variant: Variant = definition.get("thresholds", [])
		if not (thresholds_variant is Array):
			push_warning("Set bonus '%s' has invalid thresholds payload." % str(family_id))
			continue
		var thresholds: Array = thresholds_variant
		if thresholds.is_empty():
			push_warning("Set bonus '%s' has no thresholds." % str(family_id))
			continue
		var pieces_present: Dictionary = {}
		for threshold_variant in thresholds:
			if not (threshold_variant is Dictionary):
				push_warning("Set bonus '%s' contains a non-dictionary threshold." % str(family_id))
				continue
			var threshold: Dictionary = threshold_variant
			var pieces := int(threshold.get("pieces", 0))
			if pieces <= 0:
				push_warning("Set bonus '%s' contains a threshold with invalid pieces." % str(family_id))
				continue
			pieces_present[pieces] = true
			var effects_variant: Variant = threshold.get("effects", [])
			if not (effects_variant is Array):
				push_warning("Set bonus '%s' threshold %d has invalid effects payload." % [str(family_id), pieces])
				continue
			var effects: Array = effects_variant
			if effects.is_empty():
				push_warning("Set bonus '%s' threshold %d has no effects." % [str(family_id), pieces])
				continue
			for effect_variant in effects:
				if not (effect_variant is Dictionary):
					push_warning("Set bonus '%s' threshold %d contains a non-dictionary effect." % [str(family_id), pieces])
					continue
				var effect: Dictionary = effect_variant
				if str(effect.get("type", "")) == "":
					push_warning("Set bonus '%s' threshold %d contains an effect with no type." % [str(family_id), pieces])
					continue
				_validate_set_bonus_effect_tags(str(family_id), pieces, effect)
		for required_pieces in required_thresholds:
			if pieces_present.get(required_pieces, false) != true:
				push_warning("Set bonus '%s' is missing the %d-piece threshold." % [str(family_id), required_pieces])
	for character_id in get_selectable_character_ids():
		var character_variant: Variant = characters.get(character_id, {})
		if not (character_variant is Dictionary):
			continue
		var character_data: Dictionary = character_variant
		var family_id := str(character_data.get("preferred_weapon_family", ""))
		if family_id == "":
			push_warning("Character '%s' is missing preferred_weapon_family for set bonus coverage." % character_id)
			continue
		if not set_bonuses.has(family_id):
			push_warning("Character '%s' preferred family '%s' has no set bonus definition." % [character_id, family_id])

func _is_placeholder_weapon(weapon: Variant) -> bool:
	if weapon == null or not weapon.has_method("get"):
		return false
	var weapon_id := str(weapon.get("id"))
	if weapon_id.contains("placeholder"):
		return true
	var family_id := ""
	if weapon.has_method("get_family_value"):
		family_id = str(weapon.call("get_family_value"))
	else:
		family_id = str(weapon.get("family"))
	return family_id.contains("placeholder")

func _validate_weapon_tags(weapon_id: String, tags_variant: Variant) -> void:
	if not (tags_variant is Array):
		return
	var invalid_tags := WeaponTagRuntime.list_noncanonical_gameplay_tags(tags_variant)
	if invalid_tags.is_empty():
		return
	push_warning(
		"Weapon '%s' has non-canonical gameplay tags: %s" % [
			weapon_id,
			", ".join(invalid_tags)
		]
	)

func _validate_item_weapon_tag_bonus_rules(item_id: String, rules_variant: Variant) -> void:
	if not (rules_variant is Array):
		return
	var invalid_tags: Array[String] = []
	for rule_variant in rules_variant:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		var rule_tag := WeaponTagRuntime.normalize_tag(str(rule.get("tag", "")))
		if rule_tag == "" or WeaponTagRuntime.is_canonical_gameplay_tag(rule_tag):
			continue
		if rule_tag in invalid_tags:
			continue
		invalid_tags.append(rule_tag)
	if invalid_tags.is_empty():
		return
	push_warning(
		"Item '%s' has non-canonical weapon tag bonus targets: %s" % [
			item_id,
			", ".join(invalid_tags)
		]
	)

func _validate_set_bonus_effect_tags(family_id: String, pieces: int, effect: Dictionary) -> void:
	var effect_tags_variant: Variant = effect.get("effect_tags", [])
	if not (effect_tags_variant is Array):
		return
	var invalid_tags := WeaponTagRuntime.list_noncanonical_gameplay_tags(effect_tags_variant)
	if invalid_tags.is_empty():
		return
	push_warning(
		"Set bonus '%s' threshold %d effect '%s' has non-canonical effect_tags: %s" % [
			family_id,
			pieces,
			str(effect.get("type", "")),
			", ".join(invalid_tags)
		]
	)

func get_character(id: String):
	return characters.get(id)

func get_character_ids() -> Array[String]:
	var ids: Array[String] = []
	for character_id in characters.keys():
		ids.append(str(character_id))
	ids.sort()
	return ids

func get_selectable_character_ids() -> Array[String]:
	var entries: Array[Dictionary] = []
	for character_id in characters.keys():
		var entry_variant: Variant = characters[character_id]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if entry.has("selectable") and entry.get("selectable", true) == false:
			continue
		entries.append({
			"id": str(character_id),
			"order": int(entry.get("roster_order", 9999))
		})
	entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var order_a := int(a.get("order", 9999))
		var order_b := int(b.get("order", 9999))
		if order_a == order_b:
			return str(a.get("id", "")) < str(b.get("id", ""))
		return order_a < order_b
	)
	var ids: Array[String] = []
	for entry in entries:
		ids.append(str(entry.get("id", "")))
	return ids

func get_default_selectable_character_id() -> String:
	var selectable_ids := get_selectable_character_ids()
	if not selectable_ids.is_empty():
		return selectable_ids[0]
	var all_ids := get_character_ids()
	if all_ids.is_empty():
		return ""
	return all_ids[0]

func get_character_display_name(id: String) -> String:
	var character_variant: Variant = characters.get(id, {})
	if character_variant is Dictionary:
		var character_data: Dictionary = character_variant
		return str(character_data.get("display_name", id))
	return id

func get_weapon(id: String):
	return weapons.get(id)

func get_item(id: String):
	return items.get(id)

func get_enemy(id: String):
	return enemies.get(id)

func get_portal_event(id: String):
	return portal_events.get(id)

func get_set_bonus(id: String):
	return set_bonuses.get(id)
