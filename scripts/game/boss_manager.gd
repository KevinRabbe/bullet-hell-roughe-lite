extends Node

signal boss_spawned_signal
signal boss_defeated_signal

@export var boss_scene: PackedScene
@export var player_path: NodePath
@export var spawn_after_seconds: float = 45.0
@export var debug_spawn_key: Key = KEY_B

var player: Node2D
var boss_spawned: bool = false
var elapsed_seconds: float = 0.0
var active_boss: Node2D

func _ready() -> void:
	if player_path != NodePath():
		player = get_node_or_null(player_path)

func _process(delta: float) -> void:
	if boss_spawned:
		return
	elapsed_seconds += delta
	if elapsed_seconds >= spawn_after_seconds:
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
	active_boss = boss
	boss_spawned = true
	boss_spawned_signal.emit()
	print("Boss spawned: Gate Beast")
	if boss.has_signal("tree_exiting"):
		boss.tree_exiting.connect(_on_gate_beast_exiting.bind(boss))

func _on_gate_beast_exiting(boss: Node2D) -> void:
	if boss != active_boss:
		return
	active_boss = null
	if boss == null or not is_instance_valid(boss):
		return
	if float(boss.get("current_hp")) > 0.0:
		boss_spawned = false
		return
	_on_gate_beast_defeated()

func _on_gate_beast_defeated() -> void:
	boss_defeated_signal.emit()
	print("Boss defeated: Gate Beast")
