extends Node

const PublicInputDefaultsRef = preload("res://scripts/input/public_input_defaults.gd")

const GAMEPLAY_FOCUS_CANDIDATES: Array[NodePath] = [
	NodePath("ShopUI/Panel/Offer1"),
	NodePath("ShopUI/Panel/Offer2"),
	NodePath("ShopUI/Panel/Offer3"),
	NodePath("ShopUI/Panel/Offer4"),
	NodePath("ShopUI/Panel/RerollButton"),
	NodePath("ShopUI/Panel/ContinueButton"),
	NodePath("LevelUpUI/Panel/Choice1"),
	NodePath("LevelUpUI/Panel/Choice2"),
	NodePath("LevelUpUI/Panel/Choice3"),
	NodePath("LevelUpUI/Panel/Choice4"),
	NodePath("LevelUpUI/Panel/RerollButton"),
	NodePath("WaveIntermission/Panel/ContinueButton")
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	PublicInputDefaultsRef.ensure()

func _process(_delta: float) -> void:
	_restore_gameplay_focus_if_needed()

func _input(event: InputEvent) -> void:
	if not OS.is_debug_build() and _is_debug_shortcut(event):
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and _route_front_door_cancel():
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

func _route_front_door_cancel() -> bool:
	if get_tree() == null:
		return false
	var scene := get_tree().current_scene
	if scene == null or not scene.has_method("_on_back_pressed"):
		return false
	scene.call("_on_back_pressed")
	return true

func _restore_gameplay_focus_if_needed() -> void:
	var viewport := get_viewport()
	if viewport == null:
		return
	var focus_owner := viewport.gui_get_focus_owner()
	if focus_owner != null and is_instance_valid(focus_owner) and focus_owner.is_visible_in_tree():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	for path in GAMEPLAY_FOCUS_CANDIDATES:
		var button := scene.get_node_or_null(path) as Button
		if button == null or not button.is_visible_in_tree() or button.disabled:
			continue
		button.grab_focus()
		return

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
