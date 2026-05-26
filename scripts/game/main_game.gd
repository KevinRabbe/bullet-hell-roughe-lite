extends Node2D

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	# Keep input handling active while the scene tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	if player == null:
		push_error("Main scene is missing a Player node.")

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		_toggle_pause()
		return

	# Optional debug placeholder for a future quit-to-menu flow.
	if key_event.keycode == KEY_Q:
		print("DEBUG QUIT PLACEHOLDER: no menu scene wired yet.")

func _toggle_pause() -> void:
	var should_pause := not get_tree().paused
	get_tree().paused = should_pause
	if should_pause:
		print("GAME PAUSED")
	else:
		print("GAME RESUMED")
