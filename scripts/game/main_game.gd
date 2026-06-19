extends Node2D

const CharacterSelectionRuntime = preload("res://scripts/game/character_selection_runtime.gd")
const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const DebugRunPresetRuntime = preload("res://scripts/game/debug_run_preset_runtime.gd")
const LevelUpRuntime = preload("res://scripts/game/level_up_runtime.gd")
const MainGameActivationRuntime = preload("res://scripts/game/main_game_activation_runtime.gd")
const RunFlowRuntime = preload("res://scripts/game/run_flow_runtime.gd")
const MainGameStartRuntime = preload("res://scripts/game/main_game_start_runtime.gd")

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
@onready var level_up_choice_buttons: Array[Button] = [
	$LevelUpUI/Panel/Choice1,
	$LevelUpUI/Panel/Choice2,
	$LevelUpUI/Panel/Choice3,
	$LevelUpUI/Panel/Choice4
]
@onready var boss_manager: Node = $BossManager
@onready var run_end_layer: CanvasLayer = $RunEndUI
@onready var run_end_panel: Control = $RunEndUI/Panel
@onready var run_end_title: Label = $RunEndUI/Panel/Title
@onready var run_end_body: Label = $RunEndUI/Panel/Body
@onready var run_end_restart_button: Button = $RunEndUI/Panel/RestartButton
@onready var run_end_menu_button: Button = $RunEndUI/Panel/MainMenuButton
var waiting_for_restart: bool = false
var waiting_for_wave_continue: bool = false
var waiting_for_level_up_choice: bool = false
var run_end_state: String = "inactive"
var selectable_characters: Array[String] = []
var character_display_names: Dictionary = {}
var selected_character_index: int = 0
var run_started: bool = false
var levelup_rng: RandomNumberGenerator
var active_level_up_choices: Array[Dictionary] = []
var level_up_reroll_count: int = 0
var level_up_base_reroll_cost: int = 2
var default_wave_duration_seconds: float = 30.0

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
	if boss_manager != null and boss_manager.has_signal("boss_defeated_signal"):
		boss_manager.connect("boss_defeated_signal", _on_boss_defeated)
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
		run_end_restart_button.pressed.connect(_restart_run)
	if run_end_menu_button != null:
		run_end_menu_button.pressed.connect(_return_to_main_menu)
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
		_restart_run()
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
	_enter_run_end_state("game_over")

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
	var applied_character_id := MainGameStartRuntime.apply_selected_character(
		player,
		selectable_characters,
		selected_character_index
	)
	if applied_character_id != "":
		print("Selected character (placeholder): %s" % applied_character_id)

func _new_run_seed() -> void:
	MainGameStartRuntime.new_run_seed(get_node_or_null("/root/RunRng"))

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
	var starting_gold := _get_current_starting_gold_for_preset()
	MainGameStartRuntime.apply_debug_quick_shop_preset(player, preset, starting_gold)
	_apply_debug_wave_duration()
	print("DEBUG PRESET APPLIED: %s | Gold: %d | Wave Duration: %.1fs" % [preset, starting_gold, _get_debug_wave_duration_for_preset(preset)])

func _apply_debug_wave_duration() -> void:
	var preset := _get_effective_debug_preset()
	MainGameStartRuntime.set_wave_duration_for_preset(
		enemy_spawner,
		preset,
		default_wave_duration_seconds,
		_get_debug_wave_duration_for_preset(preset)
	)

func _cycle_debug_run_preset() -> void:
	debug_run_preset = DebugRunPresetRuntime.next_preset(debug_run_preset)
	debug_quick_shop_mode = debug_run_preset != "normal"
	_apply_debug_wave_duration()
	print("DEBUG PRESET: %s | Wave Duration %.1fs | Start Gold %d on run start" % [debug_run_preset, _get_current_wave_duration(), _get_current_starting_gold_for_preset()])

func get_debug_preset_label() -> String:
	return "DebugPreset: %s" % _get_effective_debug_preset()

func _get_effective_debug_preset() -> String:
	return DebugRunPresetRuntime.effective_preset(debug_quick_shop_mode, debug_run_preset)

func _get_debug_wave_duration_for_preset(preset: String) -> float:
	return DebugRunPresetRuntime.wave_duration_for_preset(
		preset,
		default_wave_duration_seconds,
		debug_wave_duration_seconds,
		debug_combat_wave_duration_seconds
	)

func _get_current_starting_gold_for_preset() -> int:
	return DebugRunPresetRuntime.starting_gold_for_preset(
		_get_effective_debug_preset(),
		debug_starting_gold,
		debug_combat_starting_gold
	)

func _get_current_wave_duration() -> float:
	if enemy_spawner != null:
		return float(enemy_spawner.get("wave_duration_seconds"))
	return default_wave_duration_seconds

func _set_gameplay_active(active: bool) -> void:
	MainGameActivationRuntime.set_gameplay_active(
		self,
		character_select_layer,
		get_node_or_null("ShopController"),
		active
	)

func _hide_run_overlays() -> void:
	MainGameActivationRuntime.hide_run_overlays(self)

func _load_selectable_characters() -> void:
	var data_registry := get_node_or_null("/root/DataRegistry")
	if data_registry == null:
		return
	var selection_state := CharacterSelectionRuntime.load_selection_state(data_registry)
	if selection_state.is_empty():
		return
	var ids_variant: Variant = selection_state.get("ids", [])
	if not (ids_variant is Array):
		return
	var ids: Array = ids_variant
	var normalized := CharacterSelectionRuntime.normalize_character_ids(ids)
	if normalized.is_empty():
		return
	selectable_characters = normalized
	selected_character_index = 0
	var display_names_variant: Variant = selection_state.get("display_names", {})
	character_display_names = display_names_variant if display_names_variant is Dictionary else {}
	print("Character selection list: " + str(selectable_characters))

func _update_character_debug_label() -> void:
	if character_label == null or selectable_characters.is_empty():
		return
	var selected_id := selectable_characters[selected_character_index]
	var display_name := str(character_display_names.get(selected_id, selected_id))
	character_label.text = "Selected: %s (C to cycle, Enter to start)" % display_name

func _on_wave_completed(wave_index: int) -> void:
	_enter_intermission_phase(wave_index)

func _on_boss_defeated() -> void:
	_enter_run_end_state("victory")

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
		if wave_panel != null:
			wave_panel.visible = false
		if level_up_panel != null:
			level_up_panel.visible = false
	else:
		_hide_run_overlays()
	if not _is_shop_enabled() and wave_panel != null:
		wave_panel.visible = true
	print("Wave %d complete. Press Continue to start next wave." % wave_index)

func _exit_intermission_phase() -> void:
	waiting_for_wave_continue = false
	_hide_run_overlays()

func _finish_intermission_or_open_levelup() -> void:
	if RunFlowRuntime.has_pending_level_up(player):
		_open_level_up_screen()
	else:
		_start_next_wave_after_intermission()

func _start_next_wave_after_intermission() -> void:
	_heal_player_to_full()
	_set_combat_active(true)
	run_end_state = "inactive"
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")

func _set_combat_active(active: bool) -> void:
	var mode: Node.ProcessMode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	RunFlowRuntime.set_process_mode_for_paths(
		self,
		["Player", "EnemySpawner", "PortalEventManager", "RewardController", "BossManager"],
		mode
	)
	RunFlowRuntime.set_group_process_mode(get_tree(), "enemies", mode)
	RunFlowRuntime.set_group_process_mode(get_tree(), "projectiles", mode)

func _enter_run_end_state(state: String) -> void:
	if run_end_state == state:
		return
	run_end_state = state
	waiting_for_restart = RunFlowRuntime.should_wait_for_restart(state)
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	_set_combat_active(false)
	_hide_run_overlays()
	var copy := RunFlowRuntime.get_run_end_copy(state)
	if run_end_panel != null:
		run_end_panel.visible = true
	if run_end_title != null:
		run_end_title.text = str(copy.get("title", "Victory"))
	if run_end_body != null:
		run_end_body.text = str(copy.get("body", "The arena is clear. Press R or Restart to run it back."))

func _restart_run() -> void:
	print("Restarting current scene...")
	_new_run_seed()
	get_tree().reload_current_scene()

func _return_to_main_menu() -> void:
	_new_run_seed()
	get_tree().change_scene_to_file("res://scenes/ui/MainMenu.tscn")

func _clear_combat_entities() -> void:
	RunFlowRuntime.clear_group_nodes(get_tree(), "enemies")
	RunFlowRuntime.clear_group_nodes(get_tree(), "projectiles")

func _heal_player_to_full() -> void:
	if player != null and player.has_method("heal_to_full"):
		player.call("heal_to_full")

func _is_shop_enabled() -> bool:
	if shop_controller == null:
		return false
	return shop_controller.get("enabled") == true

func _on_level_up_pending_changed() -> void:
	print("Level-up pending. Will show after wave.")

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
	active_level_up_choices = LevelUpRuntime.build_choices(levelup_rng)
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
	if player.has_method("has_pending_level_up") and player.call("has_pending_level_up") == true:
		_open_level_up_screen()
		return
	_start_next_wave_after_intermission()

func _on_level_up_reroll_pressed() -> void:
	if not waiting_for_level_up_choice:
		return
	if player == null or not player.has_method("spend_gold"):
		return
	var reroll_cost := _current_level_up_reroll_cost()
	var paid: bool = player.call("spend_gold", reroll_cost) == true
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

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "MainGame")
