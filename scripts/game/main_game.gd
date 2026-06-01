extends Node2D

@export_enum("normal", "shop_test", "combat_test") var debug_run_preset: String = "shop_test"
@export var debug_quick_shop_mode: bool = true
@export var debug_wave_duration_seconds: float = 3.0
@export var debug_starting_gold: int = 50
@export var debug_combat_wave_duration_seconds: float = 20.0
@export var debug_combat_starting_gold: int = 10

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node = $EnemySpawner
@onready var wave_panel: Control = $WaveIntermission/Panel
@onready var wave_continue_button: Button = $WaveIntermission/Panel/ContinueButton
@onready var character_select_layer: CanvasLayer = $CharacterSelect
@onready var character_label: Label = $CharacterSelect/Panel/CharacterLabel
@onready var start_button: Button = $CharacterSelect/Panel/StartButton
@onready var shop_controller: Node = $ShopController
@onready var level_up_panel: Control = $LevelUpUI/Panel
@onready var level_up_title: Label = $LevelUpUI/Panel/Title
@onready var level_up_reroll_button: Button = $LevelUpUI/Panel/RerollButton
@onready var run_end_layer: CanvasLayer = $RunEndUI
@onready var run_end_panel: Control = $RunEndUI/Panel
@onready var run_end_title: Label = $RunEndUI/Panel/Title
@onready var run_end_summary: Label = $RunEndUI/Panel/Summary
@onready var run_end_restart_button: Button = $RunEndUI/Panel/RestartButton
@onready var run_end_main_menu_button: Button = $RunEndUI/Panel/MainMenuButton
@onready var level_up_choice_buttons: Array[Button] = [
	$LevelUpUI/Panel/Choice1,
	$LevelUpUI/Panel/Choice2,
	$LevelUpUI/Panel/Choice3,
	$LevelUpUI/Panel/Choice4
]
var waiting_for_restart: bool = false
var waiting_for_wave_continue: bool = false
var waiting_for_level_up_choice: bool = false
var selectable_characters: Array[String] = ["gunslinger"]
var character_display_names: Dictionary = {"gunslinger": "The Gunslinger"}
var selected_character_index: int = 0
var run_started: bool = false
var levelup_rng: RandomNumberGenerator
var active_level_up_choices: Array[Dictionary] = []
var level_up_stat_ids: Array[String] = ["damage", "attack_speed", "max_hp", "movement_speed", "armor"]
var rarity_weights: Dictionary = {"Common": 0.65, "Rare": 0.25, "Epic": 0.08, "Legendary": 0.02}
var rarity_values_by_stat: Dictionary = {
	"damage": {"Common": 0.05, "Rare": 0.12, "Epic": 0.22, "Legendary": 0.40},
	"attack_speed": {"Common": 0.05, "Rare": 0.10, "Epic": 0.18, "Legendary": 0.30},
	"max_hp": {"Common": 10.0, "Rare": 25.0, "Epic": 45.0, "Legendary": 75.0},
	"movement_speed": {"Common": 10.0, "Rare": 25.0, "Epic": 40.0, "Legendary": 65.0},
	"armor": {"Common": 1.0, "Rare": 3.0, "Epic": 5.0, "Legendary": 9.0}
}
var stat_display_names: Dictionary = {
	"damage": "Damage",
	"attack_speed": "Attack Speed",
	"max_hp": "Max HP",
	"movement_speed": "Move Speed",
	"armor": "Armor"
}
var level_up_reroll_count: int = 0
var level_up_base_reroll_cost: int = 2
var default_wave_duration_seconds: float = 30.0
var run_finished: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_new_run_seed()
	if player == null:
		push_error("Main scene is missing a Player node.")
		return

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if player.has_signal("level_up_pending_changed"):
		player.level_up_pending_changed.connect(_on_level_up_pending_changed)
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)
	var boss_manager := get_node_or_null("BossManager")
	if boss_manager != null and boss_manager.has_signal("boss_defeated"):
		boss_manager.connect("boss_defeated", _on_boss_defeated)
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if wave_continue_button != null:
		wave_continue_button.pressed.connect(_on_wave_continue_pressed)
	if shop_controller != null and shop_controller.has_signal("continue_requested"):
		shop_controller.connect("continue_requested", _on_wave_continue_pressed)
	for index in level_up_choice_buttons.size():
		level_up_choice_buttons[index].pressed.connect(_on_level_up_choice_pressed.bind(index))
	if level_up_reroll_button != null:
		level_up_reroll_button.pressed.connect(_on_level_up_reroll_pressed)
	if run_end_restart_button != null:
		run_end_restart_button.pressed.connect(_on_run_end_restart_pressed)
	if run_end_main_menu_button != null:
		run_end_main_menu_button.pressed.connect(_on_run_end_main_menu_pressed)
	levelup_rng = _resolve_rng("levelup")
	if enemy_spawner != null:
		default_wave_duration_seconds = float(enemy_spawner.get("wave_duration_seconds"))
		_apply_debug_wave_duration()
	_load_selectable_characters()
	_update_character_debug_label()
	_hide_run_overlays()
	_set_gameplay_active(false)

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_PLUS or key_event.keycode == KEY_KP_ADD:
		_cycle_debug_run_preset()
		return
	if not run_started:
		if event.is_action_pressed("cycle_character") or key_event.keycode == KEY_C:
			_cycle_character()
			_update_character_debug_label()
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
			_on_start_pressed()
		return

	if waiting_for_restart and key_event.keycode == KEY_R:
		print("Restarting current scene...")
		_new_run_seed()
		get_tree().reload_current_scene()
		return
	if waiting_for_wave_continue and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
		_on_wave_continue_pressed()
		return
	if waiting_for_level_up_choice:
		return
	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")
		return

func _on_player_died() -> void:
	if run_finished:
		return
	run_finished = true
	waiting_for_restart = true
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	_set_combat_active(false)
	_hide_run_overlays()
	_show_run_end(false)

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	if should_pause:
		print("GAME PAUSED")
	else:
		print("GAME RESUMED")

func _cycle_character() -> void:
	if selectable_characters.is_empty():
		return
	selected_character_index = (selected_character_index + 1) % selectable_characters.size()

func _apply_selected_character() -> void:
	if selectable_characters.is_empty():
		return
	if player != null and player.has_method("apply_character_by_id"):
		player.call("apply_character_by_id", selectable_characters[selected_character_index])
		print("Selected character (placeholder): %s" % selectable_characters[selected_character_index])

func _new_run_seed() -> void:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("new_run"):
		run_rng.call("new_run")

func _on_start_pressed() -> void:
	if run_started:
		return
	run_started = true
	_apply_selected_character()
	_apply_debug_quick_shop_preset()
	_hide_run_overlays()
	_set_gameplay_active(true)
	if character_select_layer != null:
		character_select_layer.visible = false

func _apply_debug_quick_shop_preset() -> void:
	var preset := _get_effective_debug_preset()
	var starting_gold := 0
	match preset:
		"shop_test":
			starting_gold = debug_starting_gold
		"combat_test":
			starting_gold = debug_combat_starting_gold
		_:
			starting_gold = 0
	if player != null and starting_gold > 0 and player.has_method("add_gold"):
		player.call("add_gold", starting_gold)
	_apply_debug_wave_duration()
	print("DEBUG PRESET APPLIED: %s | Gold: %d | Wave Duration: %.1fs" % [preset, starting_gold, _get_debug_wave_duration_for_preset(preset)])

func _apply_debug_wave_duration() -> void:
	if enemy_spawner == null:
		return
	var preset := _get_effective_debug_preset()
	if preset == "normal":
		enemy_spawner.set("wave_duration_seconds", default_wave_duration_seconds)
	else:
		enemy_spawner.set("wave_duration_seconds", _get_debug_wave_duration_for_preset(preset))

func _cycle_debug_run_preset() -> void:
	var modes: Array[String] = ["normal", "shop_test", "combat_test"]
	var current_index := modes.find(debug_run_preset)
	if current_index == -1:
		current_index = 0
	debug_run_preset = modes[(current_index + 1) % modes.size()]
	debug_quick_shop_mode = debug_run_preset != "normal"
	_apply_debug_wave_duration()
	print("DEBUG PRESET: %s | Wave Duration %.1fs | Start Gold %d on run start" % [debug_run_preset, _get_current_wave_duration(), _get_current_starting_gold_for_preset()])

func get_debug_preset_label() -> String:
	return "DebugPreset: %s" % _get_effective_debug_preset()

func _get_effective_debug_preset() -> String:
	if not debug_quick_shop_mode:
		return "normal"
	if debug_run_preset == "normal":
		return "shop_test"
	return debug_run_preset

func _get_debug_wave_duration_for_preset(preset: String) -> float:
	match preset:
		"shop_test":
			return maxf(debug_wave_duration_seconds, 1.0)
		"combat_test":
			return maxf(debug_combat_wave_duration_seconds, 1.0)
		_:
			return default_wave_duration_seconds

func _get_current_starting_gold_for_preset() -> int:
	match _get_effective_debug_preset():
		"shop_test":
			return debug_starting_gold
		"combat_test":
			return debug_combat_starting_gold
		_:
			return 0

func _get_current_wave_duration() -> float:
	if enemy_spawner != null:
		return float(enemy_spawner.get("wave_duration_seconds"))
	return default_wave_duration_seconds

func _set_gameplay_active(active: bool) -> void:
	_set_combat_active(active)
	var shop_mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	var shop_node := get_node_or_null("ShopController")
	if shop_node != null:
		shop_node.process_mode = shop_mode
	if not active:
		_hide_run_overlays()
	if character_select_layer != null:
		character_select_layer.visible = not active

func _hide_run_overlays() -> void:
	_hide_control_if_present("WaveIntermission/Panel")
	_hide_control_if_present("ShopUI/Panel")
	_hide_control_if_present("LevelUpUI/Panel")
	_hide_control_if_present("RunEndUI/Panel")
	_hide_control_if_present("RunEndUI")

func _hide_control_if_present(path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node is Control:
		(node as Control).visible = false
	if node is CanvasLayer:
		(node as CanvasLayer).visible = false

func _load_selectable_characters() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null or not data_registry.has_method("get_character_ids"):
		return
	var ids_variant: Variant = data_registry.call("get_character_ids")
	if ids_variant is Array:
		var ids: Array = ids_variant
		if ids.is_empty():
			return
		var normalized: Array[String] = []
		for id_value in ids:
			var id_string := str(id_value)
			if id_string != "":
				normalized.append(id_string)
		if not normalized.is_empty():
			selectable_characters = normalized
			selected_character_index = 0
			_refresh_character_display_names(data_registry)
			print("Character selection list: " + str(selectable_characters))

func _update_character_debug_label() -> void:
	if character_label == null or selectable_characters.is_empty():
		return
	var selected_id := selectable_characters[selected_character_index]
	var display_name := str(character_display_names.get(selected_id, selected_id))
	character_label.text = "Selected: %s (C to cycle, Enter to start)" % display_name

func _refresh_character_display_names(data_registry: Node) -> void:
	character_display_names.clear()
	for character_id in selectable_characters:
		var default_name := str(character_id)
		var display_name := default_name
		if data_registry.has_method("get_character"):
			var character_variant: Variant = data_registry.call("get_character", character_id)
			if character_variant is Dictionary:
				display_name = str(character_variant.get("display_name", default_name))
		character_display_names[character_id] = display_name

func _on_wave_completed(wave_index: int) -> void:
	_enter_intermission_phase(wave_index)

func _on_wave_continue_pressed() -> void:
	if not waiting_for_wave_continue:
		return
	_exit_intermission_phase()
	_finish_intermission_or_open_levelup()

func _enter_intermission_phase(wave_index: int) -> void:
	waiting_for_wave_continue = true
	_set_combat_active(false)
	_clear_combat_entities()
	if _is_shop_enabled():
		_hide_control_if_present("WaveIntermission/Panel")
		_hide_control_if_present("LevelUpUI/Panel")
	else:
		_hide_run_overlays()
	if not _is_shop_enabled() and wave_panel != null:
		wave_panel.visible = true
	print("Wave %d complete. Press Continue to start next wave." % wave_index)

func _exit_intermission_phase() -> void:
	waiting_for_wave_continue = false
	_hide_run_overlays()

func _finish_intermission_or_open_levelup() -> void:
	if player != null and player.has_method("has_pending_level_up") and bool(player.call("has_pending_level_up")):
		_open_level_up_screen()
	else:
		_start_next_wave_after_intermission()

func _start_next_wave_after_intermission() -> void:
	_heal_player_to_full()
	_set_combat_active(true)
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")

func _set_combat_active(active: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for path in ["Player", "EnemySpawner", "PortalEventManager", "RewardController", "BossManager"]:
		var node := get_node_or_null(path)
		if node != null:
			node.process_mode = mode
	_set_group_process_mode("enemies", mode)
	_set_group_process_mode("projectiles", mode)

func _set_group_process_mode(group_name: StringName, mode: Node.ProcessMode) -> void:
	var nodes := get_tree().get_nodes_in_group(group_name)
	for group_node in nodes:
		if group_node is Node:
			(group_node as Node).process_mode = mode

func _clear_combat_entities() -> void:
	_clear_group_nodes("enemies")
	_clear_group_nodes("projectiles")

func _clear_group_nodes(group_name: StringName) -> void:
	var nodes := get_tree().get_nodes_in_group(group_name)
	for group_node in nodes:
		if group_node is Node:
			(group_node as Node).queue_free()

func _heal_player_to_full() -> void:
	if player != null and player.has_method("heal_to_full"):
		player.call("heal_to_full")

func _is_shop_enabled() -> bool:
	if shop_controller == null:
		return false
	return bool(shop_controller.get("enabled"))

func _on_level_up_pending_changed() -> void:
	print("Level-up pending. Will show after wave.")

func _on_boss_defeated() -> void:
	if run_finished:
		return
	run_finished = true
	waiting_for_restart = true
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	_set_combat_active(false)
	_hide_run_overlays()
	_show_run_end(true)

func _show_run_end(victory: bool) -> void:
	if run_end_layer != null:
		run_end_layer.visible = true
	if run_end_panel != null:
		run_end_panel.visible = true
	if run_end_title != null:
		run_end_title.text = "Victory!" if victory else "Game Over"
	if run_end_summary != null:
		var wave := int(enemy_spawner.get("current_wave_index")) if enemy_spawner != null else 1
		run_end_summary.text = "Reached Wave %d\nPress Restart or R to play again." % wave

func _on_run_end_restart_pressed() -> void:
	_new_run_seed()
	get_tree().reload_current_scene()

func _on_run_end_main_menu_pressed() -> void:
	_new_run_seed()
	get_tree().reload_current_scene()

func _open_level_up_screen() -> void:
	waiting_for_level_up_choice = true
	level_up_reroll_count = 0
	_set_combat_active(false)
	_roll_level_up_choices()
	if level_up_title != null:
		level_up_title.text = "Level Up! Pick 1 of 4"
	_update_level_up_reroll_button()
	if level_up_panel != null:
		level_up_panel.visible = true
	print("Level-up choices shown.")

func _roll_level_up_choices() -> void:
	active_level_up_choices.clear()
	for _slot in 4:
		var stat_index := levelup_rng.randi_range(0, level_up_stat_ids.size() - 1)
		var stat_id := level_up_stat_ids[stat_index]
		active_level_up_choices.append(_build_level_up_choice(stat_id))
	_refresh_levelup_buttons()

func _refresh_levelup_buttons() -> void:
	for index in level_up_choice_buttons.size():
		var button := level_up_choice_buttons[index]
		if index < active_level_up_choices.size():
			var choice := active_level_up_choices[index]
			button.text = str(choice.get("label", "Upgrade"))
			button.disabled = false
		else:
			button.text = "N/A"
			button.disabled = true

func _on_level_up_choice_pressed(index: int) -> void:
	if not waiting_for_level_up_choice:
		return
	if index < 0 or index >= active_level_up_choices.size():
		return
	if player == null:
		return
	var choice := active_level_up_choices[index]
	if player.has_method("apply_level_up_bonus"):
		player.call("apply_level_up_bonus", str(choice.get("id", "")), float(choice.get("value", 0.0)))
	if player.has_method("consume_pending_level_up"):
		player.call("consume_pending_level_up")
	waiting_for_level_up_choice = false
	if level_up_panel != null:
		level_up_panel.visible = false
	if player.has_method("has_pending_level_up") and bool(player.call("has_pending_level_up")):
		_open_level_up_screen()
		return
	_start_next_wave_after_intermission()

func _on_level_up_reroll_pressed() -> void:
	if not waiting_for_level_up_choice:
		return
	if player == null or not player.has_method("spend_gold"):
		return
	var reroll_cost := _current_level_up_reroll_cost()
	var paid: bool = bool(player.call("spend_gold", reroll_cost))
	if not paid:
		print("Not enough gold for level-up reroll. Need %d." % reroll_cost)
		return
	level_up_reroll_count += 1
	_roll_level_up_choices()
	_update_level_up_reroll_button()
	print("Level-up choices rerolled for %d gold." % reroll_cost)

func _current_level_up_reroll_cost() -> int:
	return level_up_base_reroll_cost + level_up_reroll_count

func _update_level_up_reroll_button() -> void:
	if level_up_reroll_button == null:
		return
	level_up_reroll_button.text = "Reroll (%dG)" % _current_level_up_reroll_cost()

func _build_level_up_choice(stat_id: String) -> Dictionary:
	var rarity := _roll_rarity_name()
	var value := _get_rarity_value(stat_id, rarity)
	var display_name := str(stat_display_names.get(stat_id, stat_id))
	var formatted_value := "%+.0f" % value
	if stat_id == "damage" or stat_id == "attack_speed":
		formatted_value = "%+.0f%%" % (value * 100.0)
	return {
		"id": stat_id,
		"value": value,
		"rarity": rarity,
		"label": "[%s] %s %s" % [rarity, display_name, formatted_value]
	}

func _roll_rarity_name() -> String:
	var roll := levelup_rng.randf()
	var threshold := 0.0
	for rarity_name in ["Common", "Rare", "Epic", "Legendary"]:
		threshold += float(rarity_weights.get(rarity_name, 0.0))
		if roll <= threshold:
			return rarity_name
	return "Common"

func _get_rarity_value(stat_id: String, rarity_name: String) -> float:
	var stat_entry_variant: Variant = rarity_values_by_stat.get(stat_id, {})
	if stat_entry_variant is Dictionary:
		var stat_entry: Dictionary = stat_entry_variant
		return float(stat_entry.get(rarity_name, 0.0))
	return 0.0

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
