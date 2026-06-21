class_name MainGameReadyRuntime
extends RefCounted

static func connect_runtime_signals(
	main_game: Node,
	player: Node,
	enemy_spawner: Node,
	boss_manager: Node,
	start_button: Button,
	wave_continue_button: Button,
	shop_controller: Node,
	level_up_choice_buttons: Array[Button],
	level_up_reroll_button: Button,
	run_end_restart_button: Button,
	run_end_menu_button: Button
) -> void:
	if player != null:
		if player.has_signal("player_died"):
			player.player_died.connect(main_game._on_player_died)
		if player.has_signal("level_up_pending_changed"):
			player.level_up_pending_changed.connect(main_game._on_level_up_pending_changed)
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", main_game._on_wave_completed)
	if boss_manager != null and boss_manager.has_signal("boss_defeated_signal"):
		boss_manager.connect("boss_defeated_signal", main_game._on_boss_defeated)
	if start_button != null:
		start_button.pressed.connect(main_game._on_start_pressed)
	if wave_continue_button != null:
		wave_continue_button.pressed.connect(main_game._on_wave_continue_pressed)
	if shop_controller != null and shop_controller.has_signal("continue_requested"):
		shop_controller.connect("continue_requested", main_game._on_wave_continue_pressed)
	for index in level_up_choice_buttons.size():
		level_up_choice_buttons[index].pressed.connect(main_game._on_level_up_choice_pressed.bind(index))
	if level_up_reroll_button != null:
		level_up_reroll_button.pressed.connect(main_game._on_level_up_reroll_pressed)
	if run_end_restart_button != null:
		run_end_restart_button.pressed.connect(main_game._restart_run)
	if run_end_menu_button != null:
		run_end_menu_button.pressed.connect(main_game._return_to_main_menu)

static func configure_initial_wave_duration(main_game: Node, enemy_spawner: Node) -> float:
	if enemy_spawner == null:
		return float(main_game.get("default_wave_duration_seconds"))
	var default_wave_duration_seconds := float(enemy_spawner.get("wave_duration_seconds"))
	main_game.set("default_wave_duration_seconds", default_wave_duration_seconds)
	main_game.call("_apply_debug_wave_duration")
	return default_wave_duration_seconds
