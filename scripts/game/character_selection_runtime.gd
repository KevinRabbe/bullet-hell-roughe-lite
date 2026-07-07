class_name CharacterSelectionRuntime
extends RefCounted

static var pending_character_id: String = ""
static var pending_run_start_payload: Dictionary = {}

static func load_selection_state(data_registry: Node) -> Dictionary:
	if data_registry == null:
		return {}
	var ids_variant: Variant
	if data_registry.has_method("get_selectable_character_ids"):
		ids_variant = data_registry.call("get_selectable_character_ids")
	elif data_registry.has_method("get_character_ids"):
		ids_variant = data_registry.call("get_character_ids")
	else:
		return {}
	if not (ids_variant is Array):
		return build_fallback_state(data_registry)
	var ids: Array = ids_variant
	if ids.is_empty():
		return build_fallback_state(data_registry)
	var normalized_ids := normalize_character_ids(ids)
	if normalized_ids.is_empty():
		return build_fallback_state(data_registry)
	return {
		"ids": normalized_ids,
		"display_names": build_display_names(data_registry, normalized_ids),
		"presentations": build_presentations(data_registry, normalized_ids)
	}

static func set_pending_character_id(character_id: String) -> void:
	pending_character_id = character_id

static func get_pending_character_id() -> String:
	return pending_character_id

static func clear_pending_character_id() -> void:
	pending_character_id = ""

static func set_pending_run_start_payload(payload: Dictionary) -> void:
	pending_run_start_payload = payload.duplicate(true)

static func get_pending_run_start_payload() -> Dictionary:
	return pending_run_start_payload.duplicate(true)

static func consume_pending_run_start_payload() -> Dictionary:
	var payload := pending_run_start_payload.duplicate(true)
	pending_run_start_payload.clear()
	return payload

static func clear_pending_run_start_payload() -> void:
	pending_run_start_payload.clear()

static func build_starting_weapon_selection_state(data_registry: Node, character_id: String) -> Dictionary:
	if data_registry == null or character_id == "":
		return {}
	var character_data := _get_character_data(data_registry, character_id)
	if character_data.is_empty():
		return {}
	var starting_weapon_ids := _normalize_weapon_ids(character_data.get("starting_weapon_ids", []))
	if starting_weapon_ids.is_empty():
		return {}
	var weapon_options: Array[Dictionary] = []
	var default_weapon_id := ""
	for weapon_id in starting_weapon_ids:
		var weapon_option := _build_starting_weapon_option(data_registry, weapon_id)
		if weapon_option.is_empty():
			continue
		if default_weapon_id == "":
			default_weapon_id = weapon_id
			weapon_option["default_selected"] = true
		else:
			weapon_option["default_selected"] = false
		weapon_options.append(weapon_option)
	if weapon_options.is_empty():
		return {}
	var presentation_variant: Variant = character_data.get("presentation", {})
	var presentation := presentation_variant if presentation_variant is Dictionary else {}
	return {
		"character_id": character_id,
		"display_name": str(character_data.get("display_name", character_id)),
		"visual_path": str(character_data.get("visual_path", "")),
		"family_id": str(character_data.get("preferred_weapon_family", "")),
		"fantasy_hook": str(presentation.get("fantasy_hook", "")),
		"weapon_options": weapon_options,
		"default_weapon_id": default_weapon_id
	}

static func build_run_start_payload(data_registry: Node, character_id: String, starting_weapon_id: String = "") -> Dictionary:
	if data_registry == null or character_id == "":
		return {}
	var character_data := _get_character_data(data_registry, character_id)
	if character_data.is_empty():
		return {}
	var valid_weapon_ids := _normalize_weapon_ids(character_data.get("starting_weapon_ids", []))
	if valid_weapon_ids.is_empty():
		return {}
	var resolved_weapon_id := starting_weapon_id
	if resolved_weapon_id == "" or valid_weapon_ids.find(resolved_weapon_id) == -1:
		resolved_weapon_id = valid_weapon_ids[0]
	return {
		"character_id": character_id,
		"starting_weapon_id": resolved_weapon_id
	}

static func normalize_character_ids(ids: Array) -> Array[String]:
	var normalized: Array[String] = []
	for id_value in ids:
		var id_string := str(id_value)
		if id_string != "":
			normalized.append(id_string)
	return normalized

static func build_display_names(data_registry: Node, character_ids: Array[String]) -> Dictionary:
	var display_names: Dictionary = {}
	for character_id in character_ids:
		var default_name := str(character_id)
		var display_name := default_name
		if data_registry != null and data_registry.has_method("get_character"):
			var character_variant: Variant = data_registry.call("get_character", character_id)
			if character_variant is Dictionary:
				display_name = str(character_variant.get("display_name", default_name))
		display_names[character_id] = display_name
	return display_names

static func build_presentations(data_registry: Node, character_ids: Array[String]) -> Dictionary:
	var presentations: Dictionary = {}
	for character_id in character_ids:
		var default_presentation := {
			"headline": "",
			"fantasy_hook": "",
			"identity_summary": "",
			"passive_name": "",
			"passive_summary": "",
			"playstyle_tags": [],
			"difficulty": "medium",
			"starter_weapon_label": "Starting Weapon",
			"arsenal_label": "Arsenal",
			"arsenal_preview": [],
			"strengths": [],
			"tradeoffs": []
		}
		if data_registry != null and data_registry.has_method("get_character"):
			var character_variant: Variant = data_registry.call("get_character", character_id)
			if character_variant is Dictionary:
				var character_data: Dictionary = character_variant
				var presentation_variant: Variant = character_data.get("presentation", {})
				if presentation_variant is Dictionary:
					var presentation: Dictionary = presentation_variant
					default_presentation["headline"] = str(presentation.get("headline", ""))
					default_presentation["fantasy_hook"] = str(presentation.get("fantasy_hook", ""))
					default_presentation["identity_summary"] = str(presentation.get("identity_summary", ""))
					default_presentation["passive_name"] = str(presentation.get("passive_name", ""))
					default_presentation["passive_summary"] = str(presentation.get("passive_summary", ""))
					default_presentation["difficulty"] = str(presentation.get("difficulty", "medium"))
					default_presentation["starter_weapon_label"] = str(presentation.get("starter_weapon_label", "Starting Weapon"))
					default_presentation["arsenal_label"] = str(presentation.get("arsenal_label", "Arsenal"))
					var playstyle_tags_variant: Variant = presentation.get("playstyle_tags", [])
					if playstyle_tags_variant is Array:
						default_presentation["playstyle_tags"] = playstyle_tags_variant
					var arsenal_preview_variant: Variant = presentation.get("arsenal_preview", [])
					if arsenal_preview_variant is Array:
						default_presentation["arsenal_preview"] = arsenal_preview_variant
					var strengths_variant: Variant = presentation.get("strengths", [])
					if strengths_variant is Array:
						default_presentation["strengths"] = strengths_variant
					var tradeoffs_variant: Variant = presentation.get("tradeoffs", [])
					if tradeoffs_variant is Array:
						default_presentation["tradeoffs"] = tradeoffs_variant
		presentations[character_id] = default_presentation
	return presentations

static func build_fallback_state(data_registry: Node) -> Dictionary:
	if data_registry == null or not data_registry.has_method("get_default_selectable_character_id"):
		return {}
	var fallback_character_id := str(data_registry.call("get_default_selectable_character_id"))
	if fallback_character_id == "":
		return {}
	var fallback_display_name := fallback_character_id
	if data_registry.has_method("get_character_display_name"):
		fallback_display_name = str(data_registry.call("get_character_display_name", fallback_character_id))
	return {
		"ids": [fallback_character_id],
		"display_names": {fallback_character_id: fallback_display_name},
		"presentations": {
			fallback_character_id: {
				"headline": "",
				"fantasy_hook": "",
				"identity_summary": "",
				"passive_name": "",
				"passive_summary": "",
				"playstyle_tags": [],
				"difficulty": "medium",
				"starter_weapon_label": "Starting Weapon",
				"arsenal_label": "Arsenal",
				"arsenal_preview": [],
				"strengths": [],
				"tradeoffs": []
			}
		}
	}

static func _get_character_data(data_registry: Node, character_id: String) -> Dictionary:
	if data_registry == null or character_id == "" or not data_registry.has_method("get_character"):
		return {}
	var character_variant: Variant = data_registry.call("get_character", character_id)
	if character_variant is Dictionary:
		return (character_variant as Dictionary).duplicate(true)
	return {}

static func _normalize_weapon_ids(weapon_ids_variant: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if not (weapon_ids_variant is Array):
		return normalized
	for weapon_id_variant in weapon_ids_variant:
		var weapon_id := str(weapon_id_variant)
		if weapon_id != "":
			normalized.append(weapon_id)
	return normalized

static func _build_starting_weapon_option(data_registry: Node, weapon_id: String) -> Dictionary:
	if data_registry == null or weapon_id == "" or not data_registry.has_method("get_weapon"):
		return {}
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		return {
			"id": weapon_id,
			"display_name": weapon_resource.display_name if weapon_resource.display_name != "" else weapon_id,
			"description": weapon_resource.description,
			"tags": weapon_resource.tags.duplicate(),
			"icon_path": weapon_resource.icon.resource_path if weapon_resource.icon != null else "",
			"family_id": weapon_resource.get_family_value()
		}
	if weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		var tags: Array[String] = []
		var tags_variant: Variant = weapon_data.get("tags", [])
		if tags_variant is Array:
			for tag_variant in tags_variant:
				tags.append(str(tag_variant))
		return {
			"id": weapon_id,
			"display_name": str(weapon_data.get("display_name", weapon_id)),
			"description": str(weapon_data.get("description", "")),
			"tags": tags,
			"icon_path": "",
			"family_id": str(weapon_data.get("family", weapon_data.get("family_id", "")))
		}
	return {}
