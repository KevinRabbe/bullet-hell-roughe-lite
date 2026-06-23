extends Node2D

signal portal_event_completed

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const PortalEventResolver = preload("res://scripts/portal/portal_event_resolver.gd")
const PortalEventManagerRuntime = preload("res://scripts/portal/portal_event_manager_runtime.gd")
const PortalRunProfile = preload("res://scripts/portal/portal_run_profile.gd")

@export var portal_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var first_portal_position: Vector2 = Vector2(240.0, 0.0)
@export var elite_spawn_distance: float = 180.0
@export var elite_move_speed: float = 240.0
@export var elite_max_hp: float = 80.0
@export var log_portal_spawns: bool = false
@export var log_portal_events: bool = true

var player: Node2D
var enemy_spawner: Node
var active_event_elites: Array[Node] = []
var rng: RandomNumberGenerator
var flood_timer: Timer
var flood_original_spawn_interval: float = 1.2
var flood_original_max_alive: int = 25

func _ready() -> void:
	rng = _resolve_rng("portal")
	player = PortalEventManagerRuntime.resolve_player(self, player_path)
	enemy_spawner = PortalEventManagerRuntime.resolve_enemy_spawner(self, enemy_spawner_path)
	if enemy_spawner != null and enemy_spawner.has_signal("wave_completed"):
		enemy_spawner.connect("wave_completed", _on_wave_completed)
	flood_timer = Timer.new()
	flood_timer.one_shot = true
	flood_timer.timeout.connect(_on_flood_event_finished)
	add_child(flood_timer)
	_try_spawn_portal_for_wave(1)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_try_activate_nearest_portal()

func _spawn_first_portal() -> void:
	if _active_portal_count() >= 1:
		return
	PortalEventManagerRuntime.instantiate_portal(
		self,
		portal_scene,
		first_portal_position,
		Callable(self, "_on_portal_activated")
	)

func _on_wave_completed(wave_index: int) -> void:
	_try_spawn_portal_for_wave(wave_index + 1)

func _try_spawn_portal_for_wave(wave_index: int) -> void:
	if _active_portal_count() >= 1:
		if log_portal_spawns:
			print("Portal spawn skipped for wave %d: active portal already exists." % wave_index)
		return
	var chance := _compute_portal_spawn_chance()
	var roll := rng.randf()
	if log_portal_spawns:
		print("Portal spawn roll | wave=%d chance=%.2f roll=%.2f" % [wave_index, chance, roll])
	if roll <= chance:
		_spawn_first_portal()

func _compute_portal_spawn_chance() -> float:
	return _build_portal_profile().compute_spawn_chance()

func _active_portal_count() -> int:
	return PortalEventManagerRuntime.count_active_portals(get_tree())

func _try_activate_nearest_portal() -> void:
	var nearest_portal := PortalEventManagerRuntime.find_nearest_portal(get_tree(), player)
	if nearest_portal != null and nearest_portal.has_method("try_activate"):
		nearest_portal.call("try_activate", player)

func _on_portal_activated(portal_position: Vector2) -> void:
	var event_id := _pick_portal_event_id()
	if log_portal_events:
		print("Portal activated. Event: %s" % event_id)
	match event_id:
		"double_elite":
			_start_double_elite_event(portal_position)
		"power_for_hp_loss":
			_start_power_for_hp_loss_event()
		"enemy_flood_20s":
			_start_enemy_flood_event()

func _start_double_elite_event(portal_position: Vector2) -> void:
	if log_portal_events:
		print("Portal event started: Double Elite")
	active_event_elites.clear()
	_track_event_elite(_spawn_elite(portal_position + Vector2.LEFT * elite_spawn_distance))
	_track_event_elite(_spawn_elite(portal_position + Vector2.RIGHT * elite_spawn_distance))
	if active_event_elites.is_empty():
		if log_portal_events:
			print("Portal event completed: no active elites.")
		portal_event_completed.emit()

func _start_power_for_hp_loss_event() -> void:
	if log_portal_events:
		print("Portal event started: Power for Max HP loss")
	var result := PortalEventManagerRuntime.apply_power_for_hp_loss(player)
	if log_portal_events and result.get("applied", false) == true:
		print("Power trade applied: +0.35 damage, -20 max HP")
	if log_portal_events:
		print("Portal event completed: Power for Max HP loss")
	portal_event_completed.emit()

func _start_enemy_flood_event() -> void:
	if log_portal_events:
		print("Portal event started: 20-second enemy flood")
	var result := PortalEventManagerRuntime.apply_enemy_flood(enemy_spawner)
	if result.get("applied", false) == true:
		flood_original_spawn_interval = float(result.get("original_spawn_interval", flood_original_spawn_interval))
		flood_original_max_alive = int(result.get("original_max_alive", flood_original_max_alive))
	flood_timer.start(20.0)

func _on_flood_event_finished() -> void:
	PortalEventManagerRuntime.restore_enemy_flood(
		enemy_spawner,
		flood_original_spawn_interval,
		flood_original_max_alive
	)
	if log_portal_events:
		print("Portal event completed: enemy flood survived.")
	portal_event_completed.emit()

func _spawn_elite(spawn_position: Vector2) -> Node:
	var elite_role := _pick_elite_role()
	var enemy_node := PortalEventManagerRuntime.spawn_elite(
		self,
		elite_enemy_scene,
		player,
		spawn_position,
		elite_move_speed,
		elite_max_hp,
		elite_role
	)
	if enemy_node != null and log_portal_events:
		print("Spawned elite variant: %s" % elite_role)
	return enemy_node

func _track_event_elite(enemy: Node) -> void:
	PortalEventManagerRuntime.track_event_elite(
		active_event_elites,
		enemy,
		Callable(self, "_on_event_elite_exited")
	)

func _on_event_elite_exited(enemy: Node) -> void:
	active_event_elites.erase(enemy)
	if log_portal_events:
		print("Portal elite defeated. Remaining elites: %d" % active_event_elites.size())
	if active_event_elites.is_empty():
		if log_portal_events:
			print("Portal event completed: all elites defeated.")
		portal_event_completed.emit()

func _pick_portal_event_id() -> String:
	return PortalEventResolver.pick_event_id(rng, _build_portal_profile())

func _pick_elite_role() -> String:
	return PortalEventManagerRuntime.pick_elite_role(rng)

func _build_portal_profile() -> PortalRunProfile:
	return PortalRunProfile.from_player(player)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "PortalEventManager")
