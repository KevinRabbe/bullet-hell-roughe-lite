class_name ContentValidator
extends RefCounted

const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")
const PortalMutationRuntimeRef = preload("res://scripts/portal/portal_mutation_runtime.gd")

const EXPECTED_SELECTABLE_HUNTERS := 16
const SUPPORTED_RARITIES: Array[String] = ["common", "rare", "epic", "legendary"]
const REQUIRED_SET_THRESHOLDS: Array[int] = [2, 4, 6]
const SUPPORTED_MUTATION_TIERS: Array[String] = ["minor", "major"]
const SUPPORTED_DURATIONS: Array[String] = ["event", "wave", "run"]

static func validate_registry(registry: Node) -> Dictionary:
	var issues: Array[Dictionary] = []
	if registry == null:
		_add_error(issues, "registry_missing", "registry", "", "DataRegistry is unavailable.")
		return _build_report(issues, {})

	var characters := _dictionary_property(registry, "characters")
	var weapons := _dictionary_property(registry, "weapons")
	var items := _dictionary_property(registry, "items")
	var enemies := _dictionary_property(registry, "enemies")
	var portal_events := _dictionary_property(registry, "portal_events")
	var portal_mutations := _dictionary_property(registry, "portal_mutations")
	var ascensions := _dictionary_property(registry, "ascensions")
	var set_bonuses := _dictionary_property(registry, "set_bonuses")

	_validate_characters(issues, characters, weapons, set_bonuses)
	_validate_weapons(issues, weapons)
	_validate_items(issues, items)
	_validate_enemies(issues, enemies)
	_validate_portal_events(issues, portal_events)
	_validate_effect_definitions(issues, "portal_mutation", portal_mutations, true)
	_validate_effect_definitions(issues, "ascension", ascensions, false)
	_validate_set_bonuses(issues, set_bonuses)

	return _build_report(issues, {
		"characters": characters.size(),
		"weapons": weapons.size(),
		"items": items.size(),
		"enemies": enemies.size(),
		"portal_events": portal_events.size(),
		"portal_mutations": portal_mutations.size(),
		"ascensions": ascensions.size(),
		"set_bonuses": set_bonuses.size()
	})

static func _validate_characters(
	issues: Array[Dictionary],
	characters: Dictionary,
	weapons: Dictionary,
	set_bonuses: Dictionary
) -> void:
	var selectable_count := 0
	var roster_orders: Dictionary = {}
	for character_id in _sorted_keys(characters):
		var entry: Variant = characters[character_id]
		if not (entry is Dictionary):
			_add_error(issues, "character_type", "character", character_id, "Character entry must be a dictionary.")
			continue
		var character: Dictionary = entry
		_validate_embedded_id(issues, "character", character_id, character)
		var selectable := character.get("selectable", true) != false
		if not selectable:
			continue
		selectable_count += 1

		if str(character.get("display_name", "")).strip_edges() == "":
			_add_error(issues, "character_display_name", "character", character_id, "Selectable hunter is missing display_name.")
		var visual_path := str(character.get("visual_path", "")).strip_edges()
		if visual_path == "":
			_add_error(issues, "character_visual_path", "character", character_id, "Selectable hunter is missing visual_path.")
		elif not ResourceLoader.exists(visual_path):
			_add_error(issues, "character_visual_missing", "character", character_id, "Selectable hunter visual resource does not exist: %s" % visual_path)

		var roster_order := int(character.get("roster_order", -1))
		if roster_order < 0:
			_add_error(issues, "character_roster_order", "character", character_id, "Selectable hunter requires a non-negative roster_order.")
		elif roster_orders.has(roster_order):
			_add_error(issues, "character_roster_order_duplicate", "character", character_id, "roster_order %d is already used by '%s'." % [roster_order, str(roster_orders[roster_order])])
		else:
			roster_orders[roster_order] = character_id

		var starting_weapon_ids := _string_array(character.get("starting_weapon_ids", []))
		var family_weapon_ids := _string_array(character.get("family_weapon_ids", []))
		if starting_weapon_ids.is_empty():
			_add_error(issues, "character_starters_empty", "character", character_id, "Selectable hunter has no starting weapons.")
		if family_weapon_ids.size() != 6:
			_add_error(issues, "character_family_weapon_count", "character", character_id, "Selectable hunter must expose exactly 6 family weapons; found %d." % family_weapon_ids.size())
		_validate_weapon_references(issues, character_id, "starting_weapon_ids", starting_weapon_ids, weapons)
		_validate_weapon_references(issues, character_id, "family_weapon_ids", family_weapon_ids, weapons)
		for starter_id in starting_weapon_ids:
			if not family_weapon_ids.has(starter_id):
				_add_error(issues, "character_starter_outside_family", "character", character_id, "Starting weapon '%s' is not in family_weapon_ids." % starter_id)

		var family_id := str(character.get("preferred_weapon_family", "")).strip_edges()
		if family_id == "":
			_add_error(issues, "character_family_missing", "character", character_id, "Selectable hunter is missing preferred_weapon_family.")
		elif not set_bonuses.has(family_id):
			_add_error(issues, "character_set_bonus_missing", "character", character_id, "Preferred family '%s' has no set-bonus definition." % family_id)

	if selectable_count != EXPECTED_SELECTABLE_HUNTERS:
		_add_error(issues, "selectable_hunter_count", "character", "", "Expected %d selectable hunters; found %d." % [EXPECTED_SELECTABLE_HUNTERS, selectable_count])

static func _validate_weapon_references(
	issues: Array[Dictionary],
	character_id: String,
	field_name: String,
	weapon_ids: Array[String],
	weapons: Dictionary
) -> void:
	var seen: Dictionary = {}
	for weapon_id in weapon_ids:
		if weapon_id == "":
			_add_error(issues, "character_weapon_id_empty", "character", character_id, "%s contains an empty weapon id." % field_name)
			continue
		if seen.has(weapon_id):
			_add_error(issues, "character_weapon_duplicate", "character", character_id, "%s repeats weapon '%s'." % [field_name, weapon_id])
			continue
		seen[weapon_id] = true
		if not weapons.has(weapon_id):
			_add_error(issues, "character_weapon_missing", "character", character_id, "%s references unknown weapon '%s'." % [field_name, weapon_id])

static func _validate_weapons(issues: Array[Dictionary], weapons: Dictionary) -> void:
	for weapon_id in _sorted_keys(weapons):
		var weapon: Variant = weapons[weapon_id]
		if weapon == null or not (weapon is Object):
			_add_error(issues, "weapon_type", "weapon", weapon_id, "Weapon entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "weapon", weapon_id, weapon)
		if str(_value(weapon, "display_name", "")).strip_edges() == "":
			_add_error(issues, "weapon_display_name", "weapon", weapon_id, "Weapon is missing display_name.")
		if _weapon_family(weapon) == "":
			_add_error(issues, "weapon_family", "weapon", weapon_id, "Weapon is missing family.")
		if _weapon_damage(weapon) <= 0.0:
			_add_error(issues, "weapon_damage", "weapon", weapon_id, "Weapon damage must be positive.")
		if _weapon_cooldown(weapon) <= 0.0:
			_add_error(issues, "weapon_cooldown", "weapon", weapon_id, "Weapon cooldown must be positive.")
		if _weapon_range(weapon) <= 0.0:
			_add_error(issues, "weapon_range", "weapon", weapon_id, "Weapon range must be positive.")
		var tags_variant: Variant = _value(weapon, "tags", [])
		if tags_variant is Array:
			var invalid_tags := WeaponTagRuntimeRef.list_noncanonical_gameplay_tags(tags_variant)
			if not invalid_tags.is_empty():
				_add_error(issues, "weapon_tags", "weapon", weapon_id, "Non-canonical gameplay tags: %s" % ", ".join(invalid_tags))
		if bool(_value(weapon, "shop_enabled", true)) and not _is_placeholder_weapon(weapon) and int(_value(weapon, "price", 0)) <= 0:
			_add_error(issues, "weapon_price", "weapon", weapon_id, "Shop-enabled weapon must have a positive price.")

static func _validate_items(issues: Array[Dictionary], items: Dictionary) -> void:
	for item_id in _sorted_keys(items):
		var item: Variant = items[item_id]
		if item == null or not (item is Object):
			_add_error(issues, "item_type", "item", item_id, "Item entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "item", item_id, item)
		if str(_value(item, "name", "")).strip_edges() == "":
			_add_error(issues, "item_name", "item", item_id, "Item is missing name.")
		if int(_value(item, "price", 0)) <= 0:
			_add_error(issues, "item_price", "item", item_id, "Item price must be positive.")
		if int(_value(item, "stack_limit", 0)) <= 0:
			_add_error(issues, "item_stack_limit", "item", item_id, "Item stack_limit must be positive.")
		var rarity := str(_value(item, "rarity", "")).to_lower()
		if rarity not in SUPPORTED_RARITIES:
			_add_error(issues, "item_rarity", "item", item_id, "Unsupported rarity '%s'." % rarity)
		var rules_variant: Variant = _value(item, "weapon_tag_stat_bonuses", [])
		if rules_variant is Array:
			for rule_variant in rules_variant:
				if not (rule_variant is Dictionary):
					_add_error(issues, "item_tag_bonus_type", "item", item_id, "weapon_tag_stat_bonuses contains a non-dictionary rule.")
					continue
				var rule: Dictionary = rule_variant
				var tag := WeaponTagRuntimeRef.normalize_tag(str(rule.get("tag", "")))
				if tag == "" or not WeaponTagRuntimeRef.is_canonical_gameplay_tag(tag):
					_add_error(issues, "item_tag_bonus_tag", "item", item_id, "weapon_tag_stat_bonuses targets invalid tag '%s'." % tag)
				if str(rule.get("stat_id", "")).strip_edges() == "":
					_add_error(issues, "item_tag_bonus_stat", "item", item_id, "weapon_tag_stat_bonuses contains an empty stat_id.")

static func _validate_enemies(issues: Array[Dictionary], enemies: Dictionary) -> void:
	for enemy_id in _sorted_keys(enemies):
		var enemy: Variant = enemies[enemy_id]
		if enemy == null or not (enemy is Object):
			_add_error(issues, "enemy_type", "enemy", enemy_id, "Enemy entry must be a Resource/Object.")
			continue
		_validate_embedded_id(issues, "enemy", enemy_id, enemy)
		if str(_value(enemy, "display_name", "")).strip_edges() == "":
			_add_warning(issues, "enemy_display_name", "enemy", enemy_id, "Enemy is missing display_name.")
		if float(_value(enemy, "max_hp", 0.0)) <= 0.0:
			_add_error(issues, "enemy_max_hp", "enemy", enemy_id, "Enemy max_hp must be positive.")
		if float(_value(enemy, "move_speed", -1.0)) < 0.0:
			_add_error(issues, "enemy_move_speed", "enemy", enemy_id, "Enemy move_speed cannot be negative.")
		if float(_value(enemy, "contact_damage", -1.0)) < 0.0:
			_add_error(issues, "enemy_contact_damage", "enemy", enemy_id, "Enemy contact_damage cannot be negative.")
		if int(_value(enemy, "reward_gold", -1)) < 0 or int(_value(enemy, "reward_xp", -1)) < 0:
			_add_error(issues, "enemy_reward", "enemy", enemy_id, "Enemy rewards cannot be negative.")
		var visual_path := str(_value(enemy, "visual_texture_path", "")).strip_edges()
		if visual_path != "" and not ResourceLoader.exists(visual_path):
			_add_error(issues, "enemy_visual_missing", "enemy", enemy_id, "Enemy visual resource does not exist: %s" % visual_path)

static func _validate_portal_events(issues: Array[Dictionary], portal_events: Dictionary) -> void:
	for event_id in _sorted_keys(portal_events):
		var event_variant: Variant = portal_events[event_id]
		if not (event_variant is Dictionary):
			_add_error(issues, "portal_event_type", "portal_event", event_id, "Portal event must be a dictionary.")
			continue
		var event: Dictionary = event_variant
		_validate_embedded_id(issues, "portal_event", event_id, event)
		if str(event.get("title", "")).strip_edges() == "":
			_add_error(issues, "portal_event_title", "portal_event", event_id, "Portal event is missing title.")
		if float(event.get("base_weight", 0.0)) <= 0.0:
			_add_error(issues, "portal_event_weight", "portal_event", event_id, "Portal event base_weight must be positive.")
		if int(event.get("reward_count", 0)) < 0:
			_add_error(issues, "portal_event_reward_count", "portal_event", event_id, "Portal event reward_count cannot be negative.")

static func _validate_effect_definitions(
	issues: Array[Dictionary],
	category: String,
	definitions: Dictionary,
	validate_mutation_fields: bool
) -> void:
	for definition_id in _sorted_keys(definitions):
		var definition_variant: Variant = definitions[definition_id]
		if not (definition_variant is Dictionary):
			_add_error(issues, "%s_type" % category, category, definition_id, "Definition must be a dictionary.")
			continue
		var definition: Dictionary = definition_variant
		_validate_embedded_id(issues, category, definition_id, definition)
		if str(definition.get("title", "")).strip_edges() == "":
			_add_error(issues, "%s_title" % category, category, definition_id, "Definition is missing title.")
		var stack_policy := str(definition.get("stack_policy", ""))
		if stack_policy not in PortalMutationRuntimeRef.SUPPORTED_STACK_POLICIES:
			_add_error(issues, "%s_stack_policy" % category, category, definition_id, "Unsupported stack_policy '%s'." % stack_policy)
		if validate_mutation_fields:
			var mutation_tier := str(definition.get("mutation_tier", ""))
			if mutation_tier not in SUPPORTED_MUTATION_TIERS:
				_add_error(issues, "portal_mutation_tier", category, definition_id, "Unsupported mutation_tier '%s'." % mutation_tier)
			var duration := str(definition.get("duration", ""))
			if duration not in SUPPORTED_DURATIONS:
				_add_error(issues, "portal_mutation_duration", category, definition_id, "Unsupported duration '%s'." % duration)
		var effects_variant: Variant = definition.get("effects", [])
		if not (effects_variant is Array) or (effects_variant as Array).is_empty():
			_add_error(issues, "%s_effects" % category, category, definition_id, "Definition must contain at least one effect.")
			continue
		for effect_variant in effects_variant:
			if not (effect_variant is Dictionary):
				_add_error(issues, "%s_effect_type" % category, category, definition_id, "Definition contains a non-dictionary effect.")
				continue
			var effect: Dictionary = effect_variant
			var effect_type := str(effect.get("type", ""))
			if effect_type not in PortalMutationRuntimeRef.SUPPORTED_EFFECT_TYPES:
				_add_error(issues, "%s_effect_kind" % category, category, definition_id, "Unsupported effect type '%s'." % effect_type)
		var tags_variant: Variant = definition.get("effect_tags", [])
		if tags_variant is Array:
			var invalid_tags := WeaponTagRuntimeRef.list_noncanonical_gameplay_tags(tags_variant)
			if not invalid_tags.is_empty():
				_add_error(issues, "%s_effect_tags" % category, category, definition_id, "Non-canonical effect_tags: %s" % ", ".join(invalid_tags))

static func _validate_set_bonuses(issues: Array[Dictionary], set_bonuses: Dictionary) -> void:
	for family_id in _sorted_keys(set_bonuses):
		var definition_variant: Variant = set_bonuses[family_id]
		if not (definition_variant is Dictionary):
			_add_error(issues, "set_bonus_type", "set_bonus", family_id, "Set-bonus definition must be a dictionary.")
			continue
		var definition: Dictionary = definition_variant
		var embedded_id := str(definition.get("id", "")).strip_edges()
		if embedded_id != "" and embedded_id != family_id:
			_add_error(issues, "set_bonus_id_mismatch", "set_bonus", family_id, "Embedded id '%s' does not match registry key." % embedded_id)
		var thresholds_variant: Variant = definition.get("thresholds", [])
		if not (thresholds_variant is Array):
			_add_error(issues, "set_bonus_thresholds_type", "set_bonus", family_id, "thresholds must be an array.")
			continue
		var pieces_present: Dictionary = {}
		for threshold_variant in thresholds_variant:
			if not (threshold_variant is Dictionary):
				_add_error(issues, "set_bonus_threshold_type", "set_bonus", family_id, "thresholds contains a non-dictionary entry.")
				continue
			var threshold: Dictionary = threshold_variant
			var pieces := int(threshold.get("pieces", 0))
			if pieces <= 0:
				_add_error(issues, "set_bonus_pieces", "set_bonus", family_id, "Threshold pieces must be positive.")
				continue
			if pieces_present.has(pieces):
				_add_error(issues, "set_bonus_duplicate_threshold", "set_bonus", family_id, "Duplicate %d-piece threshold." % pieces)
			pieces_present[pieces] = true
			var effects_variant: Variant = threshold.get("effects", [])
			if not (effects_variant is Array) or (effects_variant as Array).is_empty():
				_add_error(issues, "set_bonus_effects", "set_bonus", family_id, "%d-piece threshold must contain effects." % pieces)
		for required_pieces in REQUIRED_SET_THRESHOLDS:
			if not pieces_present.has(required_pieces):
				_add_error(issues, "set_bonus_required_threshold", "set_bonus", family_id, "Missing required %d-piece threshold." % required_pieces)

static func _validate_embedded_id(
	issues: Array[Dictionary],
	category: String,
	registry_id: String,
	entry: Variant
) -> void:
	var embedded_id := str(_value(entry, "id", "")).strip_edges()
	if embedded_id == "":
		_add_error(issues, "%s_id_missing" % category, category, registry_id, "Entry is missing id.")
	elif embedded_id != registry_id:
		_add_error(issues, "%s_id_mismatch" % category, category, registry_id, "Embedded id '%s' does not match registry key." % embedded_id)

static func _weapon_family(weapon: Object) -> String:
	if weapon.has_method("get_family_value"):
		return str(weapon.call("get_family_value")).strip_edges()
	return str(_value(weapon, "family", "")).strip_edges()

static func _weapon_damage(weapon: Object) -> float:
	if weapon.has_method("get_damage_value"):
		return float(weapon.call("get_damage_value"))
	return float(_value(weapon, "base_damage", 0.0))

static func _weapon_cooldown(weapon: Object) -> float:
	if weapon.has_method("get_cooldown_value"):
		return float(weapon.call("get_cooldown_value"))
	return float(_value(weapon, "cooldown", 0.0))

static func _weapon_range(weapon: Object) -> float:
	if weapon.has_method("get_attack_range_value"):
		return float(weapon.call("get_attack_range_value"))
	return float(_value(weapon, "range", 0.0))

static func _is_placeholder_weapon(weapon: Object) -> bool:
	var weapon_id := str(_value(weapon, "id", ""))
	return weapon_id.contains("placeholder") or _weapon_family(weapon).contains("placeholder")

static func _dictionary_property(owner: Object, property_name: String) -> Dictionary:
	var value: Variant = owner.get(property_name)
	return value if value is Dictionary else {}

static func _value(entry: Variant, key: String, fallback: Variant) -> Variant:
	if entry is Dictionary:
		return (entry as Dictionary).get(key, fallback)
	if entry is Object:
		var value: Variant = (entry as Object).get(key)
		return fallback if value == null else value
	return fallback

static func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		return result
	for item in value:
		result.append(str(item).strip_edges())
	return result

static func _sorted_keys(dictionary: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for key in dictionary.keys():
		result.append(str(key))
	result.sort()
	return result

static func _add_error(issues: Array[Dictionary], code: String, category: String, entry_id: String, message: String) -> void:
	_add_issue(issues, "error", code, category, entry_id, message)

static func _add_warning(issues: Array[Dictionary], code: String, category: String, entry_id: String, message: String) -> void:
	_add_issue(issues, "warning", code, category, entry_id, message)

static func _add_issue(
	issues: Array[Dictionary],
	severity: String,
	code: String,
	category: String,
	entry_id: String,
	message: String
) -> void:
	issues.append({
		"severity": severity,
		"code": code,
		"category": category,
		"id": entry_id,
		"message": message
	})

static func _build_report(issues: Array[Dictionary], counts: Dictionary) -> Dictionary:
	var error_count := 0
	var warning_count := 0
	for issue in issues:
		if str(issue.get("severity", "")) == "error":
			error_count += 1
		elif str(issue.get("severity", "")) == "warning":
			warning_count += 1
	return {
		"valid": error_count == 0,
		"error_count": error_count,
		"warning_count": warning_count,
		"issues": issues.duplicate(true),
		"counts": counts.duplicate(true)
	}
