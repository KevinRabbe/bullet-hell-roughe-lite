class_name PublicInputDefaults
extends RefCounted

static func ensure() -> void:
	_ensure_action("move_left", 0.22)
	_ensure_action("move_right", 0.22)
	_ensure_action("move_up", 0.22)
	_ensure_action("move_down", 0.22)
	_ensure_action("interact", 0.5)
	_ensure_action("pause_game", 0.5)
	_ensure_action("ui_left", 0.22)
	_ensure_action("ui_right", 0.22)
	_ensure_action("ui_up", 0.22)
	_ensure_action("ui_down", 0.22)
	_ensure_action("ui_accept", 0.5)
	_ensure_action("ui_cancel", 0.5)

	_add_key_if_missing("move_left", KEY_A, true)
	_add_key_if_missing("move_left", KEY_LEFT)
	_add_axis_if_missing("move_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_button_if_missing("move_left", JOY_BUTTON_DPAD_LEFT)

	_add_key_if_missing("move_right", KEY_D, true)
	_add_key_if_missing("move_right", KEY_RIGHT)
	_add_axis_if_missing("move_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button_if_missing("move_right", JOY_BUTTON_DPAD_RIGHT)

	_add_key_if_missing("move_up", KEY_W, true)
	_add_key_if_missing("move_up", KEY_UP)
	_add_axis_if_missing("move_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_button_if_missing("move_up", JOY_BUTTON_DPAD_UP)

	_add_key_if_missing("move_down", KEY_S, true)
	_add_key_if_missing("move_down", KEY_DOWN)
	_add_axis_if_missing("move_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button_if_missing("move_down", JOY_BUTTON_DPAD_DOWN)

	_add_key_if_missing("interact", KEY_E, true)
	_add_joy_button_if_missing("interact", JOY_BUTTON_A)

	_add_key_if_missing("pause_game", KEY_ESCAPE)
	_add_key_if_missing("pause_game", KEY_P, true)
	_add_joy_button_if_missing("pause_game", JOY_BUTTON_START)

	_add_key_if_missing("ui_left", KEY_LEFT)
	_add_axis_if_missing("ui_left", JOY_AXIS_LEFT_X, -1.0)
	_add_joy_button_if_missing("ui_left", JOY_BUTTON_DPAD_LEFT)
	_add_key_if_missing("ui_right", KEY_RIGHT)
	_add_axis_if_missing("ui_right", JOY_AXIS_LEFT_X, 1.0)
	_add_joy_button_if_missing("ui_right", JOY_BUTTON_DPAD_RIGHT)
	_add_key_if_missing("ui_up", KEY_UP)
	_add_axis_if_missing("ui_up", JOY_AXIS_LEFT_Y, -1.0)
	_add_joy_button_if_missing("ui_up", JOY_BUTTON_DPAD_UP)
	_add_key_if_missing("ui_down", KEY_DOWN)
	_add_axis_if_missing("ui_down", JOY_AXIS_LEFT_Y, 1.0)
	_add_joy_button_if_missing("ui_down", JOY_BUTTON_DPAD_DOWN)
	_add_key_if_missing("ui_accept", KEY_ENTER)
	_add_key_if_missing("ui_accept", KEY_SPACE)
	_add_joy_button_if_missing("ui_accept", JOY_BUTTON_A)
	_add_key_if_missing("ui_cancel", KEY_ESCAPE)
	_add_joy_button_if_missing("ui_cancel", JOY_BUTTON_B)

static func _ensure_action(action: StringName, deadzone: float) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action, deadzone)
	else:
		InputMap.action_set_deadzone(action, deadzone)

static func _add_key_if_missing(action: StringName, keycode: int, physical: bool = false) -> void:
	for existing in InputMap.action_get_events(action):
		if not (existing is InputEventKey):
			continue
		var key_event := existing as InputEventKey
		if physical and key_event.physical_keycode == keycode:
			return
		if not physical and key_event.keycode == keycode:
			return
	var event := InputEventKey.new()
	if physical:
		event.physical_keycode = keycode
	else:
		event.keycode = keycode
	InputMap.action_add_event(action, event)

static func _add_axis_if_missing(action: StringName, axis: int, axis_value: float) -> void:
	for existing in InputMap.action_get_events(action):
		if not (existing is InputEventJoypadMotion):
			continue
		var motion := existing as InputEventJoypadMotion
		if motion.axis == axis and is_equal_approx(signf(motion.axis_value), signf(axis_value)):
			return
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = clampf(axis_value, -1.0, 1.0)
	InputMap.action_add_event(action, event)

static func _add_joy_button_if_missing(action: StringName, button_index: int) -> void:
	for existing in InputMap.action_get_events(action):
		if existing is InputEventJoypadButton and (existing as InputEventJoypadButton).button_index == button_index:
			return
	var event := InputEventJoypadButton.new()
	event.button_index = button_index
	InputMap.action_add_event(action, event)
