class_name ItemData
extends Resource

@export var id: String = ""
@export var name: String = ""
@export_multiline var description: String = ""
@export var stat_modifiers: Dictionary = {}

func _init(
	new_id: String = "",
	new_name: String = "",
	new_description: String = "",
	new_stat_modifiers: Dictionary = {}
) -> void:
	id = new_id
	name = new_name
	description = new_description
	stat_modifiers = new_stat_modifiers.duplicate(true)
