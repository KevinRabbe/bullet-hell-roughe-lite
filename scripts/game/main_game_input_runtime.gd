class_name MainGameInputRuntime
extends RefCounted

static func resolve_input_action(
	event: InputEvent,
	run_started: bool,
	waiting_for_restart: bool,
	waiting_for_wave_continue: bool,
	waiting_for_level_up_choice: bool
) -> String:
	if not (event is InputEventKey):
		return ""
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return ""
	if key_event.keycode == KEY_PLUS or key_event.keycode == KEY_KP_ADD:
		return "cycle_debug_preset"
	if not run_started:
		if is_character_cycle_input(event, key_event):
			return "cycle_character"
		if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
			return "start_run"
		return ""
	if waiting_for_restart and key_event.keycode == KEY_R:
		return "restart_run"
	if waiting_for_wave_continue and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE):
		return "continue_wave"
	if waiting_for_level_up_choice:
		return "blocked"
	if key_event.keycode == KEY_ESCAPE or key_event.keycode == KEY_P:
		return "toggle_pause"
	if key_event.keycode == KEY_Q:
		return "debug_quit"
	return ""

static func is_character_cycle_input(event: InputEvent, key_event: InputEventKey) -> bool:
	return event.is_action_pressed("cycle_character") or key_event.keycode == KEY_C
