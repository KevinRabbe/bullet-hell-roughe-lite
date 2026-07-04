extends RefCounted

const ITEM_RESOURCE_DIR: String = "res://data/items"

static func get_prototype_items() -> Array[ItemData]:
	var items: Array[ItemData] = []
	for resource_path in _list_item_resource_paths():
		if not ResourceLoader.exists(resource_path):
			continue
		var item_resource := load(resource_path)
		if item_resource is ItemData:
			items.append(item_resource as ItemData)
	return items

static func get_random_item(rng: RandomNumberGenerator) -> ItemData:
	var items := get_prototype_items()
	if items.is_empty():
		return ItemData.new()
	return items[rng.randi_range(0, items.size() - 1)]

static func get_random_item_for_tier(tier: int, rng: RandomNumberGenerator) -> ItemData:
	var tier_ids: Array[String]
	match tier:
		3:
			tier_ids = ["steel_heart", "trigger_core"]
		2:
			tier_ids = ["glass_scope", "lucky_charm"]
		_:
			tier_ids = ["swift_boots", "lucky_charm"]

	var pool: Array[ItemData] = []
	for item in get_prototype_items():
		if tier_ids.has(item.id):
			pool.append(item)
	if pool.is_empty():
		return get_random_item(rng)
	return pool[rng.randi_range(0, pool.size() - 1)]

static func get_item_by_id(item_id: String) -> ItemData:
	if item_id == "":
		return null
	for item in get_prototype_items():
		if item != null and item.id == item_id:
			return item
	return null

static func _list_item_resource_paths() -> Array[String]:
	var paths: Array[String] = []
	var directory := DirAccess.open(ITEM_RESOURCE_DIR)
	if directory == null:
		return paths
	var file_names: Array[String] = []
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			file_names.append(file_name)
		file_name = directory.get_next()
	directory.list_dir_end()
	file_names.sort()
	for sorted_file_name in file_names:
		paths.append("%s/%s" % [ITEM_RESOURCE_DIR, sorted_file_name])
	return paths
