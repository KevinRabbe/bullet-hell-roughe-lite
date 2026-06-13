extends RefCounted

var waiting_for_restart: bool = false
var waiting_for_wave_continue: bool = false
var waiting_for_level_up_choice: bool = false
var run_end_state: String = "inactive"

func reset() -> void:
	waiting_for_restart = false
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	run_end_state = "inactive"

func enter_intermission() -> void:
	waiting_for_wave_continue = true
	waiting_for_level_up_choice = false

func exit_intermission() -> void:
	waiting_for_wave_continue = false

func open_level_up() -> void:
	waiting_for_level_up_choice = true

func close_level_up() -> void:
	waiting_for_level_up_choice = false

func clear_run_end() -> void:
	waiting_for_restart = false
	run_end_state = "inactive"

func enter_run_end(state: String) -> bool:
	if run_end_state == state:
		return false
	run_end_state = state
	waiting_for_restart = state == "game_over" or state == "victory"
	waiting_for_wave_continue = false
	waiting_for_level_up_choice = false
	return true
