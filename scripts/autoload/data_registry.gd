extends Node

const ItemDatabase = preload("res://scripts/items/item_database.gd")
const ENEMY_RESOURCE_PATHS: Array[String] = [
	"res://data/enemies/imp_runner.tres",
	"res://data/enemies/husk_brute.tres",
	"res://data/enemies/spit_fiend.tres",
]

var characters: Dictionary = {}
var weapons: Dictionary = {}
var items: Dictionary = {}
var enemies: Dictionary = {}
var portal_events: Dictionary = {}
var set_bonuses: Dictionary = {}

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
	_register_by_id(items, ItemDatabase.get_prototype_items())
	_register_by_id(enemies, _load_enemy_resources())

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
