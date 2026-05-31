extends Node

signal loadout_changed

const MAX_WEAPON_SLOTS: int = 6
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]

@export var equipped_weapon_ids: Array[String] = []
var equipped_weapons: Array[Dictionary] = []

func _ready() -> void:
	_migrate_legacy_ids_if_needed()
	_sync_legacy_ids()

func has_space() -> bool:
	return equipped_weapons.size() < MAX_WEAPON_SLOTS

func can_grant_weapon(weapon_id: String) -> bool:
	if weapon_id == "":
		return false
	if has_space():
		return true
	return _find_upgrade_target_for_incoming(weapon_id, "common") != -1

func get_grant_block_reason(weapon_id: String) -> String:
	if weapon_id == "":
		return "Missing weapon id."
	if has_space():
		return ""
	if _find_upgrade_target_for_incoming(weapon_id, "common") != -1:
		return ""
	return "Need matching %s (Common) to auto-combine." % _pretty_weapon_name(weapon_id)

func can_merge_slot(slot_index: int) -> bool:
	var result := _evaluate_slot_merge(slot_index)
	return bool(result.get("can_merge", false))

func get_merge_slot_state(slot_index: int) -> Dictionary:
	var result := _evaluate_slot_merge(slot_index)
	return {
		"state": "merge_available" if bool(result.get("can_merge", false)) else "merge_blocked",
		"can_merge": bool(result.get("can_merge", false)),
		"message": str(result.get("message", ""))
	}

func try_merge_slot(slot_index: int) -> Dictionary:
	var result := _evaluate_slot_merge(slot_index)
	if not bool(result.get("can_merge", false)):
		return {
			"success": false,
			"message": str(result.get("message", "Cannot merge this slot.")),
			"new_rarity": str(result.get("new_rarity", ""))
		}
	var target_index := int(result.get("target_index", -1))
	var partner_index := int(result.get("partner_index", -1))
	if target_index < 0 or partner_index < 0:
		return {"success": false, "message": "Cannot merge this slot.", "new_rarity": ""}
	var current_entry: Dictionary = equipped_weapons[target_index]
	var next_rarity := str(result.get("new_rarity", ""))
	equipped_weapons.remove_at(partner_index)
	if partner_index < target_index:
		target_index -= 1
	current_entry["rarity"] = next_rarity
	equipped_weapons[target_index] = current_entry
	_sync_legacy_ids()
	loadout_changed.emit()
	return {"success": true, "message": "Merged to %s." % next_rarity.capitalize(), "new_rarity": next_rarity}

# Fallback alias for existing player code that might call can_equip_more
func can_equip_more() -> bool:
	return has_space()

func get_weapon_count() -> int:
	return equipped_weapons.size()

func get_equipped_weapon_ids() -> Array[String]:
	return equipped_weapon_ids.duplicate()

func get_weapon_entries() -> Array[Dictionary]:
	var copied_entries: Array[Dictionary] = []
	for entry_variant in equipped_weapons:
		if entry_variant is Dictionary:
			copied_entries.append((entry_variant as Dictionary).duplicate(true))
	return copied_entries

func equip_weapon(weapon_id: String) -> bool:
	if weapon_id == "":
		return false
	if not has_space():
		return false
	equipped_weapons.append({"id": weapon_id, "rarity": "common"})
	_sync_legacy_ids()
	loadout_changed.emit()
	return true

func grant_or_combine_weapon(weapon_id: String) -> Dictionary:
	if weapon_id == "":
		return {"success": false, "combined": false, "rarity": ""}
	if has_space():
		equipped_weapons.append({"id": weapon_id, "rarity": "common"})
		_sync_legacy_ids()
		loadout_changed.emit()
		return {"success": true, "combined": false, "rarity": "common"}

	var target_index := _find_upgrade_target_for_incoming(weapon_id, "common")
	if target_index == -1:
		return {"success": false, "combined": false, "rarity": ""}
	var current_entry: Dictionary = equipped_weapons[target_index]
	var current_rarity := str(current_entry.get("rarity", "common"))
	var next_rarity := _next_rarity(current_rarity)
	if next_rarity == current_rarity:
		return {"success": false, "combined": true, "rarity": current_rarity}
	current_entry["rarity"] = next_rarity
	equipped_weapons[target_index] = current_entry
	_sync_legacy_ids()
	loadout_changed.emit()
	return {"success": true, "combined": true, "rarity": next_rarity}

func clear_loadout() -> void:
	equipped_weapons.clear()
	equipped_weapon_ids.clear()
	loadout_changed.emit()

func get_family_counts() -> Dictionary:
	var family_counts: Dictionary = {}
	for weapon_entry_variant in equipped_weapons:
		if not (weapon_entry_variant is Dictionary):
			continue
		var weapon_entry: Dictionary = weapon_entry_variant
		var weapon_id := str(weapon_entry.get("id", ""))
		if weapon_id == "":
			continue
		var family_id := _get_family_id_from_weapon_id(weapon_id)
		family_counts[family_id] = int(family_counts.get(family_id, 0)) + 1
	return family_counts

func debug_equip_duplicate_weapons(weapon_id: String, count: int) -> void:
	var requested_count := maxi(count, 0)
	for _index in requested_count:
		if not equip_weapon(weapon_id):
			break
	print("WeaponLoadout debug equip: %s -> %s" % [weapon_id, equipped_weapon_ids])
	print("Weapon family counts: %s" % get_family_counts())

func get_weapon_rarity(weapon_id: String) -> String:
	var entry_index := _find_weapon_entry_index(weapon_id)
	if entry_index == -1:
		return "common"
	var entry: Dictionary = equipped_weapons[entry_index]
	return str(entry.get("rarity", "common"))

func _find_weapon_entry_index(weapon_id: String) -> int:
	for index in range(equipped_weapons.size()):
		var entry_variant := equipped_weapons[index]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("id", "")) == weapon_id:
			return index
	return -1

func _find_combine_pair(weapon_id: String) -> Array[int]:
	var rarity_indexes: Dictionary = {}
	for index in range(equipped_weapons.size()):
		var entry_variant := equipped_weapons[index]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("id", "")) != weapon_id:
			continue
		var rarity := str(entry.get("rarity", "common"))
		if _next_rarity(rarity) == rarity:
			continue
		if not rarity_indexes.has(rarity):
			rarity_indexes[rarity] = []
		var rarity_list: Array = rarity_indexes[rarity]
		rarity_list.append(index)
		rarity_indexes[rarity] = rarity_list
	for rarity_name in RARITY_ORDER:
		var indexes_variant: Variant = rarity_indexes.get(rarity_name, [])
		if indexes_variant is Array:
			var indexes: Array = indexes_variant
			if indexes.size() >= 2:
				return [int(indexes[0]), int(indexes[1])]
	return []

func _find_upgrade_target_for_incoming(weapon_id: String, incoming_rarity: String = "common") -> int:
	if _next_rarity(incoming_rarity) == incoming_rarity:
		return -1
	for index in range(equipped_weapons.size()):
		var entry_variant := equipped_weapons[index]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("id", "")) != weapon_id:
			continue
		if str(entry.get("rarity", "common")) != incoming_rarity:
			continue
		return index
	return -1

func _evaluate_slot_merge(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= equipped_weapons.size():
		return {"can_merge": false, "message": "Invalid slot."}
	var entry_variant := equipped_weapons[slot_index]
	if not (entry_variant is Dictionary):
		return {"can_merge": false, "message": "Invalid weapon entry."}
	var entry: Dictionary = entry_variant
	var weapon_id := str(entry.get("id", ""))
	if weapon_id == "":
		return {"can_merge": false, "message": "Empty slot."}
	var rarity := str(entry.get("rarity", "common"))
	var next_rarity := _next_rarity(rarity)
	if next_rarity == rarity:
		return {"can_merge": false, "message": "%s is already Legendary." % _pretty_weapon_name(weapon_id)}
	var partner_index := _find_matching_slot_partner(slot_index, weapon_id, rarity)
	if partner_index == -1:
		return {
			"can_merge": false,
			"message": "Need another %s (%s)." % [_pretty_weapon_name(weapon_id), rarity.capitalize()]
		}
	var target_index := slot_index
	var consume_index := partner_index
	return {
		"can_merge": true,
		"message": "Merge ready.",
		"target_index": target_index,
		"partner_index": consume_index,
		"new_rarity": next_rarity
	}

func _find_matching_slot_partner(slot_index: int, weapon_id: String, rarity: String) -> int:
	for index in range(equipped_weapons.size()):
		if index == slot_index:
			continue
		var entry_variant := equipped_weapons[index]
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = entry_variant
		if str(entry.get("id", "")) != weapon_id:
			continue
		if str(entry.get("rarity", "common")) != rarity:
			continue
		return index
	return -1

func _pretty_weapon_name(weapon_id: String) -> String:
	return weapon_id.replace("_", " ").capitalize()

func _next_rarity(current_rarity: String) -> String:
	var rarity_index := RARITY_ORDER.find(current_rarity)
	if rarity_index == -1:
		return "common"
	if rarity_index >= RARITY_ORDER.size() - 1:
		return current_rarity
	return RARITY_ORDER[rarity_index + 1]

func _sync_legacy_ids() -> void:
	equipped_weapon_ids.clear()
	for entry_variant in equipped_weapons:
		if entry_variant is Dictionary:
			var entry: Dictionary = entry_variant
			var weapon_id := str(entry.get("id", ""))
			if weapon_id != "":
				equipped_weapon_ids.append(weapon_id)

func _migrate_legacy_ids_if_needed() -> void:
	if not equipped_weapons.is_empty() or equipped_weapon_ids.is_empty():
		return
	for weapon_id in equipped_weapon_ids:
		equipped_weapons.append({"id": weapon_id, "rarity": "common"})

func _get_family_id_from_weapon_id(weapon_id: String) -> String:
	# Try to load the weapon data to get its actual family, to respect Stage 8.1
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if ResourceLoader.exists(resource_path):
		var weapon_data := load(resource_path) as WeaponData
		if weapon_data != null and weapon_data.family != "":
			return weapon_data.family
		elif weapon_data != null and weapon_data.family_id != "":
			return weapon_data.family_id
			
	# Fallback parsing
	if "/" in weapon_id:
		return weapon_id.split("/", false, 1)[0]
	if "_" in weapon_id:
		return weapon_id.split("_", false, 1)[0]
	return weapon_id
