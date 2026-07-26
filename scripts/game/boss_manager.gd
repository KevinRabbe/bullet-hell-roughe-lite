extends Node

const BossManagerRuntime = preload("res://scripts/game/boss_manager_runtime.gd")
const ArenaBoundsRuntime = preload("res://scripts/game/arena_bounds.gd")
const BossPresentationRuntimeRef = preload("res://scripts/ui/boss_presentation_runtime.gd")
const GateBeastPressureRuntimeRef = preload("res://scripts/enemies/gate_beast_pressure_runtime.gd")

signal boss_spawned_signal
signal boss_defeated_signal

@export var boss_scene: PackedScene
@export var player_path: NodePath
@export var arena_bounds_path: NodePath
@export var auto_spawn_enabled: bool = false
@export var spawn_after_seconds: float = 45.0
@export var debug_spawn_key: Key = KEY_B

var player: Node2D
var arena_bounds: Node
var boss_spawned: bool = false
var elapsed_seconds: float = 0.0
var active_boss: Node2D
var gate_beast_pressure: RefCounted = GateBeastPressureRuntimeRef.new()

func _ready() -> void:
	player = BossManagerRuntime.resolve_player(self, player_path)
	if arena_bounds_path != NodePath():
		arena_bounds = get_node_or_null(arena_bounds_path)
	if arena_bounds == null:
		arena_bounds = ArenaBoundsRuntime.ensure_for_scene(self)

func _process(delta: float) -> void:
	_tick_active_boss_pressure(delta)
	if not auto_spawn_enabled:
		return
	elapsed_seconds += delta
	if BossManagerRuntime.should_auto_spawn(boss_spawned, elapsed_seconds, spawn_after_seconds):
		_spawn_gate_beast()

func _unhandled_input(event: InputEvent) -> void:
	if BossManagerRuntime.is_debug_spawn_event(event, boss_spawned, debug_spawn_key):
		_spawn_gate_beast()

func spawn_boss(boss_id: String) -> bool:
	if boss_id != "gate_beast" or boss_spawned:
		return false
	return _spawn_gate_beast()

func _spawn_gate_beast() -> bool:
	var boss := BossManagerRuntime.instantiate_boss(self, boss_scene, player)
	if boss == null:
		return false
	boss.global_position = _clamp_boss_position(boss.global_position)
	active_boss = boss
	boss_spawned = true
	if gate_beast_pressure != null and gate_beast_pressure.has_method("configure"):
		gate_beast_pressure.call("configure", boss)
	boss_spawned_signal.emit()
	BossPresentationRuntimeRef.show_gate_beast_spawn(self)
	print("Boss spawned: Gate Beast")
	if boss.has_signal("tree_exiting"):
		boss.tree_exiting.connect(_on_gate_beast_exiting.bind(boss))
	return true

func _tick_active_boss_pressure(delta: float) -> void:
	if active_boss == null or not is_instance_valid(active_boss):
		return
	if gate_beast_pressure != null and gate_beast_pressure.has_method("tick"):
		gate_beast_pressure.call("tick", delta, active_boss)

func _clamp_boss_position(spawn_position: Vector2) -> Vector2:
	if arena_bounds == null or not is_instance_valid(arena_bounds):
		arena_bounds = ArenaBoundsRuntime.ensure_for_scene(self)
	if arena_bounds == null or not arena_bounds.has_method("clamp_spawn_position"):
		return spawn_position
	var resolved: Variant = arena_bounds.call("clamp_spawn_position", spawn_position, 72.0)
	return resolved if resolved is Vector2 else spawn_position

func _on_gate_beast_exiting(boss: Node2D) -> void:
	var result := BossManagerRuntime.evaluate_boss_exit(active_boss, boss)
	if result.get("matches_active", false) != true:
		return
	if gate_beast_pressure != null and gate_beast_pressure.has_method("restore"):
		gate_beast_pressure.call("restore", boss)
	active_boss = null
	if result.get("boss_should_reset_spawn", false) == true:
		boss_spawned = false
		return
	if result.get("boss_defeated", false) == true:
		_on_gate_beast_defeated()

func _on_gate_beast_defeated() -> void:
	boss_defeated_signal.emit()
	BossPresentationRuntimeRef.show_gate_beast_defeated(self)
	print("Boss defeated: Gate Beast")

func has_active_boss() -> bool:
	return active_boss != null and is_instance_valid(active_boss)
