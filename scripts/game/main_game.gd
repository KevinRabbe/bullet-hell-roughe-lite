extends Node2D

@onready var player: CharacterBody2D = $Player

func _ready() -> void:
	if player == null:
		push_error("Main scene is missing a Player node.")
