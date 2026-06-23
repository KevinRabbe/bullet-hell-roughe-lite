extends Node

const BossManagerRuntime = preload("res://scripts/game/boss_manager_runtime.gd")

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
	player = BossManagerRuntime.resolve_player(self, player_path)

func _process(delta: float) -> void:
	elapsed_seconds += delta
	if BossManagerRuntime.should_auto_spawn(boss_spawned, elapsed_seconds, spawn_after_seconds):
		_spawn_gate_beast()

func _unhandled_input(event: InputEvent) -> void:
	if BossManagerRuntime.is_debug_spawn_event(event, boss_spawned, debug_spawn_key):
		_spawn_gate_beast()

func _spawn_gate_beast() -> void:
	var boss := BossManagerRuntime.instantiate_boss(self, boss_scene, player)
	if boss == null:
		return
	active_boss = boss
	boss_spawned = true
	boss_spawned_signal.emit()
	print("Boss spawned: Gate Beast")
	if boss.has_signal("tree_exiting"):
		boss.tree_exiting.connect(_on_gate_beast_exiting.bind(boss))

func _on_gate_beast_exiting(boss: Node2D) -> void:
	var result := BossManagerRuntime.evaluate_boss_exit(active_boss, boss)
	if result.get("matches_active", false) != true:
		return
	active_boss = null
	if result.get("boss_should_reset_spawn", false) == true:
		boss_spawned = false
		return
	if result.get("boss_defeated", false) == true:
		_on_gate_beast_defeated()

func _on_gate_beast_defeated() -> void:
	boss_defeated_signal.emit()
	print("Boss defeated: Gate Beast")
