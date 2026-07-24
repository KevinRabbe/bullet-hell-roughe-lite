class_name CharacterSelectionRuntime
extends RefCounted

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
	var entries := build_character_entries(data_registry, normalized_ids)
	return {
		"ids": normalized_ids,
		"entries": entries,
		"display_names": _map_entry_field(entries, "display_name"),
		"presentations": _map_nested_entry_field(entries, "presentation"),
		"details": _map_nested_entry_field(entries, "detail")
	}

static func normalize_character_ids(ids: Array) -> Array[String]:
	var normalized: Array[String] = []
	for id_value in ids:
		var id_string := str(id_value)
		if id_string != "":
			normalized.append(id_string)
	return normalized

static func build_character_entries(data_registry: Node, character_ids: Array[String]) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for character_id in character_ids:
		entries.append(_build_character_entry(data_registry, character_id))
	return entries

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
		var default_presentation := _build_character_presentation({})
		if data_registry != null and data_registry.has_method("get_character"):
			var character_variant: Variant = data_registry.call("get_character", character_id)
			if character_variant is Dictionary:
				var character_data: Dictionary = character_variant
				default_presentation = _build_character_presentation(character_data)
		presentations[character_id] = default_presentation
	return presentations

static func build_details(data_registry: Node, character_ids: Array[String]) -> Dictionary:
	var details: Dictionary = {}
	for character_id in character_ids:
		details[character_id] = _build_character_detail(data_registry, character_id)
	return details

static func _map_entry_field(entries: Array[Dictionary], field_name: String) -> Dictionary:
	var mapped: Dictionary = {}
	for entry in entries:
		var character_id := str(entry.get("id", ""))
		if character_id == "":
			continue
		mapped[character_id] = entry.get(field_name)
	return mapped

static func _map_nested_entry_field(entries: Array[Dictionary], field_name: String) -> Dictionary:
	var mapped: Dictionary = {}
	for entry in entries:
		var character_id := str(entry.get("id", ""))
		if character_id == "":
			continue
		var nested_variant: Variant = entry.get(field_name, {})
		mapped[character_id] = nested_variant if nested_variant is Dictionary else {}
	return mapped

static func _build_character_entry(data_registry: Node, character_id: String) -> Dictionary:
	var character_data: Dictionary = {}
	if data_registry != null and data_registry.has_method("get_character"):
		var character_variant: Variant = data_registry.call("get_character", character_id)
		if character_variant is Dictionary:
			character_data = character_variant
	var display_name := str(character_data.get("display_name", character_id))
	var starting_weapon_ids := _normalize_string_array(character_data.get("starting_weapon_ids", []))
	var family_weapon_ids := _normalize_string_array(character_data.get("family_weapon_ids", []))
	var presentation := _build_character_presentation(character_data)
	var detail := _build_character_detail(data_registry, character_id)
	var readiness := _build_character_readiness(character_data, starting_weapon_ids, family_weapon_ids)
	return {
		"id": character_id,
		"display_name": display_name,
		"roster_order": int(character_data.get("roster_order", 9999)),
		"selectable": character_data.get("selectable", true) != false,
		"visual_path": str(character_data.get("visual_path", "")),
		"visual_scale": float(character_data.get("visual_scale", 1.0)),
		"preferred_weapon_family": str(character_data.get("preferred_weapon_family", "")),
		"starting_weapon_ids": starting_weapon_ids,
		"family_weapon_ids": family_weapon_ids,
		"starting_weapon_count": starting_weapon_ids.size(),
		"family_weapon_count": family_weapon_ids.size(),
		"is_ready_for_run_start": readiness.get("is_ready", false) == true,
		"readiness_reason": str(readiness.get("reason", "")),
		"presentation": presentation,
		"detail": detail
	}

static func _build_character_readiness(character_data: Dictionary, starting_weapon_ids: Array[String], family_weapon_ids: Array[String]) -> Dictionary:
	var visual_path := str(character_data.get("visual_path", ""))
	if visual_path == "":
		return {"is_ready": false, "reason": "Missing visual path"}
	if not ResourceLoader.exists(visual_path):
		return {"is_ready": false, "reason": "Missing visual resource"}
	if starting_weapon_ids.is_empty():
		return {"is_ready": false, "reason": "Missing starting weapon"}
	for weapon_id in starting_weapon_ids:
		if not ResourceLoader.exists("res://data/weapons/%s.tres" % weapon_id):
			return {"is_ready": false, "reason": "Missing starting weapon resource"}
	if family_weapon_ids.is_empty():
		return {"is_ready": false, "reason": "Missing family arsenal"}
	var presentation_variant: Variant = character_data.get("presentation", {})
	if not (presentation_variant is Dictionary):
		return {"is_ready": false, "reason": "Missing presentation block"}
	var presentation: Dictionary = presentation_variant
	if str(presentation.get("headline", "")) == "":
		return {"is_ready": false, "reason": "Missing presentation headline"}
	if str(presentation.get("fantasy_hook", "")) == "":
		return {"is_ready": false, "reason": "Missing fantasy hook"}
	if str(presentation.get("identity_summary", "")) == "":
		return {"is_ready": false, "reason": "Incomplete presentation copy"}
	if str(presentation.get("passive_name", "")) == "" or str(presentation.get("passive_summary", "")) == "":
		return {"is_ready": false, "reason": "Missing passive presentation"}
	if str(presentation.get("starter_weapon_label", "")) == "" or str(presentation.get("arsenal_label", "")) == "":
		return {"is_ready": false, "reason": "Missing presentation labels"}
	var strengths := _normalize_string_array(presentation.get("strengths", []))
	if strengths.is_empty():
		return {"is_ready": false, "reason": "Missing strengths list"}
	var tradeoffs := _normalize_string_array(presentation.get("tradeoffs", []))
	if tradeoffs.is_empty():
		return {"is_ready": false, "reason": "Missing tradeoffs list"}
	var arsenal_preview := _normalize_string_array(presentation.get("arsenal_preview", []))
	if arsenal_preview.is_empty():
		return {"is_ready": false, "reason": "Missing arsenal preview"}
	return {"is_ready": true, "reason": ""}

static func _build_character_presentation(character_data: Dictionary) -> Dictionary:
	var result := {
		"headline": "",
		"fantasy_hook": "",
		"identity_summary": "",
		"passive_name": "",
		"passive_summary": "",
		"passive_icon_path": "",
		"playstyle_tags": [],
		"difficulty": "medium",
		"starter_weapon_label": "Starting Weapon",
		"arsenal_label": "Arsenal",
		"arsenal_preview": [],
		"strengths": [],
		"tradeoffs": []
	}
	var presentation_variant: Variant = character_data.get("presentation", {})
	if not (presentation_variant is Dictionary):
		return result
	var presentation: Dictionary = presentation_variant
	result["headline"] = str(presentation.get("headline", ""))
	result["fantasy_hook"] = str(presentation.get("fantasy_hook", ""))
	result["identity_summary"] = str(presentation.get("identity_summary", ""))
	result["passive_name"] = str(presentation.get("passive_name", ""))
	result["passive_summary"] = str(presentation.get("passive_summary", ""))
	result["passive_icon_path"] = str(presentation.get("passive_icon_path", ""))
	result["difficulty"] = str(presentation.get("difficulty", "medium"))
	result["starter_weapon_label"] = str(presentation.get("starter_weapon_label", "Starting Weapon"))
	result["arsenal_label"] = str(presentation.get("arsenal_label", "Arsenal"))
	var playstyle_tags_variant: Variant = presentation.get("playstyle_tags", [])
	if playstyle_tags_variant is Array:
		result["playstyle_tags"] = playstyle_tags_variant
	var arsenal_preview_variant: Variant = presentation.get("arsenal_preview", [])
	if arsenal_preview_variant is Array:
		result["arsenal_preview"] = arsenal_preview_variant
	var strengths_variant: Variant = presentation.get("strengths", [])
	if strengths_variant is Array:
		result["strengths"] = strengths_variant
	var tradeoffs_variant: Variant = presentation.get("tradeoffs", [])
	if tradeoffs_variant is Array:
		result["tradeoffs"] = tradeoffs_variant
	return result

static func _build_character_detail(data_registry: Node, character_id: String) -> Dictionary:
	var detail := {
		"visual_path": "",
		"visual_scale": 1.0,
		"family_label": "",
		"fantasy_hook": "",
		"starter_weapon_names": [],
		"starter_weapon_label": "Starting Weapon",
		"starter_weapon_summary": "",
		"arsenal_names": [],
		"arsenal_label": "Arsenal",
		"passive_tags": [],
		"strengths": [],
		"tradeoffs": []
	}
	if data_registry == null or not data_registry.has_method("get_character"):
		return detail
	var character_variant: Variant = data_registry.call("get_character", character_id)
	if not (character_variant is Dictionary):
		return detail
	var character_data: Dictionary = character_variant
	var presentation := _build_character_presentation(character_data)
	detail["visual_path"] = str(character_data.get("visual_path", ""))
	detail["visual_scale"] = float(character_data.get("visual_scale", 1.0))
	detail["family_label"] = _humanize_family_id(str(character_data.get("preferred_weapon_family", "")))
	detail["fantasy_hook"] = str(presentation.get("fantasy_hook", ""))
	detail["starter_weapon_names"] = _resolve_weapon_names(data_registry, character_data.get("starting_weapon_ids", []))
	detail["starter_weapon_label"] = str(presentation.get("starter_weapon_label", "Starting Weapon"))
	detail["arsenal_names"] = _resolve_arsenal_names(data_registry, character_data, presentation)
	detail["arsenal_label"] = str(presentation.get("arsenal_label", "Arsenal"))
	detail["starter_weapon_summary"] = _build_starter_weapon_summary(data_registry, character_data.get("starting_weapon_ids", []))
	detail["passive_tags"] = _normalize_string_array(character_data.get("passive_tags", []))
	detail["strengths"] = _resolve_strengths(character_data, presentation)
	detail["tradeoffs"] = _resolve_tradeoffs(character_data, presentation)
	return detail

static func _resolve_weapon_names(data_registry: Node, weapon_ids_variant: Variant) -> Array[String]:
	var weapon_names: Array[String] = []
	if not (weapon_ids_variant is Array):
		return weapon_names
	var weapon_ids: Array = weapon_ids_variant
	for weapon_id_variant in weapon_ids:
		var weapon_id := str(weapon_id_variant)
		if weapon_id == "":
			continue
		var weapon_name := _resolve_weapon_name(data_registry, weapon_id)
		if weapon_name != "":
			weapon_names.append(weapon_name)
	return weapon_names

static func _build_starter_weapon_summary(data_registry: Node, weapon_ids_variant: Variant) -> String:
	if not (weapon_ids_variant is Array):
		return ""
	var weapon_ids: Array = weapon_ids_variant
	if weapon_ids.is_empty():
		return ""
	var first_weapon_id := str(weapon_ids[0])
	if first_weapon_id == "":
		return ""
	var weapon_name := _resolve_weapon_name(data_registry, first_weapon_id)
	var weapon_description := _resolve_weapon_description(data_registry, first_weapon_id)
	if weapon_name == "":
		return weapon_description
	if weapon_description == "":
		return weapon_name
	return "%s - %s" % [weapon_name, weapon_description]

static func _resolve_weapon_name(data_registry: Node, weapon_id: String) -> String:
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return weapon_id
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant == null:
		return weapon_id
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		if weapon_resource.display_name != "":
			return weapon_resource.display_name
	elif weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		var display_name := str(weapon_data.get("display_name", ""))
		if display_name != "":
			return display_name
	return weapon_id

static func _resolve_weapon_description(data_registry: Node, weapon_id: String) -> String:
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return ""
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant == null:
		return ""
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		return weapon_resource.description
	if weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		return str(weapon_data.get("description", ""))
	return ""

static func _normalize_string_array(values_variant: Variant) -> Array[String]:
	var normalized: Array[String] = []
	if not (values_variant is Array):
		return normalized
	var values: Array = values_variant
	for value_variant in values:
		var value := str(value_variant)
		if value != "":
			normalized.append(value)
	return normalized

static func _resolve_arsenal_names(data_registry: Node, character_data: Dictionary, presentation: Dictionary) -> Array[String]:
	var arsenal_preview := _normalize_string_array(presentation.get("arsenal_preview", []))
	if not arsenal_preview.is_empty():
		return arsenal_preview
	return _resolve_weapon_names(data_registry, character_data.get("family_weapon_ids", []))

static func _resolve_strengths(character_data: Dictionary, presentation: Dictionary) -> Array[String]:
	var configured_strengths := _normalize_string_array(presentation.get("strengths", []))
	if not configured_strengths.is_empty():
		return configured_strengths
	return _build_character_strengths(character_data)

static func _resolve_tradeoffs(character_data: Dictionary, presentation: Dictionary) -> Array[String]:
	var configured_tradeoffs := _normalize_string_array(presentation.get("tradeoffs", []))
	if not configured_tradeoffs.is_empty():
		return configured_tradeoffs
	return _build_character_tradeoffs(character_data)

static func _build_character_strengths(character_data: Dictionary) -> Array[String]:
	var strengths: Array[String] = []
	var stat_multipliers_variant: Variant = character_data.get("stat_multipliers", {})
	if stat_multipliers_variant is Dictionary:
		var stat_multipliers: Dictionary = stat_multipliers_variant
		for stat_id_variant in stat_multipliers.keys():
			var stat_id := str(stat_id_variant)
			var value := float(stat_multipliers.get(stat_id, 1.0))
			if value > 1.0:
				strengths.append("%s %+d%%" % [_humanize_stat_id(stat_id), int(round((value - 1.0) * 100.0))])
	var stat_bonuses_variant: Variant = character_data.get("stat_bonuses", {})
	if stat_bonuses_variant is Dictionary:
		var stat_bonuses: Dictionary = stat_bonuses_variant
		for stat_id_variant in stat_bonuses.keys():
			var stat_id := str(stat_id_variant)
			var value := float(stat_bonuses.get(stat_id, 0.0))
			if value > 0.0:
				strengths.append("%s +%s" % [_humanize_stat_id(stat_id), _format_stat_bonus(value)])
	return strengths

static func _build_character_tradeoffs(character_data: Dictionary) -> Array[String]:
	var tradeoffs: Array[String] = []
	var stat_multipliers_variant: Variant = character_data.get("stat_multipliers", {})
	if stat_multipliers_variant is Dictionary:
		var stat_multipliers: Dictionary = stat_multipliers_variant
		for stat_id_variant in stat_multipliers.keys():
			var stat_id := str(stat_id_variant)
			var value := float(stat_multipliers.get(stat_id, 1.0))
			if value < 1.0:
				tradeoffs.append("%s %d%%" % [_humanize_stat_id(stat_id), int(round(value * 100.0))])
	var stat_bonuses_variant: Variant = character_data.get("stat_bonuses", {})
	if stat_bonuses_variant is Dictionary:
		var stat_bonuses: Dictionary = stat_bonuses_variant
		for stat_id_variant in stat_bonuses.keys():
			var stat_id := str(stat_id_variant)
			var value := float(stat_bonuses.get(stat_id, 0.0))
			if value < 0.0:
				tradeoffs.append("%s %s" % [_humanize_stat_id(stat_id), _format_stat_bonus(value)])
	return tradeoffs

static func _humanize_family_id(family_id: String) -> String:
	if family_id == "":
		return "Unknown"
	var words: PackedStringArray = family_id.split("_")
	var capitalized: Array[String] = []
	for word in words:
		capitalized.append(word.capitalize())
	return " ".join(capitalized)

static func _humanize_stat_id(stat_id: String) -> String:
	var words: PackedStringArray = stat_id.split("_")
	var capitalized: Array[String] = []
	for word in words:
		capitalized.append(word.capitalize())
	return " ".join(capitalized)

static func _format_stat_bonus(value: float) -> String:
	if is_zero_approx(value - roundf(value)):
		return str(int(roundf(value)))
	return "%.2f" % value

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
		"entries": [{
			"id": fallback_character_id,
			"display_name": fallback_display_name,
			"roster_order": 9999,
			"selectable": true,
			"visual_path": "",
			"visual_scale": 1.0,
			"preferred_weapon_family": "",
			"starting_weapon_ids": [],
			"family_weapon_ids": [],
			"starting_weapon_count": 0,
			"family_weapon_count": 0,
			"is_ready_for_run_start": false,
			"readiness_reason": "Fallback character data only",
			"presentation": {
				"headline": "",
				"fantasy_hook": "",
				"identity_summary": "",
				"passive_name": "",
				"passive_summary": "",
				"passive_icon_path": "",
				"playstyle_tags": [],
				"difficulty": "medium",
				"starter_weapon_label": "Starting Weapon",
				"arsenal_label": "Arsenal",
				"arsenal_preview": [],
				"strengths": [],
				"tradeoffs": []
			},
			"detail": {
				"visual_path": "",
				"visual_scale": 1.0,
				"family_label": "Unknown",
				"fantasy_hook": "",
				"starter_weapon_names": [],
				"starter_weapon_label": "Starting Weapon",
				"starter_weapon_summary": "",
				"arsenal_names": [],
				"arsenal_label": "Arsenal",
				"passive_tags": [],
				"strengths": [],
				"tradeoffs": []
			}
		}],
		"display_names": {fallback_character_id: fallback_display_name},
		"presentations": {
			fallback_character_id: {
				"headline": "",
				"fantasy_hook": "",
				"identity_summary": "",
				"passive_name": "",
				"passive_summary": "",
				"passive_icon_path": "",
				"playstyle_tags": [],
				"difficulty": "medium",
				"starter_weapon_label": "Starting Weapon",
				"arsenal_label": "Arsenal",
				"arsenal_preview": [],
				"strengths": [],
				"tradeoffs": []
			}
		},
		"details": {
			fallback_character_id: {
				"visual_path": "",
				"visual_scale": 1.0,
				"family_label": "Unknown",
				"fantasy_hook": "",
				"starter_weapon_names": [],
				"starter_weapon_label": "Starting Weapon",
				"starter_weapon_summary": "",
				"arsenal_names": [],
				"arsenal_label": "Arsenal",
				"passive_tags": [],
				"strengths": [],
				"tradeoffs": []
			}
		}
	}

static func set_pending_character_id(character_id: String) -> void:
	pending_run_start_payload = build_run_start_payload(null, character_id)

static func get_pending_character_id() -> String:
	return str(pending_run_start_payload.get("character_id", ""))

static func consume_pending_character_id() -> String:
	var payload := consume_pending_run_start_payload()
	return str(payload.get("character_id", ""))

static func clear_pending_character_id() -> void:
	clear_pending_run_start_payload()

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

static func build_run_start_payload(data_registry: Node, character_id: String, starting_weapon_id: String = "") -> Dictionary:
	var resolved_character_id := character_id
	var resolved_starting_weapon_id := starting_weapon_id
	if resolved_character_id == "" and data_registry != null and data_registry.has_method("get_default_selectable_character_id"):
		resolved_character_id = str(data_registry.call("get_default_selectable_character_id"))
	if data_registry != null and data_registry.has_method("get_character"):
		var character_variant: Variant = data_registry.call("get_character", resolved_character_id)
		if character_variant is Dictionary:
			var character_data: Dictionary = character_variant
			var starting_ids := _normalize_string_array(character_data.get("starting_weapon_ids", []))
			if resolved_starting_weapon_id == "" or not starting_ids.has(resolved_starting_weapon_id):
				resolved_starting_weapon_id = ""
				for candidate_id in starting_ids:
					if candidate_id != "":
						resolved_starting_weapon_id = candidate_id
						break
	return {
		"character_id": resolved_character_id,
		"starting_weapon_id": resolved_starting_weapon_id
	}

static func build_starting_weapon_selection_state(data_registry: Node, character_id: String) -> Dictionary:
	var state := {
		"character_id": character_id,
		"display_name": character_id,
		"headline": "",
		"weapon_options": [],
		"character_entry": {},
		"selected_weapon_id": "",
		"selection_source": "default_starter"
	}
	if data_registry == null or not data_registry.has_method("get_character"):
		return state
	var character_entry := _build_character_entry(data_registry, character_id)
	state["character_entry"] = character_entry
	var character_variant: Variant = data_registry.call("get_character", character_id)
	if not (character_variant is Dictionary):
		return state
	var character_data: Dictionary = character_variant
	state["display_name"] = str(character_entry.get("display_name", character_id))
	var presentation_variant: Variant = character_entry.get("presentation", {})
	if presentation_variant is Dictionary:
		var presentation: Dictionary = presentation_variant
		state["headline"] = str(presentation.get("headline", ""))
	var starting_weapon_ids := _normalize_string_array(character_data.get("starting_weapon_ids", []))
	if starting_weapon_ids.is_empty():
		return state
	var remembered_weapon_id := _resolve_pending_starting_weapon_for_character(character_id)
	if remembered_weapon_id != "":
		state["selected_weapon_id"] = remembered_weapon_id
		state["selection_source"] = "remembered_choice"
	else:
		state["selected_weapon_id"] = starting_weapon_ids[0]
	var options: Array[Dictionary] = []
	for weapon_id in starting_weapon_ids:
		if weapon_id == "":
			continue
		var is_default_selected := weapon_id == str(state.get("selected_weapon_id", ""))
		options.append(_build_weapon_option(data_registry, weapon_id, is_default_selected))
	if remembered_weapon_id != "" and not _weapon_options_contain(options, remembered_weapon_id):
		state["selected_weapon_id"] = starting_weapon_ids[0]
		state["selection_source"] = "default_starter"
		for option in options:
			option["default_selected"] = str(option.get("id", "")) == starting_weapon_ids[0]
	state["weapon_options"] = options
	return state

static func _resolve_pending_starting_weapon_for_character(character_id: String) -> String:
	if str(pending_run_start_payload.get("character_id", "")) != character_id:
		return ""
	return str(pending_run_start_payload.get("starting_weapon_id", ""))

static func _weapon_options_contain(options: Array[Dictionary], weapon_id: String) -> bool:
	for option in options:
		if str(option.get("id", "")) == weapon_id:
			return true
	return false

static func _build_weapon_option(data_registry: Node, weapon_id: String, default_selected: bool) -> Dictionary:
	var option := {
		"id": weapon_id,
		"display_name": weapon_id,
		"description": "",
		"tags": [],
		"icon": null,
		"default_selected": default_selected
	}
	if data_registry == null or not data_registry.has_method("get_weapon"):
		return option
	var weapon_variant: Variant = data_registry.call("get_weapon", weapon_id)
	if weapon_variant is WeaponData:
		var weapon_resource: WeaponData = weapon_variant
		if weapon_resource.display_name != "":
			option["display_name"] = weapon_resource.display_name
		option["description"] = weapon_resource.description
		option["tags"] = _normalize_string_array(weapon_resource.tags)
		option["icon"] = weapon_resource.icon
	elif weapon_variant is Dictionary:
		var weapon_data: Dictionary = weapon_variant
		option["display_name"] = str(weapon_data.get("display_name", weapon_id))
		option["description"] = str(weapon_data.get("description", ""))
		option["tags"] = _normalize_string_array(weapon_data.get("tags", []))
	return option
