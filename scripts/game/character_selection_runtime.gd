class_name CharacterSelectionRuntime
extends RefCounted

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
		"display_names": build_display_names(data_registry, normalized_ids)
	}

static func normalize_character_ids(ids: Array) -> Array[String]:
	var normalized: Array[String] = []
	for id_value in ids:
		var id_string := str(id_value)
		if id_string != "":
			normalized.append(id_string)
	return normalized

static func extract_ids(selection_state: Dictionary) -> Array[String]:
	var ids_variant: Variant = selection_state.get("ids", [])
	if ids_variant is Array:
		return normalize_character_ids(ids_variant as Array)
	return []

static func extract_display_names(selection_state: Dictionary) -> Dictionary:
	var display_names_variant: Variant = selection_state.get("display_names", {})
	if display_names_variant is Dictionary:
		return display_names_variant as Dictionary
	return {}

static func next_character_index(character_ids: Array[String], current_index: int) -> int:
	if character_ids.is_empty():
		return current_index
	return (current_index + 1) % character_ids.size()

static func build_selection_label(
	character_ids: Array[String],
	display_names: Dictionary,
	selected_index: int
) -> String:
	if character_ids.is_empty():
		return ""
	var clamped_index := clampi(selected_index, 0, character_ids.size() - 1)
	var selected_id := character_ids[clamped_index]
	var display_name := str(display_names.get(selected_id, selected_id))
	return "Selected: %s (C to cycle, Enter to start)" % display_name

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
		"display_names": {fallback_character_id: fallback_display_name}
	}
