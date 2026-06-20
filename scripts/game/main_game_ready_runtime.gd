class_name MainGameReadyRuntime
extends RefCounted

static func connect_scene_signals(
	player: Node,
	enemy_spawner: Node,
	boss_manager: Node,
	shop_controller: Node,
	start_button: Button,
	wave_continue_button: Button,
	level_up_choice_buttons: Array[Button],
	level_up_reroll_button: Button,
	run_end_restart_button: Button,
	run_end_menu_button: Button,
	on_player_died: Callable,
	on_level_up_pending_changed: Callable,
	on_wave_completed: Callable,
	on_boss_defeated: Callable,
	on_start_pressed: Callable,
	on_wave_continue_pressed: Callable,
	on_level_up_choice_pressed: Callable,
	on_level_up_reroll_pressed: Callable,
	on_restart_run: Callable,
	on_return_to_main_menu: Callable
) -> void:
	if player != null and player.has_signal("player_died"):
		player.player_died.connect(on_player_died)
	if player != null and player.has_signal("level_up_pending_changed"):
		player.level_up_pending_changed.connect(on_level_up_pending_changed)
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", on_wave_completed)
	if boss_manager != null and boss_manager.has_signal("boss_defeated_signal"):
		boss_manager.connect("boss_defeated_signal", on_boss_defeated)
	if start_button != null:
		start_button.pressed.connect(on_start_pressed)
	if wave_continue_button != null:
		wave_continue_button.pressed.connect(on_wave_continue_pressed)
	if shop_controller != null and shop_controller.has_signal("continue_requested"):
		shop_controller.connect("continue_requested", on_wave_continue_pressed)
	for index in level_up_choice_buttons.size():
		level_up_choice_buttons[index].pressed.connect(on_level_up_choice_pressed.bind(index))
	if level_up_reroll_button != null:
		level_up_reroll_button.pressed.connect(on_level_up_reroll_pressed)
	if run_end_restart_button != null:
		run_end_restart_button.pressed.connect(on_restart_run)
	if run_end_menu_button != null:
		run_end_menu_button.pressed.connect(on_return_to_main_menu)
