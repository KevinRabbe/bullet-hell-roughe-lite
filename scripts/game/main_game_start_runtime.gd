class_name MainGameStartRuntime
extends RefCounted

const ArenaBoundsRuntime = preload("res://scripts/game/arena_bounds.gd")
const DebugRunPresetRuntimeRef = preload("res://scripts/game/debug_run_preset_runtime.gd")

static func apply_selected_character(player: Node, selectable_characters: Array[String], selected_character_index: int) -> String:
	if selectable_characters.is_empty() or player == null or not player.has_method("apply_character_by_id"):
		return ""
	var character_id := selectable_characters[selected_character_index]
	player.call("apply_character_by_id", character_id)
	return character_id

static func apply_run_start_payload(player: Node, payload: Dictionary) -> String:
	if player == null:
		return ""
	var character_id := str(payload.get("character_id", ""))
	if character_id == "":
		return ""
	var starting_weapon_id := str(payload.get("starting_weapon_id", ""))
	if player.has_method("apply_character_loadout"):
		player.call("apply_character_loadout", character_id, starting_weapon_id)
	elif player.has_method("apply_character_by_id"):
		player.call("apply_character_by_id", character_id)
	return character_id

static func new_run_seed(run_rng: Node) -> void:
	if run_rng != null and run_rng.has_method("new_run"):
		run_rng.call("new_run")

static func apply_debug_quick_shop_preset(
	player: Node,
	effective_preset: String,
	starting_gold: int
) -> void:
	if player != null and starting_gold > 0 and player.has_method("add_gold"):
		player.call("add_gold", starting_gold)
	_apply_weapon_grants_for_preset(player, effective_preset)
	_apply_arena_size_for_preset(player, effective_preset)
	_apply_scene_scenario(player, effective_preset)

static func set_wave_duration_for_preset(
	enemy_spawner: Node,
	preset: String,
	default_wave_duration_seconds: float,
	debug_preset_wave_duration: float
) -> void:
	if enemy_spawner == null:
		return
	if preset == "normal":
		enemy_spawner.set("wave_duration_seconds", default_wave_duration_seconds)
	else:
		enemy_spawner.set("wave_duration_seconds", debug_preset_wave_duration)

static func _apply_weapon_grants_for_preset(player: Node, preset: String) -> void:
	if player == null or not player.has_method("grant_weapon"):
		return
	for grant in DebugRunPresetRuntimeRef.weapon_grants_for_preset(preset):
		var weapon_id := str(grant.get("id", ""))
		if weapon_id == "":
			continue
		var rarity := str(grant.get("rarity", "common"))
		player.call("grant_weapon", weapon_id, rarity)

static func _apply_arena_size_for_preset(requester: Node, preset: String) -> void:
	if requester == null:
		return
	var arena_bounds := ArenaBoundsRuntime.ensure_for_scene(requester)
	if arena_bounds == null or not arena_bounds.has_method("set_size_class_id"):
		return
	arena_bounds.call("set_size_class_id", DebugRunPresetRuntimeRef.arena_size_class_for_preset(preset))

static func _apply_scene_scenario(requester: Node, preset: String) -> void:
	if requester == null or requester.get_tree() == null:
		return
	var scene := requester.get_tree().current_scene
	if scene == null:
		return

	var enemy_spawner := scene.get_node_or_null("EnemySpawner")
	if enemy_spawner != null and enemy_spawner.has_method("configure_starting_wave"):
		enemy_spawner.call("configure_starting_wave", DebugRunPresetRuntimeRef.wave_index_for_preset(preset))

	var portal_event_id := DebugRunPresetRuntimeRef.portal_event_id_for_preset(preset)
	if portal_event_id != "":
		var portal_event_manager := scene.get_node_or_null("PortalEventManager")
		if portal_event_manager != null and portal_event_manager.has_method("configure_debug_capture_event"):
			portal_event_manager.call("configure_debug_capture_event", portal_event_id)

	var boss_id := DebugRunPresetRuntimeRef.boss_id_for_preset(preset)
	if boss_id != "":
		var boss_manager := scene.get_node_or_null("BossManager")
		if boss_manager != null and boss_manager.has_method("spawn_boss"):
			boss_manager.call("spawn_boss", boss_id)
