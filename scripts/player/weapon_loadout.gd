extends Node

signal loadout_changed

const MAX_WEAPON_SLOTS: int = 6

@export var equipped_weapon_ids: Array[String] = []

func has_space() -> bool:
	return equipped_weapon_ids.size() < MAX_WEAPON_SLOTS

# Fallback alias for existing player code that might call can_equip_more
func can_equip_more() -> bool:
	return has_space()

func get_weapon_count() -> int:
	return equipped_weapon_ids.size()

func get_equipped_weapon_ids() -> Array[String]:
	return equipped_weapon_ids.duplicate()

func equip_weapon(weapon_id: String) -> bool:
	if weapon_id == "":
		return false
	if not has_space():
		return false
	equipped_weapon_ids.append(weapon_id)
	loadout_changed.emit()
	return true

func clear_loadout() -> void:
	equipped_weapon_ids.clear()
	loadout_changed.emit()

func get_family_counts() -> Dictionary:
	var family_counts: Dictionary = {}
	for weapon_id in equipped_weapon_ids:
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
