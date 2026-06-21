class_name MainGameStartRuntime
extends RefCounted

static func apply_selected_character(player: Node, selectable_characters: Array[String], selected_character_index: int) -> String:
	if selectable_characters.is_empty() or player == null or not player.has_method("apply_character_by_id"):
		return ""
	var character_id := selectable_characters[selected_character_index]
	player.call("apply_character_by_id", character_id)
	return character_id

static func new_run_seed(run_rng: Node) -> void:
	if run_rng != null and run_rng.has_method("new_run"):
		run_rng.call("new_run")

static func begin_run(
	player: Node,
	selectable_characters: Array[String],
	selected_character_index: int,
	character_select_layer: CanvasLayer,
	apply_debug_quick_shop_preset_callback: Callable,
	hide_run_overlays_callback: Callable,
	set_gameplay_active_callback: Callable
) -> Dictionary:
	var applied_character_id := apply_selected_character(
		player,
		selectable_characters,
		selected_character_index
	)
	if apply_debug_quick_shop_preset_callback.is_valid():
		apply_debug_quick_shop_preset_callback.call()
	if hide_run_overlays_callback.is_valid():
		hide_run_overlays_callback.call()
	if set_gameplay_active_callback.is_valid():
		set_gameplay_active_callback.call(true)
	if character_select_layer != null:
		character_select_layer.visible = false
	return {
		"run_started": true,
		"applied_character_id": applied_character_id
	}

static func apply_debug_quick_shop_preset(
	player: Node,
	effective_preset: String,
	starting_gold: int
) -> void:
	if player != null and starting_gold > 0 and player.has_method("add_gold"):
		player.call("add_gold", starting_gold)

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
