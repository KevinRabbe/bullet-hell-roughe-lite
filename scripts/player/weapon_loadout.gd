extends Node

const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")
const WeaponTagRuntimeRef = preload("res://scripts/weapons/weapon_tag_runtime.gd")

signal loadout_changed

const MAX_WEAPON_SLOTS: int = 6
const RARITY_ORDER: Array[String] = ["common", "rare", "epic", "legendary"]

@export var equipped_weapon_ids: Array[String] = []
var equipped_weapons: Array[Dictionary] = []
var _weapon_data_cache: Dictionary = {}

func _ready() -> void:
	_migrate_legacy_ids_if_needed()
	_sync_legacy_ids()

func has_space() -> bool:
	return equipped_weapons.size() < MAX_WEAPON_SLOTS

func can_grant_weapon(weapon_id: String, incoming_rarity: String = "common") -> bool:
	if weapon_id == "":
		return false
	if has_space():
		return true
	return _find_upgrade_target_for_incoming(weapon_id, incoming_rarity) != -1

func get_grant_block_reason(weapon_id: String, incoming_rarity: String = "common") -> String:
	if weapon_id == "":
		return "Missing weapon id."
	if has_space():
		return ""
	if _find_upgrade_target_for_incoming(weapon_id, incoming_rarity) != -1:
		return ""
	return "Need matching %s (%s) to auto-combine." % [_pretty_weapon_name(weapon_id), incoming_rarity.capitalize()]

func can_merge_slot(slot_index: int) -> bool:
	var result := _evaluate_slot_merge(slot_index)
	return result.get("can_merge", false) == true

func get_merge_slot_state(slot_index: int) -> Dictionary:
	var result := _evaluate_slot_merge(slot_index)
	return {
		"state": "merge_available" if result.get("can_merge", false) == true else "merge_blocked",
		"can_merge": result.get("can_merge", false) == true,
		"message": str(result.get("message", ""))
	}

func try_merge_slot(slot_index: int) -> Dictionary:
	var result := _evaluate_slot_merge(slot_index)
	if result.get("can_merge", false) != true:
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
	var partner_entry := _get_entry(partner_index)
	var next_rarity := str(result.get("new_rarity", ""))
	equipped_weapons.remove_at(partner_index)
	if partner_index < target_index:
		target_index -= 1
	current_entry["kill_count"] = int(current_entry.get("kill_count", 0)) + int(partner_entry.get("kill_count", 0))
	current_entry["milestones_earned"] = int(current_entry.get("milestones_earned", 0)) + int(partner_entry.get("milestones_earned", 0))
	current_entry["weapon_bonus_overrides"] = _merge_bonus_overrides(
		current_entry.get("weapon_bonus_overrides", {}),
		partner_entry.get("weapon_bonus_overrides", {})
	)
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
	equipped_weapons.append(_build_weapon_entry(weapon_id, "common"))
	_sync_legacy_ids()
	loadout_changed.emit()
	return true

func grant_or_combine_weapon(weapon_id: String, incoming_rarity: String = "common") -> Dictionary:
	if weapon_id == "":
		return {"success": false, "combined": false, "rarity": ""}
	if RARITY_ORDER.find(incoming_rarity) == -1:
		incoming_rarity = "common"
	if has_space():
		equipped_weapons.append(_build_weapon_entry(weapon_id, incoming_rarity))
		_sync_legacy_ids()
		loadout_changed.emit()
		return {"success": true, "combined": false, "rarity": incoming_rarity}

	var target_index := _find_upgrade_target_for_incoming(weapon_id, incoming_rarity)
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

func register_weapon_kill(slot_index: int, weapon_data: WeaponData, kill_requirement_multiplier: float = 1.0) -> Dictionary:
	if slot_index < 0 or slot_index >= equipped_weapons.size():
		return {"triggered": false}
	if weapon_data == null:
		return {"triggered": false}
	var entry := _get_entry(slot_index)
	entry["kill_count"] = int(entry.get("kill_count", 0)) + 1
	equipped_weapons[slot_index] = entry
	var base_kills := maxi(weapon_data.kill_milestone_base_kills, 0)
	if base_kills <= 0 or weapon_data.kill_milestone_stat_id == "" or is_zero_approx(weapon_data.kill_milestone_amount):
		return {"triggered": false}
	var required_kills := maxi(int(round(float(base_kills) * maxf(kill_requirement_multiplier, 0.01))), 1)
	var next_milestone := int(entry.get("milestones_earned", 0)) + 1
	var kill_count := int(entry.get("kill_count", 0))
	if kill_count < required_kills * next_milestone:
		return {"triggered": false}
	entry["milestones_earned"] = next_milestone
	if weapon_data.kill_milestone_scope == "weapon":
		entry["weapon_bonus_overrides"] = _apply_weapon_bonus_override(
			entry.get("weapon_bonus_overrides", {}),
			weapon_data.kill_milestone_stat_id,
			weapon_data.kill_milestone_amount
		)
	equipped_weapons[slot_index] = entry
	loadout_changed.emit()
	return {
		"triggered": true,
		"stat_id": weapon_data.kill_milestone_stat_id,
		"amount": weapon_data.kill_milestone_amount,
		"scope": weapon_data.kill_milestone_scope,
		"weapon_id": str(entry.get("id", "")),
		"kill_count": kill_count,
		"milestones_earned": next_milestone,
		"required_kills": required_kills
	}

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

func get_weapon_tag_counts() -> Dictionary:
	return WeaponTagRuntimeRef.build_weapon_tag_counts(equipped_weapons, Callable(self, "_load_weapon_data"))

func get_active_weapon_tags() -> Array[String]:
	return WeaponTagRuntimeRef.build_active_weapon_tags(equipped_weapons, Callable(self, "_load_weapon_data"))

func count_weapons_with_tag(tag: String) -> int:
	return WeaponTagRuntimeRef.count_equipped_weapons_with_tag(equipped_weapons, Callable(self, "_load_weapon_data"), tag)

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

func _get_entry(index: int) -> Dictionary:
	var entry_variant := equipped_weapons[index]
	if entry_variant is Dictionary:
		return (entry_variant as Dictionary).duplicate(true)
	return {}

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
		equipped_weapons.append(_build_weapon_entry(weapon_id, "common"))

func _build_weapon_entry(weapon_id: String, rarity: String) -> Dictionary:
	return {
		"id": weapon_id,
		"rarity": rarity,
		"kill_count": 0,
		"milestones_earned": 0,
		"weapon_bonus_overrides": {}
	}

func _apply_weapon_bonus_override(current_overrides_variant: Variant, stat_id: String, amount: float) -> Dictionary:
	var current_overrides: Dictionary = {}
	if current_overrides_variant is Dictionary:
		current_overrides = (current_overrides_variant as Dictionary).duplicate(true)
	current_overrides[stat_id] = float(current_overrides.get(stat_id, 0.0)) + amount
	return current_overrides

func _merge_bonus_overrides(left_variant: Variant, right_variant: Variant) -> Dictionary:
	var merged: Dictionary = {}
	if left_variant is Dictionary:
		for stat_id_variant in (left_variant as Dictionary).keys():
			var stat_id := str(stat_id_variant)
			merged[stat_id] = float((left_variant as Dictionary).get(stat_id, 0.0))
	if right_variant is Dictionary:
		for stat_id_variant in (right_variant as Dictionary).keys():
			var stat_id := str(stat_id_variant)
			merged[stat_id] = float(merged.get(stat_id, 0.0)) + float((right_variant as Dictionary).get(stat_id, 0.0))
	return merged

func _get_family_id_from_weapon_id(weapon_id: String) -> String:
	var weapon_data := _load_weapon_data(weapon_id)
	if weapon_data != null:
		if weapon_data.has_method("get_family_value"):
			return weapon_data.get_family_value()
			
	# Fallback parsing
	if "/" in weapon_id:
		return weapon_id.split("/", false, 1)[0]
	if "_" in weapon_id:
		return weapon_id.split("_", false, 1)[0]
	return weapon_id

func _load_weapon_data(weapon_id: String) -> WeaponData:
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, weapon_id)
