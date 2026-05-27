extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node = $EnemySpawner
@onready var wave_panel: Control = $WaveIntermission/Panel
@onready var wave_continue_button: Button = $WaveIntermission/Panel/ContinueButton
@onready var character_select_layer: CanvasLayer = $CharacterSelect
@onready var character_label: Label = $CharacterSelect/Panel/CharacterLabel
@onready var start_button: Button = $CharacterSelect/Panel/StartButton
@onready var shop_controller: Node = $ShopController
var waiting_for_restart: bool = false
var waiting_for_wave_continue: bool = false
var selectable_characters: Array[String] = ["gunslinger"]
var character_display_names: Dictionary = {"gunslinger": "The Gunslinger"}
var selected_character_index: int = 0
var run_started: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_new_run_seed()
	if player == null:
		push_error("Main scene is missing a Player node.")
		return

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	if wave_continue_button != null:
		wave_continue_button.pressed.connect(_on_wave_continue_pressed)
	if shop_controller != null and shop_controller.has_signal("continue_requested"):
		shop_controller.connect("continue_requested", _on_wave_continue_pressed)
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
	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")
		return

func _on_player_died() -> void:
	waiting_for_restart = true
	waiting_for_wave_continue = false
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

func _is_shop_enabled() -> bool:
	if shop_controller == null:
		return false
	return bool(shop_controller.get("enabled"))
