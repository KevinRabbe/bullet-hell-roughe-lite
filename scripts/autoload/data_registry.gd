extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const ENEMY_RESOURCE_PATHS: Array[String] = [
	"res://data/enemies/imp_runner.tres",
	"res://data/enemies/husk_brute.tres",
	"res://data/enemies/spit_fiend.tres",
	"res://data/enemies/skeleton_rifleman.tres",
]
const WEAPON_RESOURCE_DIR: String = "res://data/weapons"
const ITEM_RESOURCE_DIR: String = "res://data/items"
const WAVE_COMPOSITION_PATH: String = "res://data/waves/wave_composition.json"

var characters: Dictionary = {}
var weapons: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var portal_events: Dictionary = {}
var set_bonuses: Dictionary = {}
var wave_composition: Dictionary = {}

func _ready() -> void:
	_register_defaults()
	print("DataRegistry ready: %d characters, %d weapons, %d items, %d enemies, %d portal events, %d set bonuses" % [
		characters.size(),
		weapons.size(),
		items.size(),
		enemies.size(),
		portal_events.size(),
		set_bonuses.size()
	])

func _register_defaults() -> void:
	_load_character_json_data("res://data/characters")
	_register_by_id(weapons, _load_resource_directory(WEAPON_RESOURCE_DIR))
	_register_by_id(items, _load_resource_directory(ITEM_RESOURCE_DIR))
	if items.is_empty():
		_register_by_id(items, ItemDatabase.get_prototype_items())
	_register_by_id(enemies, _load_enemy_resources())
	wave_composition = _load_json_dictionary(WAVE_COMPOSITION_PATH)
	_validate_registry_entries()

func _load_enemy_resources() -> Array:
	var loaded: Array = []
	for resource_path in ENEMY_RESOURCE_PATHS:
		if not ResourceLoader.exists(resource_path):
			continue
		var enemy_resource := load(resource_path)
		if enemy_resource != null:
			loaded.append(enemy_resource)
	return loaded

func _load_character_json_data(directory_path: String) -> void:
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".json"):
			var full_path := "%s/%s" % [directory_path, file_name]
			var data := _load_json_dictionary(full_path)
			var character_id := str(data.get("id", ""))
			if character_id != "":
				characters[character_id] = data
		file_name = directory.get_next()
	directory.list_dir_end()

func _load_json_dictionary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var json_text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(json_text)
	if parsed is Dictionary:
		return parsed
	return {}

func _register_by_id(target: Dictionary, entries: Array) -> void:
	for entry in entries:
		if entry == null:
			continue
		if not entry.has_method("get"):
			continue
		var entry_id := str(entry.get("id"))
		if entry_id == "":
			continue
		target[entry_id] = entry

func _load_resource_directory(directory_path: String) -> Array:
	var loaded: Array = []
	var directory := DirAccess.open(directory_path)
	if directory == null:
		return loaded
	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".tres"):
			var full_path := "%s/%s" % [directory_path, file_name]
			if ResourceLoader.exists(full_path):
				var resource := load(full_path)
				if resource != null:
					loaded.append(resource)
		file_name = directory.get_next()
	directory.list_dir_end()
	return loaded

func _validate_registry_entries() -> void:
	for weapon_id in weapons.keys():
		var weapon: Variant = weapons[weapon_id]
		if weapon == null:
			push_warning("Weapon entry '%s' is null." % str(weapon_id))
			continue
		if str(weapon.get("display_name")) == "":
			push_warning("Weapon '%s' is missing display_name." % str(weapon_id))
		if int(weapon.get("price")) <= 0:
			push_warning("Weapon '%s' has non-positive price; shop fallback may be used." % str(weapon_id))
	for item_id in items.keys():
		var item: Variant = items[item_id]
		if item == null:
			push_warning("Item entry '%s' is null." % str(item_id))
			continue
		if str(item.get("name")) == "":
			push_warning("Item '%s' is missing name." % str(item_id))
	for enemy_id in enemies.keys():
		var enemy: Variant = enemies[enemy_id]
		if enemy == null:
			push_warning("Enemy entry '%s' is null." % str(enemy_id))
			continue
		if float(enemy.get("max_hp")) <= 0.0:
			push_warning("Enemy '%s' has invalid max_hp." % str(enemy_id))

func get_character(id: String):
	return characters.get(id)

func get_character_ids() -> Array[String]:
	var ids: Array[String] = []
	for character_id in characters.keys():
		ids.append(str(character_id))
	ids.sort()
	return ids

func get_weapon(id: String):
	return weapons.get(id)

func get_item(id: String):
	return items.get(id)

func get_enemy(id: String):
	return enemies.get(id)

func get_portal_event(id: String):
	return portal_events.get(id)

func get_set_bonus(id: String):
	return set_bonuses.get(id)

func get_wave_composition() -> Dictionary:
	return wave_composition.duplicate(true)
