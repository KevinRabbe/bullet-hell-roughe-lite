extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node = $EnemySpawner
@onready var character_select_layer: CanvasLayer = $CharacterSelect
@onready var character_label: Label = $CharacterSelect/Panel/CharacterLabel
@onready var start_button: Button = $CharacterSelect/Panel/StartButton
var waiting_for_restart: bool = false
var selectable_characters: Array[String] = ["gunslinger"]
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
	if start_button != null:
		start_button.pressed.connect(_on_start_pressed)
	_load_selectable_characters()
	_update_character_debug_label()
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
	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")
		return

func _on_player_died() -> void:
	waiting_for_restart = true

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
	_apply_selected_character()

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
	_set_gameplay_active(true)
	if character_select_layer != null:
		character_select_layer.visible = false

func _set_gameplay_active(active: bool) -> void:
	var mode := Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	for path in ["Player", "EnemySpawner", "PortalEventManager", "RewardController", "ShopController", "BossManager"]:
		var node := get_node_or_null(path)
		if node != null:
			node.process_mode = mode
	if character_select_layer != null:
		character_select_layer.visible = not active

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

func _update_character_debug_label() -> void:
	if character_label == null or selectable_characters.is_empty():
		return
	character_label.text = "Selected: %s (C to cycle, Enter to start)" % selectable_characters[selected_character_index]
