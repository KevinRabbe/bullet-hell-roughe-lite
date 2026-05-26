extends Node2D

@onready var player: CharacterBody2D = $Player
var waiting_for_restart: bool = false
var selectable_characters: Array[String] = ["gunslinger"]
var selected_character_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player == null:
		push_error("Main scene is missing a Player node.")
		return

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	_apply_selected_character()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if waiting_for_restart and key_event.keycode == KEY_R:
		print("Restarting current scene...")
		get_tree().reload_current_scene()
		return

	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")
		return

	if event.is_action_pressed("cycle_character"):
		_cycle_character()

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
