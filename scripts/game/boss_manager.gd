extends Node

const BossManagerRuntime = preload("res://scripts/game/boss_manager_runtime.gd")
const ArenaBoundsRuntime = preload("res://scripts/game/arena_bounds.gd")
const BossPresentationRuntimeRef = preload("res://scripts/ui/boss_presentation_runtime.gd")
const GateBeastPressureRuntimeRef = preload("res://scripts/enemies/gate_beast_pressure_runtime.gd")
const CinderMarshalPressureRuntimeRef = preload("res://scripts/enemies/cinder_marshal_pressure_runtime.gd")
const PyreArchonPressureRuntimeRef = preload("res://scripts/enemies/pyre_archon_pressure_runtime.gd")
const LastShadePressureRuntimeRef = preload("res://scripts/enemies/last_shade_pressure_runtime.gd")

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
var active_boss_id: String = ""
var active_pressure: RefCounted

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
		spawn_boss("gate_beast")

func _unhandled_input(event: InputEvent) -> void:
	if BossManagerRuntime.is_debug_spawn_event(event, boss_spawned, debug_spawn_key):
		spawn_boss("gate_beast")

func spawn_boss(boss_id: String) -> bool:
	if boss_spawned:
		return false
	var definition := BossManagerRuntime.get_boss_definition(boss_id)
	if definition.is_empty():
		push_warning("BossManager rejected unsupported boss id '%s'." % boss_id)
		return false
	return _spawn_configured_boss(definition)

func _spawn_configured_boss(definition: Dictionary) -> bool:
	var boss_id := str(definition.get("id", ""))
	var boss := BossManagerRuntime.instantiate_boss(self, boss_scene, player, boss_id)
	if boss == null:
		return false
	boss.global_position = _clamp_boss_position(boss.global_position)
	active_boss = boss
	active_boss_id = boss_id
	boss_spawned = true
	active_pressure = _create_pressure_runtime(str(definition.get("pressure_id", "")))
	if active_pressure != null and active_pressure.has_method("configure"):
		active_pressure.call("configure", boss)
	boss_spawned_signal.emit()
	BossPresentationRuntimeRef.show_boss_spawn(self, boss_id)
	print("Boss spawned: %s" % str(definition.get("display_name", boss_id)))
	if boss.has_signal("tree_exiting"):
		boss.tree_exiting.connect(_on_boss_exiting.bind(boss))
	return true

func _create_pressure_runtime(pressure_id: String) -> RefCounted:
	match pressure_id:
		"gate_beast":
			return GateBeastPressureRuntimeRef.new()
		"cinder_marshal":
			return CinderMarshalPressureRuntimeRef.new()
		"pyre_archon":
			return PyreArchonPressureRuntimeRef.new()
		"last_shade":
			return LastShadePressureRuntimeRef.new()
		_:
			return null

func _tick_active_boss_pressure(delta: float) -> void:
	if active_boss == null or not is_instance_valid(active_boss):
		return
	if active_pressure != null and active_pressure.has_method("tick"):
		active_pressure.call("tick", delta, active_boss)

func _clamp_boss_position(spawn_position: Vector2) -> Vector2:
	if arena_bounds == null or not is_instance_valid(arena_bounds):
		arena_bounds = ArenaBoundsRuntime.ensure_for_scene(self)
	if arena_bounds == null or not arena_bounds.has_method("clamp_spawn_position"):
		return spawn_position
	var resolved: Variant = arena_bounds.call("clamp_spawn_position", spawn_position, 72.0)
	return resolved if resolved is Vector2 else spawn_position

func _on_boss_exiting(boss: Node2D) -> void:
	var result := BossManagerRuntime.evaluate_boss_exit(active_boss, boss)
	if result.get("matches_active", false) != true:
		return
	if active_pressure != null and active_pressure.has_method("restore"):
		active_pressure.call("restore", boss)
	var defeated_boss_id := active_boss_id
	active_boss = null
	active_boss_id = ""
	active_pressure = null
	if result.get("boss_should_reset_spawn", false) == true:
		boss_spawned = false
		return
	if result.get("boss_defeated", false) == true:
		boss_spawned = false
		call_deferred("_on_boss_defeated", defeated_boss_id)

func _on_boss_defeated(boss_id: String) -> void:
	boss_defeated_signal.emit()
	BossPresentationRuntimeRef.show_boss_defeated(self, boss_id)
	var definition := BossManagerRuntime.get_boss_definition(boss_id)
	print("Boss defeated: %s" % str(definition.get("display_name", boss_id)))

func has_active_boss() -> bool:
	return active_boss != null and is_instance_valid(active_boss)
