class_name MainGameIntermissionExitRuntime
extends RefCounted

const IntermissionRuntime = preload("res://scripts/game/intermission_runtime.gd")

static func exit_intermission(main_game: Node) -> void:
	main_game.set("waiting_for_wave_continue", false)
	IntermissionRuntime.end_intermission(main_game)

static func start_next_wave_after_intermission(main_game: Node, enemy_spawner: Node) -> void:
	IntermissionRuntime.start_next_wave(main_game, enemy_spawner)
	main_game.set("run_end_state", "inactive")
