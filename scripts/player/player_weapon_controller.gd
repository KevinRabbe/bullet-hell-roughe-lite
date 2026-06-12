extends Node

var player_facade: Node
var _logged_resource_warnings: Dictionary = {}
var _weapon_resource_cache: Dictionary = {}

func configure(next_player_facade: Node) -> void:
	player_facade = next_player_facade

func get_preferred_weapon_family_id() -> String:
	if player_facade == null:
		return ""
	return str(player_facade.get("active_character_data").get("preferred_weapon_family", ""))

func get_shop_weapon_family_bias() -> float:
	if player_facade == null:
		return 0.0
	return maxf(float(player_facade.get("active_character_data").get("shop_weapon_family_bias", 0.0)), 0.0)

func resolve_weapon_family_id(weapon_resource: WeaponData) -> String:
	if weapon_resource == null:
		return ""
	if weapon_resource.has_method("get_family_value"):
		return weapon_resource.get_family_value()
	return ""

func weapon_slot_index_from_key(keycode: int) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		_: return -1

func equip_family_weapon(index: int) -> void:
	var family_weapon_ids: Array[String] = get_family_weapon_ids()
	if index < 0 or index >= family_weapon_ids.size():
		return
	var weapon_id: String = family_weapon_ids[index]
	grant_weapon(weapon_id)

func grant_weapon(weapon_id: String, incoming_rarity: String = "common") -> bool:
	if weapon_id == "" or player_facade == null:
		return false
	var weapon_loadout: Node = player_facade.get("weapon_loadout")
	if weapon_loadout == null or not weapon_loadout.has_method("equip_weapon"):
		push_error("WeaponLoadout not found on Player.")
		return false

	var grant_result_variant: Variant
	if weapon_loadout.has_method("grant_or_combine_weapon"):
		grant_result_variant = weapon_loadout.call("grant_or_combine_weapon", weapon_id, incoming_rarity)
	else:
		var equipped: bool = weapon_loadout.call("equip_weapon", weapon_id) == true
		grant_result_variant = {"success": equipped, "combined": false, "rarity": incoming_rarity}

	if not (grant_result_variant is Dictionary):
		push_warning("Weapon grant failed: invalid loadout result for %s" % weapon_id)
		return false
	var grant_result: Dictionary = grant_result_variant
	var success: bool = grant_result.get("success", false) == true
	if not success:
		push_warning("Weapon loadout full or weapon rejected: %s" % weapon_id)
		return false
	var combined: bool = grant_result.get("combined", false) == true
	var granted_rarity: String = str(grant_result.get("rarity", "common"))

	var weapon_resource: WeaponData = load_weapon_resource(weapon_id)
	var auto_weapon: Node = player_facade.get("auto_weapon")
	if weapon_resource != null and auto_weapon != null and auto_weapon.has_method("set_weapon_data"):
		auto_weapon.call("set_weapon_data", weapon_resource)

	if combined:
		print("Weapon combined: %s -> %s" % [weapon_id, granted_rarity])
	else:
		print("Weapon granted: %s (%s)" % [weapon_id, granted_rarity])
	return true

func grant_starting_weapon_by_id(weapon_id: String) -> void:
	grant_weapon(weapon_id)

func resolve_starting_weapon_id(character_data: Dictionary) -> String:
	var starting_weapon_ids_variant: Variant = character_data.get("starting_weapon_ids", [])
	if starting_weapon_ids_variant is Array:
		var starting_weapon_ids: Array = starting_weapon_ids_variant
		for starting_weapon_variant in starting_weapon_ids:
			var starting_weapon_id: String = str(starting_weapon_variant)
			if starting_weapon_id == "":
				continue
			if weapon_resource_exists(starting_weapon_id):
				return starting_weapon_id
			log_resource_warning_once(
				"missing_starting_weapon:%s" % starting_weapon_id,
				"Missing starting weapon resource: %s" % starting_weapon_id
			)
	return "heavy_pistol"

func get_family_weapon_ids() -> Array[String]:
	if player_facade == null:
		return ["heavy_pistol"]
	var active_character_data: Dictionary = player_facade.get("active_character_data")
	var family_weapon_ids_variant: Variant = active_character_data.get("family_weapon_ids", [])
	if family_weapon_ids_variant is Array:
		var configured_ids: Array[String] = []
		for weapon_id_variant in family_weapon_ids_variant:
			var weapon_id: String = str(weapon_id_variant)
			if weapon_id == "":
				continue
			if weapon_resource_exists(weapon_id):
				configured_ids.append(weapon_id)
			else:
				log_resource_warning_once(
					"missing_family_weapon:%s" % weapon_id,
					"Missing family weapon resource: %s" % weapon_id
				)
		if not configured_ids.is_empty():
			return configured_ids
	var weapon_loadout: Node = player_facade.get("weapon_loadout")
	if weapon_loadout != null and weapon_loadout.has_method("get_equipped_weapon_ids"):
		var equipped_ids_variant: Variant = weapon_loadout.call("get_equipped_weapon_ids")
		if equipped_ids_variant is Array:
			var equipped_ids: Array[String] = []
			for weapon_id_variant in equipped_ids_variant:
				var weapon_id: String = str(weapon_id_variant)
				if weapon_id != "":
					equipped_ids.append(weapon_id)
			if not equipped_ids.is_empty():
				return equipped_ids
	return ["heavy_pistol"]

func weapon_resource_exists(weapon_id: String) -> bool:
	return ResourceLoader.exists("res://data/weapons/%s.tres" % weapon_id)

func load_weapon_resource(weapon_id: String) -> WeaponData:
	var resource_path: String = "res://data/weapons/%s.tres" % weapon_id
	if _weapon_resource_cache.has(resource_path):
		var cached: Variant = _weapon_resource_cache[resource_path]
		if cached is WeaponData:
			return cached
	if not ResourceLoader.exists(resource_path):
		log_resource_warning_once("missing_weapon:%s" % weapon_id, "Missing weapon resource: %s" % resource_path)
		return null
	var resource: Variant = load(resource_path)
	if resource is WeaponData:
		var weapon_resource: WeaponData = resource as WeaponData
		_weapon_resource_cache[resource_path] = weapon_resource
		return weapon_resource
	log_resource_warning_once("invalid_weapon:%s" % weapon_id, "Invalid weapon resource type: %s" % resource_path)
	return null

func log_resource_warning_once(warning_key: String, message: String) -> void:
	if _logged_resource_warnings.has(warning_key):
		return
	_logged_resource_warnings[warning_key] = true
	push_warning(message)

func get_weapon_ui_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if player_facade == null:
		return entries
	var weapon_loadout: Node = player_facade.get("weapon_loadout")
	if weapon_loadout == null or not weapon_loadout.has_method("get_weapon_entries"):
		return entries
	var raw_entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
	if not (raw_entries_variant is Array):
		return entries
	var raw_entries: Array = raw_entries_variant
	for entry_variant in raw_entries:
		if not (entry_variant is Dictionary):
			continue
		var entry: Dictionary = (entry_variant as Dictionary).duplicate(true)
		var weapon_id: String = str(entry.get("id", ""))
		var weapon_resource: WeaponData = load_weapon_resource(weapon_id)
		if weapon_resource == null:
			entries.append(entry)
			continue
		var family_id: String = resolve_weapon_family_id(weapon_resource)
		var required_kills: int = _get_effective_kill_requirement(weapon_resource, family_id)
		var kill_count: int = int(entry.get("kill_count", 0))
		var milestones_earned: int = int(entry.get("milestones_earned", 0))
		var progress_in_stage: int = kill_count - (required_kills * milestones_earned)
		if required_kills > 0:
			progress_in_stage = maxi(progress_in_stage, 0)
		entry["display_name"] = weapon_resource.display_name
		entry["kill_requirement"] = required_kills
		entry["kill_progress"] = progress_in_stage
		entry["milestone_stat_id"] = weapon_resource.kill_milestone_stat_id
		entry["milestone_amount"] = weapon_resource.kill_milestone_amount
		entries.append(entry)
	return entries

func _get_effective_kill_requirement(weapon_resource: WeaponData, family_id: String) -> int:
	if weapon_resource == null or weapon_resource.kill_milestone_base_kills <= 0:
		return 0
	var multiplier: float = 1.0
	if player_facade != null and player_facade.has_method("get_family_kill_requirement_multiplier"):
		multiplier = float(player_facade.call("get_family_kill_requirement_multiplier", family_id))
	return maxi(int(round(float(weapon_resource.kill_milestone_base_kills) * multiplier)), 1)
