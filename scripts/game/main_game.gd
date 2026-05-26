extends Node2D

@onready var player: CharacterBody2D = $Player
var waiting_for_restart: bool = false

func _ready() -> void:
	if player == null:
		push_error("Main scene is missing a Player node.")
		return

	if player.has_signal("player_died"):
		player.player_died.connect(_on_player_died)

func _unhandled_input(event: InputEvent) -> void:
	if not waiting_for_restart:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		print("Restarting current scene...")
		get_tree().reload_current_scene()

func _on_player_died() -> void:
	waiting_for_restart = true
