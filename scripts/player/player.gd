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
var active_character_id: String = ""
var active_character_data: Dictionary = {}
var _logged_resource_warnings: Dictionary = {}
var _passive_rule_timers: Dictionary = {}
var _default_visual_texture: Texture2D
var _default_visual_scale: Vector2 = Vector2.ONE
@onready var auto_weapon: Node = get_node_or_null("AutoWeapon")
@onready var weapon_loadout: Node = get_node_or_null("WeaponLoadout")
@onready var player_build: Node = get_node_or_null("PlayerBuild")
@onready var visual_sprite: Sprite2D = get_node_or_null("Visual")

func _ready() -> void:
	add_to_group("players")
	_reset_character_stats()
	_resolve_default_character_id()
	_cache_default_visual_state()
	active_character_data = _get_character_data(active_character_id)
	_apply_character_rules(active_character_data)
	_apply_character_visual(active_character_data)
	_update_hp_label()

func _physics_process(_delta: float) -> void:
	if is_dead:
		velocity = Vector2.ZERO
		move_and_slide()
		return
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * stats.movement_speed
	move_and_slide()
	_process_passive_status_rules(_delta)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	var index := _weapon_slot_index_from_key(key_event.keycode)
	if index == -1:
		return
	_equip_family_weapon(index)

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

func notify_enemy_killed(weapon_id: String, slot_index: int) -> void:
	if weapon_loadout == null or not weapon_loadout.has_method("register_weapon_kill"):
		return
	if weapon_id == "" or slot_index < 0:
		return
	var weapon_resource := _load_weapon_resource(weapon_id)
	if weapon_resource == null:
		return
	var family_id := _resolve_weapon_family_id(weapon_resource)
	var result_variant := weapon_loadout.call(
		"register_weapon_kill",
		slot_index,
		weapon_resource,
		get_family_kill_requirement_multiplier(family_id)
	)
	if not (result_variant is Dictionary):
		return
	var result: Dictionary = result_variant
	if not bool(result.get("triggered", false)):
		return
	var stat_id := str(result.get("stat_id", ""))
	var amount := float(result.get("amount", 0.0))
	var scope := str(result.get("scope", "player"))
	if stat_id == "":
		return
	var weapon_name := weapon_resource.display_name if weapon_resource.display_name != "" else weapon_id
	if scope == "player":
		_apply_runtime_stat_bonus(stat_id, amount, "%s milestone" % weapon_name)
	else:
		print("%s milestone: %s %+0.2f (weapon only)" % [weapon_name, stat_id, amount])

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

func _apply_runtime_stat_bonus(stat_id: String, value: float, label: String = "") -> void:
	if stat_id == "max_hp":
		stats.max_hp += value
		current_hp += value
		current_hp = minf(current_hp, stats.max_hp)
	elif _has_stat_property(stat_id):
		var current_value: Variant = stats.get(stat_id)
		if current_value is float:
			stats.set(stat_id, float(current_value) + value)
		elif current_value is int:
			stats.set(stat_id, int(current_value) + int(round(value)))
	_update_hp_label()
	var bonus_label := label if label != "" else stat_id
	print("%s bonus: %s %+0.2f" % [bonus_label, stat_id, value])

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
	active_character_data = _get_character_data(active_character_id)
	_reset_character_stats()
	_apply_character_rules(active_character_data)
	_apply_character_visual(active_character_data)
	_apply_character_starting_weapon(active_character_data)
	if player_build != null and player_build.has_method("set_active_character"):
		player_build.call("set_active_character", active_character_id)
	print("Selected character: %s" % active_character_id)

func _reset_character_stats() -> void:
	stats = StatBlock.new()
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp
	stats.burn_damage = 1.0
	stats.poison_damage = 1.0
	stats.bleed_damage = 1.0
	stats.frost_power = 1.0
	stats.portal_frequency = 1.0
	stats.portal_luck = 0.0
	stats.portal_instability = 0.0

func _apply_character_starting_weapon(character_data: Dictionary = {}) -> void:
	var starting_weapon_id := _resolve_starting_weapon_id(character_data)
	_grant_starting_weapon_by_id(starting_weapon_id)

func _apply_character_rules(character_data: Dictionary = {}) -> void:
	_apply_stat_multipliers(character_data.get("stat_multipliers", {}))
	_apply_stat_bonuses(character_data.get("stat_bonuses", {}))
	_reset_passive_rule_timers(character_data)
	if player_build != null:
		var weapons_variant: Variant = player_build.get("equipped_weapon_ids")
		if weapons_variant is Array:
			var weapons: Array = weapons_variant
			if weapons.is_empty():
				weapons.append(_resolve_starting_weapon_id(character_data))
				player_build.set("equipped_weapon_ids", weapons)

func get_damage_multiplier_for_target(target: Node) -> float:
	if target == null:
		return 1.0
	var damage_rules_variant: Variant = active_character_data.get("damage_rules", [])
	if damage_rules_variant is Array:
		var damage_rules: Array = damage_rules_variant
		for damage_rule_variant in damage_rules:
			if not (damage_rule_variant is Dictionary):
				continue
			var damage_rule: Dictionary = damage_rule_variant
			if _target_matches_damage_rule(target, damage_rule):
				var debug_label := str(damage_rule.get("debug_label", ""))
				if debug_label != "":
					print(debug_label)
				return float(damage_rule.get("multiplier", 1.0))
	return 1.0

func get_family_kill_requirement_multiplier(family_id: String) -> float:
	var family_multipliers_variant: Variant = active_character_data.get("family_kill_requirement_multipliers", {})
	if not (family_multipliers_variant is Dictionary):
		return 1.0
	var family_multipliers: Dictionary = family_multipliers_variant
	return float(family_multipliers.get(family_id, 1.0))

func get_status_power_multiplier(status_id: String) -> float:
	var status_multipliers_variant: Variant = active_character_data.get("status_power_multipliers", {})
	if not (status_multipliers_variant is Dictionary):
		return 1.0
	var status_multipliers: Dictionary = status_multipliers_variant
	return maxf(float(status_multipliers.get(status_id, 1.0)), 0.0)

func get_status_power_stat_multiplier(stat_name: String, fallback: float = 1.0) -> float:
	return maxf(_get_stat_value(stat_name, fallback), 0.0)

func get_status_propagation_rule(status_id: String) -> Dictionary:
	var propagation_rules_variant: Variant = active_character_data.get("status_propagation_rules", {})
	if not (propagation_rules_variant is Dictionary):
		return {}
	var propagation_rules: Dictionary = propagation_rules_variant
	var rule_variant: Variant = propagation_rules.get(status_id, {})
	if rule_variant is Dictionary:
		var resolved_rule: Dictionary = (rule_variant as Dictionary).duplicate(true)
		_apply_pressure_scaling_to_propagation_rule(resolved_rule)
		_apply_status_density_scaling_to_propagation_rule(status_id, resolved_rule)
		return resolved_rule
	return {}

func notify_damaged_by_enemy(enemy: Node) -> void:
	_apply_passive_status_rules_for_trigger("on_enemy_hit", enemy)

func get_preferred_weapon_family_id() -> String:
	return str(active_character_data.get("preferred_weapon_family", ""))

func get_shop_weapon_family_bias() -> float:
	return maxf(float(active_character_data.get("shop_weapon_family_bias", 0.0)), 0.0)

func get_portal_event_bias(event_id: String) -> float:
	var portal_event_biases_variant: Variant = active_character_data.get("portal_event_biases", {})
	if not (portal_event_biases_variant is Dictionary):
		return 1.0
	var portal_event_biases: Dictionary = portal_event_biases_variant
	return maxf(float(portal_event_biases.get(event_id, 1.0)), 0.0)

func get_portal_reward_tier_bias(tier: int) -> float:
	var portal_reward_tier_biases_variant: Variant = active_character_data.get("portal_reward_tier_biases", {})
	if not (portal_reward_tier_biases_variant is Dictionary):
		return 0.0
	var portal_reward_tier_biases: Dictionary = portal_reward_tier_biases_variant
	return float(portal_reward_tier_biases.get(str(tier), 0.0))

func count_enemies_with_status(status_id: String, max_distance: float = 0.0) -> int:
	if status_id == "":
		return 0
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if max_distance > 0.0 and enemy is Node2D:
			var enemy_node := enemy as Node2D
			if global_position.distance_to(enemy_node.global_position) > max_distance:
				continue
		if enemy.has_method("get_status_stack_count") and int(enemy.call("get_status_stack_count", status_id)) > 0:
			count += 1
	return count

func count_nearby_enemies(max_distance: float) -> int:
	if max_distance <= 0.0:
		return 0
	var count := 0
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or not (enemy is Node2D):
			continue
		var enemy_node := enemy as Node2D
		if global_position.distance_to(enemy_node.global_position) <= max_distance:
			count += 1
	return count

func get_damage_stat_multiplier() -> float:
	return stats.damage

func get_attack_speed_multiplier() -> float:
	return stats.attack_speed

func get_attack_range_multiplier() -> float:
	return stats.attack_range

func get_projectile_speed_multiplier() -> float:
	return stats.projectile_speed

func get_stat_value_for_weapon_bonus(stat_name: String, fallback: float = 0.0) -> float:
	return _get_stat_value(stat_name, fallback)

func _resolve_weapon_family_id(weapon_resource: WeaponData) -> String:
	if weapon_resource.family != "":
		return weapon_resource.family
	if weapon_resource.family_id != "":
		return weapon_resource.family_id
	return ""

func _weapon_slot_index_from_key(keycode: int) -> int:
	match keycode:
		KEY_1: return 0
		KEY_2: return 1
		KEY_3: return 2
		KEY_4: return 3
		KEY_5: return 4
		KEY_6: return 5
		_: return -1

func _equip_family_weapon(index: int) -> void:
	var family_weapon_ids := _get_family_weapon_ids()
	if index < 0 or index >= family_weapon_ids.size():
		return
	var weapon_id := family_weapon_ids[index]
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

	var weapon_resource := _load_weapon_resource(weapon_id)
	if weapon_resource != null and auto_weapon != null and auto_weapon.has_method("set_weapon_data"):
		auto_weapon.call("set_weapon_data", weapon_resource)

	if combined:
		print("Weapon combined: %s -> %s" % [weapon_id, granted_rarity])
	else:
		print("Weapon granted: %s (%s)" % [weapon_id, granted_rarity])
	return true

func _grant_starting_weapon_by_id(weapon_id: String) -> void:
	grant_weapon(weapon_id)

func _get_character_data(character_id: String) -> Dictionary:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null or not data_registry.has_method("get_character"):
		return {}
	var character_variant: Variant = data_registry.call("get_character", character_id)
	if character_variant is Dictionary:
		return character_variant as Dictionary
	return {}

func _resolve_default_character_id() -> void:
	if active_character_id != "":
		return
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry != null and data_registry.has_method("get_default_selectable_character_id"):
		var resolved_character_id := str(data_registry.call("get_default_selectable_character_id"))
		if resolved_character_id != "":
			active_character_id = resolved_character_id
	return

func _resolve_starting_weapon_id(character_data: Dictionary) -> String:
	var starting_weapon_ids_variant: Variant = character_data.get("starting_weapon_ids", [])
	if starting_weapon_ids_variant is Array:
		var starting_weapon_ids: Array = starting_weapon_ids_variant
		for starting_weapon_variant in starting_weapon_ids:
			var starting_weapon_id := str(starting_weapon_variant)
			if starting_weapon_id == "":
				continue
			if _weapon_resource_exists(starting_weapon_id):
				return starting_weapon_id
			_log_resource_warning_once("missing_starting_weapon:%s" % starting_weapon_id, "Missing starting weapon resource: %s" % starting_weapon_id)
	return "heavy_pistol"

func _get_family_weapon_ids() -> Array[String]:
	var family_weapon_ids_variant: Variant = active_character_data.get("family_weapon_ids", [])
	if family_weapon_ids_variant is Array:
		var configured_ids: Array[String] = []
		for weapon_id_variant in family_weapon_ids_variant:
			var weapon_id := str(weapon_id_variant)
			if weapon_id == "":
				continue
			if _weapon_resource_exists(weapon_id):
				configured_ids.append(weapon_id)
			else:
				_log_resource_warning_once("missing_family_weapon:%s" % weapon_id, "Missing family weapon resource: %s" % weapon_id)
		if not configured_ids.is_empty():
			return configured_ids
	if weapon_loadout != null and weapon_loadout.has_method("get_equipped_weapon_ids"):
		var equipped_ids_variant: Variant = weapon_loadout.call("get_equipped_weapon_ids")
		if equipped_ids_variant is Array:
			var equipped_ids: Array[String] = []
			for weapon_id_variant in equipped_ids_variant:
				var weapon_id := str(weapon_id_variant)
				if weapon_id != "":
					equipped_ids.append(weapon_id)
			if not equipped_ids.is_empty():
				return equipped_ids
	return ["heavy_pistol"]

func _apply_character_visual(character_data: Dictionary) -> void:
	if visual_sprite == null:
		return
	var visual_path := str(character_data.get("visual_path", ""))
	if visual_path == "" or not ResourceLoader.exists(visual_path):
		_restore_default_visual_state()
		return
	var texture_resource := load(visual_path)
	if texture_resource is Texture2D:
		visual_sprite.texture = texture_resource as Texture2D
	var default_scale := _default_visual_scale.x if _default_visual_scale != Vector2.ZERO else 0.12
	var scale_value := float(character_data.get("visual_scale", default_scale))
	visual_sprite.scale = Vector2.ONE * scale_value

func _cache_default_visual_state() -> void:
	if visual_sprite == null:
		return
	_default_visual_texture = visual_sprite.texture
	_default_visual_scale = visual_sprite.scale

func _restore_default_visual_state() -> void:
	if visual_sprite == null:
		return
	visual_sprite.texture = _default_visual_texture
	visual_sprite.scale = _default_visual_scale

func _reset_passive_rule_timers(character_data: Dictionary) -> void:
	_passive_rule_timers.clear()
	var passive_rules_variant: Variant = character_data.get("passive_status_rules", [])
	if not (passive_rules_variant is Array):
		return
	var passive_rules: Array = passive_rules_variant
	for index in range(passive_rules.size()):
		var rule_variant: Variant = passive_rules[index]
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		if str(rule.get("trigger", "")) != "proximity_tick":
			continue
		_passive_rule_timers[index] = 0.0

func _process_passive_status_rules(delta: float) -> void:
	var passive_rules_variant: Variant = active_character_data.get("passive_status_rules", [])
	if not (passive_rules_variant is Array):
		return
	var passive_rules: Array = passive_rules_variant
	for index in range(passive_rules.size()):
		var rule_variant: Variant = passive_rules[index]
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		if str(rule.get("trigger", "")) != "proximity_tick":
			continue
		var time_left := float(_passive_rule_timers.get(index, 0.0)) - delta
		if time_left > 0.0:
			_passive_rule_timers[index] = time_left
			continue
		_passive_rule_timers[index] = maxf(float(rule.get("interval", 1.0)), 0.05)
		_apply_passive_status_rule(rule)

func _apply_passive_status_rules_for_trigger(trigger_id: String, enemy: Node) -> void:
	var passive_rules_variant: Variant = active_character_data.get("passive_status_rules", [])
	if not (passive_rules_variant is Array):
		return
	var passive_rules: Array = passive_rules_variant
	for rule_variant in passive_rules:
		if not (rule_variant is Dictionary):
			continue
		var rule: Dictionary = rule_variant
		if str(rule.get("trigger", "")) != trigger_id:
			continue
		_apply_passive_status_rule(rule, enemy)

func _apply_passive_status_rule(rule: Dictionary, enemy_override: Node = null) -> void:
	if enemy_override != null:
		_apply_status_rule_to_enemy(enemy_override, rule)
		return
	var radius := maxf(float(rule.get("radius", 0.0)), 0.0)
	if radius <= 0.0:
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not (enemy is Node2D) or not is_instance_valid(enemy):
			continue
		var enemy_node := enemy as Node2D
		if global_position.distance_to(enemy_node.global_position) > radius:
			continue
		_apply_status_rule_to_enemy(enemy_node, rule)

func _apply_status_rule_to_enemy(enemy: Node, rule: Dictionary) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if not enemy.has_method("apply_status_payload"):
		return
	var status_id := str(rule.get("status_id", ""))
	if status_id == "":
		return
	var status_payload := {
		"status_id": status_id,
		"duration": float(rule.get("duration", 0.0)),
		"tick_interval": float(rule.get("tick_interval", 0.0)),
		"flat_damage": float(rule.get("flat_damage", 0.0)),
		"max_hp_fraction": float(rule.get("max_hp_fraction", 0.0)),
		"max_stacks": int(rule.get("max_stacks", 1))
	}
	var propagation_rule := get_status_propagation_rule(status_id)
	if not propagation_rule.is_empty():
		status_payload["spread_radius"] = float(propagation_rule.get("radius", 0.0))
		status_payload["spread_chance"] = float(propagation_rule.get("chance", 0.0))
		status_payload["spread_duration_scale"] = float(propagation_rule.get("duration_scale", 1.0))
		status_payload["spread_max_targets"] = int(propagation_rule.get("max_targets", 1))
		status_payload["allow_spread"] = true
	var status_power_multiplier := get_status_power_multiplier(status_id)
	enemy.call("apply_status_payload", status_payload, self, "", -1, status_power_multiplier)

func _weapon_resource_exists(weapon_id: String) -> bool:
	return ResourceLoader.exists("res://data/weapons/%s.tres" % weapon_id)

func _apply_stat_multipliers(stat_multipliers_variant: Variant) -> void:
	if not (stat_multipliers_variant is Dictionary):
		return
	var stat_multipliers: Dictionary = stat_multipliers_variant
	for stat_name in stat_multipliers.keys():
		if not _has_stat_property(str(stat_name)):
			continue
		var current_value: Variant = stats.get(str(stat_name))
		var multiplier := float(stat_multipliers[stat_name])
		if current_value is float:
			stats.set(str(stat_name), float(current_value) * multiplier)
		elif current_value is int:
			stats.set(str(stat_name), int(round(float(current_value) * multiplier)))

func _apply_stat_bonuses(stat_bonuses_variant: Variant) -> void:
	if not (stat_bonuses_variant is Dictionary):
		return
	var stat_bonuses: Dictionary = stat_bonuses_variant
	for stat_name in stat_bonuses.keys():
		if not _has_stat_property(str(stat_name)):
			continue
		var current_value: Variant = stats.get(str(stat_name))
		var bonus := float(stat_bonuses[stat_name])
		if current_value is float:
			stats.set(str(stat_name), float(current_value) + bonus)
		elif current_value is int:
			stats.set(str(stat_name), int(current_value) + int(round(bonus)))

func _target_matches_damage_rule(target: Node, damage_rule: Dictionary) -> bool:
	var targets_variant: Variant = damage_rule.get("targets", [])
	if not (targets_variant is Array):
		return false
	var targets: Array = targets_variant
	for target_key_variant in targets:
		var target_key := str(target_key_variant)
		match target_key:
			"elite":
				if bool(target.get("is_elite")):
					return true
			"boss":
				if bool(target.get("is_boss")):
					return true
			"strongest":
				if _is_priority_damage_target(target):
					return true
	return false

func _is_priority_damage_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if bool(target.get("is_priority_target")):
		return true
	if not target.is_in_group("enemies"):
		return false
	var target_hp := float(target.get("current_hp"))
	var strongest_hp := -INF
	var strongest_target: Node = null
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		var enemy_hp := float(enemy.get("current_hp"))
		if enemy_hp > strongest_hp:
			strongest_hp = enemy_hp
			strongest_target = enemy
	return strongest_target == target

func _load_weapon_resource(weapon_id: String) -> WeaponData:
	var resource_path := "res://data/weapons/%s.tres" % weapon_id
	if not ResourceLoader.exists(resource_path):
		_log_resource_warning_once("missing_weapon:%s" % weapon_id, "Missing weapon resource: %s" % resource_path)
		return null
	var resource := load(resource_path)
	if resource is WeaponData:
		return resource as WeaponData
	_log_resource_warning_once("invalid_weapon:%s" % weapon_id, "Invalid weapon resource type: %s" % resource_path)
	return null

func _log_resource_warning_once(warning_key: String, message: String) -> void:
	if _logged_resource_warnings.has(warning_key):
		return
	_logged_resource_warnings[warning_key] = true
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
		"items": owned_items.duplicate(),
		"weapon_entries": get_weapon_ui_entries()
	}

func get_weapon_ui_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
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
		var weapon_id := str(entry.get("id", ""))
		var weapon_resource := _load_weapon_resource(weapon_id)
		if weapon_resource == null:
			entries.append(entry)
			continue
		var family_id := _resolve_weapon_family_id(weapon_resource)
		var required_kills := _get_effective_kill_requirement(weapon_resource, family_id)
		var kill_count := int(entry.get("kill_count", 0))
		var milestones_earned := int(entry.get("milestones_earned", 0))
		var progress_in_stage := kill_count - (required_kills * milestones_earned)
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
	return maxi(
		int(round(float(weapon_resource.kill_milestone_base_kills) * get_family_kill_requirement_multiplier(family_id))),
		1
	)

func _apply_pressure_scaling_to_propagation_rule(rule: Dictionary) -> void:
	var pressure_radius := maxf(float(rule.get("pressure_radius", 0.0)), 0.0)
	if pressure_radius <= 0.0:
		return
	var nearby_enemy_count := count_nearby_enemies(pressure_radius)
	if nearby_enemy_count <= 0:
		return
	var pressure_target_limit := maxi(int(rule.get("pressure_target_limit", nearby_enemy_count)), 1)
	var effective_pressure := mini(nearby_enemy_count, pressure_target_limit)
	rule["chance"] = clampf(
		float(rule.get("chance", 0.0)) + (float(rule.get("spread_chance_per_nearby_enemy", 0.0)) * effective_pressure),
		0.0,
		1.0
	)
	rule["radius"] = maxf(
		float(rule.get("radius", 0.0)) + (float(rule.get("spread_radius_per_nearby_enemy", 0.0)) * effective_pressure),
		0.0
	)
	rule["max_targets"] = maxi(
		int(round(float(rule.get("max_targets", 1)) + (float(rule.get("spread_max_targets_per_nearby_enemy", 0.0)) * effective_pressure))),
		1
	)

func _apply_status_density_scaling_to_propagation_rule(status_id: String, rule: Dictionary) -> void:
	var counted_status_id := str(rule.get("spread_status_count_id", status_id))
	if counted_status_id == "":
		return
	var count_radius := maxf(float(rule.get("spread_status_count_radius", 0.0)), 0.0)
	var marked_enemy_count := count_enemies_with_status(counted_status_id, count_radius)
	if marked_enemy_count <= 0:
		return
	var marked_enemy_limit := maxi(int(rule.get("spread_status_count_limit", marked_enemy_count)), 1)
	var effective_marked_enemy_count := mini(marked_enemy_count, marked_enemy_limit)
	rule["chance"] = clampf(
		float(rule.get("chance", 0.0)) + (float(rule.get("spread_chance_per_marked_enemy", 0.0)) * effective_marked_enemy_count),
		0.0,
		1.0
	)
	rule["radius"] = maxf(
		float(rule.get("radius", 0.0)) + (float(rule.get("spread_radius_per_marked_enemy", 0.0)) * effective_marked_enemy_count),
		0.0
	)
	rule["max_targets"] = maxi(
		int(round(float(rule.get("max_targets", 1)) + (float(rule.get("spread_max_targets_per_marked_enemy", 0.0)) * effective_marked_enemy_count))),
		1
	)
