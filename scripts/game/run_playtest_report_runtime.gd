class_name RunPlaytestReportRuntime
extends RefCounted

static func build_identity_lines(run_rng: Node, player: Node, player_snapshot: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("Run seed: %s" % _resolve_seed(run_rng))
	lines.append("Hunter: %s" % _resolve_hunter(player))
	lines.append("Arsenal: %s" % _resolve_arsenal_summary(player_snapshot))
	return lines

static func build_report(
	result_state: String,
	run_rng: Node,
	player: Node,
	player_snapshot: Dictionary,
	wave_index: int
) -> String:
	return "PLAYTEST REPORT | result=%s | seed=%s | hunter=%s | wave=%d | level=%d | gold=%d | weapons=%s | items=%s | ascension=%s" % [
		result_state,
		_resolve_seed(run_rng),
		_resolve_hunter_id(player),
		wave_index,
		int(player_snapshot.get("level", 1)),
		int(player_snapshot.get("gold", 0)),
		_resolve_arsenal_ids(player_snapshot),
		_resolve_item_ids(player_snapshot),
		_resolve_ascension_id(player_snapshot)
	]

static func build_console_report(
	result_state: String,
	run_rng: Node,
	player: Node,
	player_snapshot: Dictionary,
	wave_index: int
) -> String:
	return build_report(result_state, run_rng, player, player_snapshot, wave_index)

static func _resolve_seed(run_rng: Node) -> String:
	if run_rng != null and run_rng.has_method("current_seed"):
		return str(run_rng.call("current_seed"))
	return "-"

static func _resolve_hunter(player: Node) -> String:
	if player == null or not is_instance_valid(player):
		return "-"
	var data_variant: Variant = player.get("active_character_data")
	if data_variant is Dictionary:
		var display_name := str((data_variant as Dictionary).get("display_name", "")).strip_edges()
		if display_name != "":
			return display_name
	var character_id := _resolve_hunter_id(player)
	return character_id.replace("_", " ").capitalize() if character_id != "-" else "-"

static func _resolve_hunter_id(player: Node) -> String:
	if player == null or not is_instance_valid(player):
		return "-"
	var character_id := str(player.get("active_character_id")).strip_edges()
	return character_id if character_id != "" else "-"

static func _resolve_arsenal_summary(player_snapshot: Dictionary) -> String:
	var entries := _weapon_entries(player_snapshot)
	if entries.is_empty():
		return "None"
	var first: Dictionary = entries[0]
	var first_name := str(first.get("display_name", first.get("id", "Weapon"))).strip_edges()
	var first_rarity := str(first.get("rarity", "common")).capitalize()
	if entries.size() == 1:
		return "%s · %s" % [first_name, first_rarity]
	return "%s · %s +%d" % [first_name, first_rarity, entries.size() - 1]

static func _resolve_arsenal_ids(player_snapshot: Dictionary) -> String:
	var parts: Array[String] = []
	for entry in _weapon_entries(player_snapshot):
		var weapon_id := str(entry.get("id", "")).strip_edges()
		if weapon_id == "":
			continue
		parts.append("%s:%s" % [weapon_id, str(entry.get("rarity", "common"))])
	return ",".join(parts) if not parts.is_empty() else "none"

static func _resolve_item_ids(player_snapshot: Dictionary) -> String:
	var parts: Array[String] = []
	var items_variant: Variant = player_snapshot.get("items", [])
	if not (items_variant is Array):
		return "none"
	for item_variant in items_variant:
		var item_id := ""
		if item_variant is ItemData:
			item_id = str((item_variant as ItemData).id).strip_edges()
		elif item_variant is Dictionary:
			item_id = str((item_variant as Dictionary).get("id", "")).strip_edges()
		if item_id != "":
			parts.append(item_id)
	parts.sort()
	return ",".join(parts) if not parts.is_empty() else "none"

static func _resolve_ascension_id(player_snapshot: Dictionary) -> String:
	var ascension_variant: Variant = player_snapshot.get("ascension", {})
	if not (ascension_variant is Dictionary):
		return "none"
	var ascension_id := str((ascension_variant as Dictionary).get("active_ascension_id", "")).strip_edges()
	return ascension_id if ascension_id != "" else "none"

static func _weapon_entries(player_snapshot: Dictionary) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var entries_variant: Variant = player_snapshot.get("weapon_entries", [])
	if not (entries_variant is Array):
		return entries
	for entry_variant in entries_variant:
		if entry_variant is Dictionary:
			entries.append(entry_variant as Dictionary)
	return entries
