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
	var entry_index := _find_weapon_entry_index(weapon_id)
	if entry_index == -1:
		var equipped := equip_weapon(weapon_id)
		if not equipped:
			return {"success": false, "combined": false, "rarity": ""}
		return {"success": true, "combined": false, "rarity": "common"}

	var current_entry: Dictionary = equipped_weapons[entry_index]
	var current_rarity := str(current_entry.get("rarity", "common"))
	var next_rarity := _next_rarity(current_rarity)
	if next_rarity == current_rarity:
		if not has_space():
			return {"success": false, "combined": true, "rarity": current_rarity}
		equipped_weapons.append({"id": weapon_id, "rarity": "common"})
		_sync_legacy_ids()
		loadout_changed.emit()
		return {"success": true, "combined": false, "rarity": "common"}
	current_entry["rarity"] = next_rarity
	equipped_weapons[entry_index] = current_entry
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
