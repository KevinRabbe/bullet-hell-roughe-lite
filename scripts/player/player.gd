extends CharacterBody2D

@export var debug_starting_hp: float = 100.0
@export var debug_move_speed: float = 300.0

signal player_died
signal level_up_pending_changed

var stats: StatBlock = StatBlock.new()
var current_hp: float
var current_gold: int = 0
var current_xp: int = 0
var current_level: int = 1
var xp_to_next_level: int = 10
var pending_level_ups: int = 0
var owned_items: Array[ItemData] = []
var is_dead: bool = false
var active_character_id: String = "gunslinger"
@onready var auto_weapon: Node = get_node_or_null("AutoWeapon")
@onready var weapon_loadout: Node = get_node_or_null("WeaponLoadout")
@onready var hp_label: Label = get_node_or_null("DebugHpLabel")
@onready var player_build: Node = get_node_or_null("PlayerBuild")

const GUNSLINGER_WEAPON_IDS: Array[String] = [
	"heavy_pistol",
	"gunslinger_smg",
	"gunslinger_shotgun",
	"gunslinger_revolver",
	"gunslinger_assault_rifle",
	"gunslinger_sniper_rifle"
]

const GUNSLINGER_WEAPON_RESOURCES: Dictionary = {
	"heavy_pistol": "res://data/weapons/heavy_pistol.tres",
	"gunslinger_smg": "res://data/weapons/gunslinger_smg.tres",
	"gunslinger_shotgun": "res://data/weapons/gunslinger_shotgun.tres",
	"gunslinger_revolver": "res://data/weapons/gunslinger_revolver.tres",
	"gunslinger_assault_rifle": "res://data/weapons/gunslinger_assault_rifle.tres",
	"gunslinger_sniper_rifle": "res://data/weapons/gunslinger_sniper_rifle.tres"
}

func _ready() -> void:
	add_to_group("players")
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp
	_apply_character_rules()
	_update_hp_label()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * stats.movement_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var index := _weapon_slot_index_from_key(key_event.keycode)
	if index == -1:
		return
	_equip_gunslinger_weapon(index)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_hp = maxf(current_hp - amount, 0.0)
	_update_hp_label()
	print("PLAYER TOOK %.1f DAMAGE | HP: %.1f / %.1f" % [amount, current_hp, stats.max_hp])
	if current_hp <= 0.0:
		die()

func heal_to_full() -> void:
	if is_dead:
		return
	current_hp = stats.max_hp
	_update_hp_label()
	print("PLAYER HEALED TO FULL | HP: %.1f / %.1f" % [current_hp, stats.max_hp])

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
	hp_label.text = "HP: %.1f / %.1f | Gold: %d | Lv %d XP %d/%d" % [current_hp, stats.max_hp, current_gold, current_level, current_xp, xp_to_next_level]

func add_gold(amount: int) -> void:
	if amount <= 0:
		return
	current_gold += amount
	_update_hp_label()
	print("GOLD +%d | Total: %d" % [amount, current_gold])

func spend_gold(amount: int) -> bool:
	if amount <= 0:
		return true
	if current_gold < amount:
		print("Not enough gold. Need %d, have %d." % [amount, current_gold])
		return false
	current_gold -= amount
	_update_hp_label()
	print("GOLD -%d | Total: %d" % [amount, current_gold])
	return true

func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	current_xp += amount
	print("XP +%d | Progress: %d/%d" % [amount, current_xp, xp_to_next_level])
	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		pending_level_ups += 1
		xp_to_next_level += 5
		print("LEVEL UP! Reached level %d. Pending choices: %d" % [current_level, pending_level_ups])
		level_up_pending_changed.emit()
	_update_hp_label()

func has_pending_level_up() -> bool:
	return pending_level_ups > 0

func consume_pending_level_up() -> bool:
	if pending_level_ups <= 0:
		return false
	pending_level_ups -= 1
	level_up_pending_changed.emit()
	return true

func apply_level_up_bonus(stat_id: String, value: float) -> void:
	if stat_id == "max_hp":
		stats.max_hp += value
		current_hp += value
		current_hp = minf(current_hp, stats.max_hp)
	elif _has_stat_property(stat_id):
		var current_value: Variant = stats.get(stat_id)
		if current_value is float:
			stats.set(stat_id, float(current_value) + value)
		elif current_value is int:
			stats.set(stat_id, int(current_value) + int(value))
	_update_hp_label()
	print("LEVEL-UP BONUS: %s %+0.2f" % [stat_id, value])

func apply_character_by_id(character_id: String) -> void:
	if character_id == "":
		return
	active_character_id = character_id
	_reset_character_stats()
	_apply_character_rules()
	_apply_character_starting_weapon()
	if player_build != null and player_build.has_method("set_active_character"):
		player_build.call("set_active_character", active_character_id)
	print("Selected character: %s" % active_character_id)

func _reset_character_stats() -> void:
	stats.burn_damage = 1.0
	stats.poison_damage = 1.0
	stats.bleed_damage = 1.0
	stats.frost_power = 1.0
	stats.portal_frequency = 1.0
	stats.portal_luck = 0.0
	stats.portal_instability = 0.0

func _apply_character_starting_weapon() -> void:
	_debug_add_gunslinger_weapon_by_id("heavy_pistol")

func _apply_character_rules() -> void:
	if active_character_id == "gunslinger":
		stats.burn_damage = 0.8
		stats.poison_damage = 0.8
		stats.bleed_damage = 0.8
		stats.frost_power = 0.8
	if player_build != null:
		var weapons_variant: Variant = player_build.get("equipped_weapon_ids")
		if weapons_variant is Array:
			var weapons: Array = weapons_variant
			if weapons.is_empty():
				weapons.append("heavy_pistol")
				player_build.set("equipped_weapon_ids", weapons)

func get_damage_multiplier_for_target(target: Node) -> float:
	if active_character_id != "gunslinger":
		return 1.0
	if target == null:
		return 1.0
	var is_elite: bool = bool(target.get("is_elite"))
	var is_boss: bool = bool(target.get("is_boss"))
	if is_elite or is_boss:
		print("GUNSLINGER PASSIVE: +35% damage vs elite/boss")
		return 1.35
	return 1.0

func _weapon_slot_index_from_key(keycode: int) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		_: return -1

func _equip_gunslinger_weapon(index: int) -> void:
	if index < 0 or index >= GUNSLINGER_WEAPON_IDS.size():
		return
	var weapon_id := GUNSLINGER_WEAPON_IDS[index]
	grant_weapon(weapon_id)

func grant_weapon(weapon_id: String) -> bool:
	if weapon_id == "":
		return false
	if weapon_loadout == null or not weapon_loadout.has_method("equip_weapon"):
		push_error("WeaponLoadout not found on Player.")
		return false

	var equipped: bool = bool(weapon_loadout.call("equip_weapon", weapon_id))
	if not equipped:
		print("Weapon loadout full or weapon rejected: %s" % weapon_id)
		return false

	var weapon_path := str(GUNSLINGER_WEAPON_RESOURCES.get(weapon_id, ""))
	if weapon_path != "":
		var weapon_resource := load(weapon_path)
		if auto_weapon != null and auto_weapon.has_method("set_weapon_data"):
			auto_weapon.call("set_weapon_data", weapon_resource)

	print("Weapon granted: %s" % weapon_id)
	return true

# TODO: remove after all callers use grant_weapon directly.
func _debug_add_gunslinger_weapon_by_id(weapon_id: String) -> void:
	grant_weapon(weapon_id)

func _debug_add_stat_bonus(stat_id: String, value: float) -> void:
	if not _has_stat_property(stat_id):
		print("Unknown stat bonus: %s" % stat_id)
		return
	var current_value: Variant = stats.get(stat_id)
	if current_value is float:
		stats.set(stat_id, float(current_value) + value)
	elif current_value is int:
		stats.set(stat_id, int(current_value) + int(value))
	_update_hp_label()
	print("DEBUG stat bonus: %s %+0.2f" % [stat_id, value])
