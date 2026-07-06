class_name CharacterSelectionRuntime
extends RefCounted

static var pending_character_id: String = ""

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
			"identity_summary": "",
			"passive_name": "",
			"passive_summary": "",
			"playstyle_tags": [],
			"difficulty": "medium"
		}
		if data_registry != null and data_registry.has_method("get_character"):
			var character_variant: Variant = data_registry.call("get_character", character_id)
			if character_variant is Dictionary:
				var character_data: Dictionary = character_variant
				var presentation_variant: Variant = character_data.get("presentation", {})
				if presentation_variant is Dictionary:
					var presentation: Dictionary = presentation_variant
					default_presentation["headline"] = str(presentation.get("headline", ""))
					default_presentation["identity_summary"] = str(presentation.get("identity_summary", ""))
					default_presentation["passive_name"] = str(presentation.get("passive_name", ""))
					default_presentation["passive_summary"] = str(presentation.get("passive_summary", ""))
					default_presentation["difficulty"] = str(presentation.get("difficulty", "medium"))
					var playstyle_tags_variant: Variant = presentation.get("playstyle_tags", [])
					if playstyle_tags_variant is Array:
						default_presentation["playstyle_tags"] = playstyle_tags_variant
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
				"identity_summary": "",
				"passive_name": "",
				"passive_summary": "",
				"playstyle_tags": [],
				"difficulty": "medium"
			}
		}
	}

static func set_pending_character_id(character_id: String) -> void:
	pending_character_id = character_id

static func get_pending_character_id() -> String:
	return pending_character_id

static func consume_pending_character_id() -> String:
	var current := pending_character_id
	pending_character_id = ""
	return current
