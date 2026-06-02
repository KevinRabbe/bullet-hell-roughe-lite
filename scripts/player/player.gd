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
var active_character_data: Dictionary = {}
var _logged_character_warnings: Dictionary = {}
@onready var auto_weapon: Node = get_node_or_null("AutoWeapon")
@onready var weapon_loadout: Node = get_node_or_null("WeaponLoadout")
@onready var player_build: Node = get_node_or_null("PlayerBuild")

func _ready() -> void:
	add_to_group("players")
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp
	active_character_data = _load_character_data(active_character_id)
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
	_equip_weapon_slot(index)

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
	pass

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
	active_character_data = _load_character_data(character_id)
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
	if weapon_loadout != null and weapon_loadout.has_method("clear_loadout"):
		weapon_loadout.call("clear_loadout")
	if player_build != null:
		player_build.set("equipped_weapon_ids", [])
	var starting_weapon_ids := _get_character_starting_weapon_ids()
	for weapon_id in starting_weapon_ids:
		grant_weapon(weapon_id)

func _apply_character_rules() -> void:
	for downside_rule_variant in _get_character_rule_array("downside_rules"):
		if downside_rule_variant is Dictionary:
			_apply_character_rule(downside_rule_variant)
	if player_build != null:
		var weapons_variant: Variant = player_build.get("equipped_weapon_ids")
		if weapons_variant is Array:
			var weapons: Array = weapons_variant
			if weapons.is_empty():
				for weapon_id in _get_character_starting_weapon_ids():
					weapons.append(weapon_id)
				player_build.set("equipped_weapon_ids", weapons)

func get_damage_multiplier_for_target(target: Node) -> float:
	if target == null:
		return 1.0
	for passive_rule_variant in _get_character_rule_array("passive_rules"):
		if not (passive_rule_variant is Dictionary):
			continue
		var passive_rule: Dictionary = passive_rule_variant
		if str(passive_rule.get("type", "")) != "damage_multiplier_vs_tags":
			continue
		if not _target_matches_rule_tags(target, passive_rule):
			continue
		var debug_label := str(passive_rule.get("debug_label", ""))
		if debug_label != "":
			print(debug_label)
		return float(passive_rule.get("multiplier", 1.0))
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

func _equip_weapon_slot(index: int) -> void:
	var weapon_ids := _get_available_weapon_ids_for_hotkeys()
	if index < 0 or index >= weapon_ids.size():
		return
	var weapon_id := weapon_ids[index]
	grant_weapon(weapon_id)

func grant_weapon(weapon_id: String, incoming_rarity: String = "common") -> bool:
	if weapon_id == "":
		return false
	if weapon_loadout == null or not weapon_loadout.has_method("equip_weapon"):
		push_error("WeaponLoadout not found on Player.")
		return false

	var grant_result_variant: Variant
	if weapon_loadout.has_method("grant_or_combine_weapon"):
		grant_result_variant = weapon_loadout.call("grant_or_combine_weapon", weapon_id, incoming_rarity)
	else:
		var equipped: bool = bool(weapon_loadout.call("equip_weapon", weapon_id))
		grant_result_variant = {"success": equipped, "combined": false, "rarity": incoming_rarity}

	if not (grant_result_variant is Dictionary):
		print("Weapon grant failed: invalid loadout result for %s" % weapon_id)
		return false
	var grant_result: Dictionary = grant_result_variant
	var success := bool(grant_result.get("success", false))
	if not success:
		print("Weapon loadout full or weapon rejected: %s" % weapon_id)
		return false
	var combined := bool(grant_result.get("combined", false))
	var granted_rarity := str(grant_result.get("rarity", "common"))

	var weapon_path := "res://data/weapons/%s.tres" % weapon_id
	if ResourceLoader.exists(weapon_path):
		var weapon_resource := load(weapon_path)
		if auto_weapon != null and auto_weapon.has_method("set_weapon_data"):
			auto_weapon.call("set_weapon_data", weapon_resource)
	else:
		_log_character_warning_once("missing_weapon_resource:%s" % weapon_id, "Missing weapon resource for '%s'." % weapon_id)

	if combined:
		print("Weapon combined: %s -> %s" % [weapon_id, granted_rarity])
	else:
		print("Weapon granted: %s (%s)" % [weapon_id, granted_rarity])
	return true

# TODO: remove after all callers use grant_weapon directly.
func _debug_add_gunslinger_weapon_by_id(weapon_id: String) -> void:
	grant_weapon(weapon_id)

func _load_character_data(character_id: String) -> Dictionary:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry != null and data_registry.has_method("get_character"):
		var character_variant: Variant = data_registry.call("get_character", character_id)
		if character_variant is Dictionary:
			return character_variant
	_log_character_warning_once("missing_character_data:%s" % character_id, "Missing character data for '%s'; using deterministic fallback." % character_id)
	return {
		"id": character_id,
		"starting_weapon_ids": ["heavy_pistol"],
		"passive_rules": [],
		"downside_rules": []
	}

func _get_character_rule_array(key: String) -> Array:
	var rule_variant: Variant = active_character_data.get(key, [])
	if rule_variant is Array:
		return rule_variant
	return []

func _get_character_starting_weapon_ids() -> Array[String]:
	var starting_variant: Variant = active_character_data.get("starting_weapon_ids", ["heavy_pistol"])
	var weapon_ids: Array[String] = []
	if starting_variant is Array:
		for weapon_id_variant in starting_variant:
			var weapon_id := str(weapon_id_variant)
			if weapon_id != "":
				weapon_ids.append(weapon_id)
	if weapon_ids.is_empty():
		weapon_ids.append("heavy_pistol")
	return weapon_ids

func _apply_character_rule(rule: Dictionary) -> void:
	var rule_type := str(rule.get("type", ""))
	if rule_type != "stat_multiplier":
		return
	var multiplier := float(rule.get("multiplier", 1.0))
	var stats_variant: Variant = rule.get("stats", [])
	if not (stats_variant is Array):
		return
	for stat_id_variant in stats_variant:
		var stat_id := str(stat_id_variant)
		if not _has_stat_property(stat_id):
			continue
		var current_value: Variant = stats.get(stat_id)
		if current_value is float:
			stats.set(stat_id, float(current_value) * multiplier)
		elif current_value is int:
			stats.set(stat_id, int(round(float(current_value) * multiplier)))

func _target_matches_rule_tags(target: Node, rule: Dictionary) -> bool:
	var tags_variant: Variant = rule.get("target_tags", [])
	if not (tags_variant is Array):
		return false
	for tag_variant in tags_variant:
		var tag := str(tag_variant)
		match tag:
			"elite":
				if bool(target.get("is_elite")):
					return true
			"boss":
				if bool(target.get("is_boss")):
					return true
	return false

func _get_available_weapon_ids_for_hotkeys() -> Array[String]:
	var weapon_ids: Array[String] = []
	if weapon_loadout != null and weapon_loadout.has_method("get_weapon_entries"):
		var entries_variant: Variant = weapon_loadout.call("get_weapon_entries")
		if entries_variant is Array:
			for entry_variant in entries_variant:
				if entry_variant is Dictionary:
					var weapon_id := str(entry_variant.get("id", ""))
					if weapon_id != "":
						weapon_ids.append(weapon_id)
	if weapon_ids.is_empty():
		return _get_character_starting_weapon_ids()
	return weapon_ids

func _log_character_warning_once(key: String, message: String) -> void:
	if _logged_character_warnings.has(key):
		return
	_logged_character_warnings[key] = true
	push_warning(message)

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

func get_ui_snapshot() -> Dictionary:
	return {
		"hp": float(current_hp),
		"max_hp": float(stats.max_hp),
		"gold": int(current_gold),
		"level": int(current_level),
		"xp": int(current_xp),
		"xp_to_next": int(xp_to_next_level),
		"damage": float(stats.damage),
		"attack_speed": float(stats.attack_speed),
		"move_speed": float(stats.movement_speed),
		"attack_range": float(stats.attack_range),
		"armor": float(stats.armor),
		"crit": float(stats.crit_chance),
		"portal_luck": float(stats.portal_luck),
		"portal_frequency": float(stats.portal_frequency),
		"portal_instability": float(stats.portal_instability),
		"items": owned_items.duplicate()
	}
