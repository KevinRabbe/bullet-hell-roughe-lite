extends CharacterBody2D

const StatBlock = preload("res://scripts/core/stat_block.gd")
const ItemData = preload("res://scripts/items/item_data.gd")

@export var debug_starting_hp: float = 100.0
@export var debug_move_speed: float = 300.0

var stats: StatBlock = StatBlock.new()
var current_hp: float
var owned_items: Array[ItemData] = []

func _ready() -> void:
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * stats.movement_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		die()

func die() -> void:
	print("Player died - placeholder")

func grant_item(item: ItemData) -> void:
	if item == null:
		return
	owned_items.append(item)
	_apply_item_effects(item)
	print("Gained item: %s" % item.name)

func _apply_item_effects(item: ItemData) -> void:
	for stat_name in item.stat_modifiers.keys():
		if not _has_stat_property(stat_name):
			continue
		var current_value: Variant = stats.get(stat_name)
		var modifier: Variant = item.stat_modifiers[stat_name]
		if current_value is float and modifier is float:
			stats.set(stat_name, current_value + modifier)
		elif current_value is int and modifier is int:
			stats.set(stat_name, current_value + modifier)

	if item.stat_modifiers.has("max_hp"):
		current_hp += float(item.stat_modifiers["max_hp"])
		current_hp = minf(current_hp, stats.max_hp)

func _has_stat_property(stat_name: String) -> bool:
	for property_info in stats.get_property_list():
		if str(property_info.get("name", "")) == stat_name:
			return true
	return false
