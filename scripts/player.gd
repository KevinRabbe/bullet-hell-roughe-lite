extends CharacterBody2D

@export var debug_starting_hp: float = 100.0
@export var debug_move_speed: float = 300.0

signal player_died

var stats: StatBlock = StatBlock.new()
var current_hp: float
var owned_items: Array[ItemData] = []
var is_dead: bool = false
@onready var hp_label: Label = get_node_or_null("DebugHpLabel")

func _ready() -> void:
	add_to_group("players")
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp
	_update_hp_label()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * stats.movement_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_update_hp_label()
	print("PLAYER TOOK %.1f DAMAGE | HP: %.1f / %.1f" % [amount, current_hp, stats.max_hp])
	if current_hp <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	print("PLAYER DIED. Press R to restart.")
	player_died.emit()

func grant_item(item: ItemData) -> void:
	if item == null:
		return
	owned_items.append(item)
	_apply_item_effects(item)
	print("Gained item: %s" % item.name)
	_print_debug_stats()

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
	_update_hp_label()

func _has_stat_property(stat_name: String) -> bool:
	for property_info in stats.get_property_list():
		if str(property_info.get("name", "")) == stat_name:
			return true
	return false

func _print_debug_stats() -> void:
	var attack_range_value: float = _get_stat_value("attack_range", _get_stat_value("range", 1.0))
	print(
		"Stats | HP %.1f/%.1f | DMG %.2f | AS %.2f | MS %.1f | AR %.2f | Portal(Luck %.2f, Freq %.2f, Instability %.2f, Reward %.2f)"
		% [
			current_hp,
			stats.max_hp,
			stats.damage,
			stats.attack_speed,
			stats.movement_speed,
			attack_range_value,
			stats.portal_luck,
			stats.portal_frequency,
			stats.portal_instability,
			stats.portal_reward_multiplier
		]
	)

func _get_stat_value(stat_name: String, fallback: float) -> float:
	if _has_stat_property(stat_name):
		return float(stats.get(stat_name))
	return fallback

func _update_hp_label() -> void:
	if hp_label == null:
		return
	hp_label.text = "HP: %.1f / %.1f" % [current_hp, stats.max_hp]

func _debug_add_gunslinger_weapon_by_id(weapon_id: String) -> void:
	if weapon_id == "":
		return
	if not has_node("WeaponLoadout"):
		return
	var loadout := get_node("WeaponLoadout")
	if loadout.has_method("equip_weapon"):
		var equipped := bool(loadout.call("equip_weapon", weapon_id))
		print("Debug equip from shop: %s (%s)" % [weapon_id, equipped])

func _debug_add_stat_bonus(stat_name: String, value: float) -> void:
	if stat_name == "":
		return
	if _has_stat_property(stat_name):
		stats.set(stat_name, float(stats.get(stat_name)) + value)
		if stat_name == "max_hp":
			current_hp = minf(current_hp + value, stats.max_hp)
		_update_hp_label()
		print("Debug stat bonus from shop: %s %+0.2f" % [stat_name, value])
