extends Node

@export var boss_scene: PackedScene
@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var spawn_after_seconds: float = 45.0
@export var debug_spawn_key: Key = KEY_B
@export var boss_wave_index: int = 10
@export var spawn_on_wave: bool = true
@export var grant_bonus_on_defeat: bool = true
@export var boss_kill_gold_bonus: int = 20
@export var boss_kill_xp_bonus: int = 30

var player: Node2D
var enemy_spawner: Node
var boss_spawned: bool = false
var elapsed_seconds: float = 0.0
var boss_defeated_this_run: bool = false

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path)
	if enemy_spawner_path != NodePath():
		enemy_spawner = get_node_or_null(enemy_spawner_path)

func _process(delta: float) -> void:
	if boss_spawned or boss_defeated_this_run:
		return
	if spawn_on_wave and _is_wave_boss_due():
		_spawn_gate_beast()
		return
	elapsed_seconds += delta
	if not spawn_on_wave and elapsed_seconds >= spawn_after_seconds:
		_spawn_gate_beast()

func _unhandled_input(event: InputEvent) -> void:
	if boss_spawned:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == debug_spawn_key:
		_spawn_gate_beast()

func _spawn_gate_beast() -> void:
	if boss_scene == null:
		return
	if player == null or not is_instance_valid(player):
		return
	var boss_instance := boss_scene.instantiate()
	if not (boss_instance is Node2D):
		return
	var boss := boss_instance as Node2D
	boss.global_position = player.global_position + Vector2(260.0, -40.0)
	boss.set("is_boss", true)
	boss.set("move_speed", 150.0)
	boss.set("max_hp", 320.0)
	boss.set("current_hp", 320.0)
	boss.set("contact_damage", 22.0)
	boss.set("contact_range", 70.0)
	boss.set("damage_interval_seconds", 0.7)
	if boss.has_method("set_target"):
		boss.call("set_target", player)
	get_tree().current_scene.add_child(boss)
	boss_spawned = true
	print("Boss spawned: Gate Beast")
	if boss.has_signal("tree_exited"):
		boss.tree_exited.connect(_on_gate_beast_defeated)

func _on_gate_beast_defeated() -> void:
	boss_spawned = false
	boss_defeated_this_run = true
	if grant_bonus_on_defeat and player != null:
		if boss_kill_gold_bonus > 0 and player.has_method("add_gold"):
			player.call("add_gold", boss_kill_gold_bonus)
		if boss_kill_xp_bonus > 0 and player.has_method("add_xp"):
			player.call("add_xp", boss_kill_xp_bonus)
	print("Boss defeated: Gate Beast")

func _is_wave_boss_due() -> bool:
	if enemy_spawner == null:
		return false
	var wave_index := int(enemy_spawner.get("current_wave_index"))
	if wave_index < boss_wave_index:
		return false
	var elapsed := float(enemy_spawner.get("wave_elapsed_seconds"))
	return elapsed <= 0.8
