extends Node

const PublicInputDefaultsRef = preload("res://scripts/input/public_input_defaults.gd")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PublicInputDefaultsRef.ensure()

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() and _is_debug_shortcut(event):
		get_viewport().set_input_as_handled()
		return
	if not event.is_action_pressed("pause_game"):
		return
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_toggle_pause"):
		return
	if get_tree().paused:
		scene.call("_toggle_pause")
		get_viewport().set_input_as_handled()
		return
	if not _can_open_gameplay_pause(scene):
		return
	scene.call("_toggle_pause")
	get_viewport().set_input_as_handled()

func _can_open_gameplay_pause(scene: Node) -> bool:
	if not bool(scene.get("run_started")):
		return false
	if bool(scene.get("waiting_for_restart")):
		return false
	if bool(scene.get("waiting_for_wave_continue")):
		return false
	if bool(scene.get("waiting_for_level_up_choice")):
		return false
	return true

func _is_debug_shortcut(event: InputEvent) -> bool:
	if event.is_action_pressed("debug_grant_item") or event.is_action_pressed("cycle_character"):
		return true
	if not (event is InputEventKey):
		return false
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return false
	return key_event.keycode in [KEY_PLUS, KEY_KP_ADD, KEY_G, KEY_M, KEY_C, KEY_Q]
