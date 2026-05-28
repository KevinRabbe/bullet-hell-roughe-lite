extends Node2D

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
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if wave_continue_button != null:
		wave_continue_button.pressed.connect(_on_wave_continue_pressed)
	if shop_controller != null and shop_controller.has_signal("continue_requested"):
		shop_controller.connect("continue_requested", _on_wave_continue_pressed)
	for index in level_up_choice_buttons.size():
		level_up_choice_buttons[index].pressed.connect(_on_level_up_choice_pressed.bind(index))
	levelup_rng = _resolve_rng("levelup")
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
	waiting_for_restart = true
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	_set_combat_active(false)
	_hide_run_overlays()

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
	_hide_run_overlays()
	_set_gameplay_active(true)
	if character_select_layer != null:
		character_select_layer.visible = false

func _set_gameplay_active(active: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for path in ["Player", "EnemySpawner", "PortalEventManager", "RewardController", "ShopController", "BossManager"]:
		var node := get_node_or_null(path)
		if node != null:
			node.process_mode = mode
	if not active:
		_hide_run_overlays()
	if character_select_layer != null:
		character_select_layer.visible = not active

func _hide_run_overlays() -> void:
	_hide_control_if_present("WaveIntermission/Panel")
	_hide_control_if_present("ShopUI/Panel")
	_hide_control_if_present("LevelUpUI/Panel")

func _hide_control_if_present(path: NodePath) -> void:
	var node := get_node_or_null(path)
	if node is Control:
		(node as Control).visible = false

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
	waiting_for_wave_continue = true
	_set_combat_active(false)
	_clear_combat_entities()
	if _is_shop_enabled():
		_hide_control_if_present("WaveIntermission/Panel")
	else:
		_hide_control_if_present("ShopUI/Panel")
	if wave_panel != null and not _is_shop_enabled():
		wave_panel.visible = true
	print("Wave %d complete. Press Continue to start next wave." % wave_index)

func _on_wave_continue_pressed() -> void:
	if not waiting_for_wave_continue:
		return
	waiting_for_wave_continue = false
	_hide_run_overlays()
	_finish_intermission_or_open_levelup()

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
	var mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for path in ["Player", "EnemySpawner", "PortalEventManager", "RewardController", "BossManager"]:
		var node := get_node_or_null(path)
		if node != null:
			node.process_mode = mode
	_set_group_process_mode("enemies", mode)
	_set_group_process_mode("projectiles", mode)

func _set_group_process_mode(group_name: StringName, mode: int) -> void:
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

func _open_level_up_screen() -> void:
	waiting_for_level_up_choice = true
	_set_combat_active(false)
	_roll_level_up_choices()
	if level_up_title != null:
		level_up_title.text = "Level Up! Pick 1 of 4"
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
