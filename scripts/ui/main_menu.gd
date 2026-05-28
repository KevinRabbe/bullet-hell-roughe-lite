extends Control

@onready var options_panel = $OptionsPanel
@onready var credits_panel = $CreditsPanel

func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/game/Main.tscn")

func _on_options_button_pressed() -> void:
	options_panel.visible = not options_panel.visible
	credits_panel.visible = false

func _on_credits_button_pressed() -> void:
	credits_panel.visible = not credits_panel.visible
	options_panel.visible = false

func _on_quit_button_pressed() -> void:
	get_tree().quit()
