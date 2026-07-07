extends Control

const CHARACTER_SELECT_SCENE_PATH := "res://scenes/ui/CharacterSelect.tscn"

const OPTIONS_COPY := "Options stay lightweight for now while we finish the front-door flow. Start Run now goes through Character Select and Starting Weapon Select before entering combat."
const CREDITS_COPY := "Built in Godot as a Brotato-inspired bullet-hell roguelite prototype. Current focus: stronger character identity, cleaner run start flow, and a more scalable build system."

@onready var start_button: Button = $RootMargin/MainHBox/HeroColumn/ActionPanel/ActionMargin/ActionVBox/StartButton
@onready var modal_scrim: ColorRect = $ModalScrim
@onready var dialog_panel: PanelContainer = $DialogPanel
@onready var dialog_title: Label = $DialogPanel/DialogMargin/DialogVBox/DialogTitle
@onready var dialog_body: Label = $DialogPanel/DialogMargin/DialogVBox/DialogBody
@onready var dialog_close_button: Button = $DialogPanel/DialogMargin/DialogVBox/DialogCloseButton

func _ready() -> void:
	_hide_dialog()
	if start_button != null:
		start_button.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	if key_event.keycode == KEY_ESCAPE and dialog_panel.visible:
		_hide_dialog()

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file(CHARACTER_SELECT_SCENE_PATH)

func _on_options_button_pressed() -> void:
	_show_dialog("Options", OPTIONS_COPY)

func _on_credits_button_pressed() -> void:
	_show_dialog("Credits", CREDITS_COPY)

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _show_dialog(title: String, body: String) -> void:
	dialog_title.text = title
	dialog_body.text = body
	modal_scrim.visible = true
	dialog_panel.visible = true
	if dialog_close_button != null:
		dialog_close_button.grab_focus()

func _hide_dialog() -> void:
	modal_scrim.visible = false
	dialog_panel.visible = false
	if start_button != null:
		start_button.grab_focus()
