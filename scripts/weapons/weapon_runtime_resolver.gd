class_name WeaponRuntimeResolver
extends RefCounted

static func resource_path_for_id(weapon_id: String) -> String:
	return "res://data/weapons/%s.tres" % weapon_id

static func has_weapon_resource(weapon_id: String) -> bool:
	if weapon_id == "":
		return false
	return ResourceLoader.exists(resource_path_for_id(weapon_id))

static func load_weapon_data(cache: Dictionary, weapon_id: String) -> WeaponData:
	if weapon_id == "":
		return null
	var resource_path := resource_path_for_id(weapon_id)
	if cache.has(resource_path):
		var cached: Variant = cache[resource_path]
		if cached is WeaponData:
			return cached
	if not ResourceLoader.exists(resource_path):
		return null
	var loaded := load(resource_path)
	if loaded is WeaponData:
		var weapon_data := loaded as WeaponData
		cache[resource_path] = weapon_data
		return weapon_data
	return null
