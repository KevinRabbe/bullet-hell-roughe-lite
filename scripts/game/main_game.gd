extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var enemy_spawner: Node = $EnemySpawner
@onready var wave_overlay: CanvasLayer = $WaveIntermission
@onready var wave_label: Label = $WaveIntermission/Panel/Label
@onready var continue_button: Button = $WaveIntermission/Panel/ContinueButton
var waiting_for_restart: bool = false
var waiting_for_wave_continue: bool = false
var selectable_characters: Array[String] = ["gunslinger", "riftwalker"]
var selected_character_index: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player == null:
		push_error("Main scene is missing a Player node.")
		return

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)
	_apply_selected_character()
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)
	if continue_button != null:
		continue_button.pressed.connect(_on_continue_pressed)
	if wave_overlay != null:
		wave_overlay.visible = false

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
	if waiting_for_wave_continue and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
		_on_continue_pressed()
		return

	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")
		return

	if event.is_action_pressed("cycle_character") or key_event.keycode == KEY_C:
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

func _on_wave_completed(wave_index: int) -> void:
	waiting_for_wave_continue = true
	if wave_overlay != null:
		wave_overlay.visible = true
	if wave_label != null:
		wave_label.text = "Wave %d complete. Reward/Shop placeholder.\nPress Continue to start next wave." % wave_index
	print("Entered end-of-wave state for wave %d." % wave_index)

func _on_continue_pressed() -> void:
	if not waiting_for_wave_continue:
		return
	waiting_for_wave_continue = false
	if wave_overlay != null:
		wave_overlay.visible = false
	if enemy_spawner != null and enemy_spawner.has_method("start_next_wave"):
		enemy_spawner.call("start_next_wave")
