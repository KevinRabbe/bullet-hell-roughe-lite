extends Node2D

signal portal_event_completed(result: Dictionary)

const DeterministicRng = preload("res://scripts/core/deterministic_rng.gd")
const PortalEventResolver = preload("res://scripts/portal/portal_event_resolver.gd")
const PortalEventManagerRuntime = preload("res://scripts/portal/portal_event_manager_runtime.gd")
const PortalRiskRewardRuntime = preload("res://scripts/portal/portal_risk_reward_runtime.gd")
const PortalMutationOfferScene = preload("res://scenes/ui/PortalMutationOffer.tscn")
const PortalEventPresentationRuntimeRef = preload("res://scripts/ui/portal_event_presentation_runtime.gd")

@export var portal_scene: PackedScene
@export var elite_enemy_scene: PackedScene
@export var player_path: NodePath
@export var enemy_spawner_path: NodePath
@export var first_portal_position: Vector2 = Vector2(240.0, 0.0)
@export var elite_spawn_distance: float = 180.0
@export var elite_move_speed: float = 240.0
@export var elite_max_hp: float = 80.0
@export var log_portal_spawns: bool = false
@export var log_portal_events: bool = false

var player: Node2D
var enemy_spawner: Node
var active_event_elites: Array[Node] = []
var rng: RandomNumberGenerator
var flood_timer: Timer
var flood_original_spawn_interval: float = 1.2
var flood_original_max_alive: int = 25
var active_event_result: Dictionary = {}
var speed_pressure_active: bool = false
var speed_pressure_original_multiplier: float = 1.0
var speed_pressure_reward_result: Dictionary = {}
var active_mutation_offer: Node
var active_mutation_event_result: Dictionary = {}
var previous_tree_paused: bool = false
var debug_forced_event_id: String = ""

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

func configure_debug_capture_event(event_id: String) -> void:
	debug_forced_event_id = event_id.strip_edges()
	if debug_forced_event_id != "":
		_spawn_first_portal()

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
	if speed_pressure_active:
		_finish_enemy_speed_pressure_event()
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
	return PortalRiskRewardRuntime.build_profile(player).compute_spawn_chance()

func _active_portal_count() -> int:
	return PortalEventManagerRuntime.count_active_portals(get_tree())

func _try_activate_nearest_portal() -> void:
	var nearest_portal := PortalEventManagerRuntime.find_nearest_portal(get_tree(), player)
	if nearest_portal != null and nearest_portal.has_method("try_activate"):
		nearest_portal.call("try_activate", player)

func _on_portal_activated(portal_position: Vector2) -> void:
	var event_result := _resolve_portal_event_result()
	var event_id := str(event_result.get("event_id", "double_elite"))
	if log_portal_events:
		print("Portal activated. Event: %s" % event_id)
	var event_data_variant: Variant = event_result.get("event_data", {})
	var event_data: Dictionary = event_data_variant if event_data_variant is Dictionary else {}
	var mutation_id := str(event_data.get("mutation_id", ""))
	if mutation_id != "":
		_start_portal_mutation_offer(event_result, mutation_id)
		return
	PortalEventPresentationRuntimeRef.show_event_started(self, event_result)
	match event_id:
		"double_elite":
			_start_double_elite_event(portal_position, event_result)
		"power_for_hp_loss":
			_start_power_for_hp_loss_event(event_result)
		"attack_speed_for_damage_loss":
			_start_attack_speed_for_damage_loss_event(event_result)
		"enemy_flood_20s":
			_start_enemy_flood_event(event_result)
		"triple_reward_for_enemy_speed":
			_start_triple_reward_for_enemy_speed_event(event_result)

func _start_portal_mutation_offer(event_result: Dictionary, mutation_id: String) -> void:
	if active_mutation_offer != null and is_instance_valid(active_mutation_offer):
		return
	var registry := get_node_or_null("/root/DataRegistry")
	if registry == null or not registry.has_method("get_portal_mutation"):
		_emit_portal_event_completed(event_result.merged({"applied": false, "reason": "mutation_registry_unavailable"}, true))
		return
	var mutation_variant: Variant = registry.call("get_portal_mutation", mutation_id)
	if not (mutation_variant is Dictionary):
		_emit_portal_event_completed(event_result.merged({"applied": false, "reason": "mutation_not_found"}, true))
		return
	var mutation: Dictionary = (mutation_variant as Dictionary).duplicate(true)
	var active_major := _get_active_major_mutation()
	var replaces_active_major := (
		str(mutation.get("mutation_tier", "")) == "major"
		and str(active_major.get("id", "")) != ""
		and str(active_major.get("id", "")) != str(mutation.get("id", ""))
	)
	if replaces_active_major:
		mutation["replacement_warning"] = "Replaces active major mutation: %s." % str(
			active_major.get("title", active_major.get("id", "Unknown"))
		)
	active_mutation_event_result = event_result.duplicate(true)
	active_mutation_offer = PortalMutationOfferScene.instantiate()
	add_child(active_mutation_offer)
	active_mutation_offer.call("configure", mutation)
	active_mutation_offer.connect("accepted", _on_portal_mutation_accepted.bind(mutation, replaces_active_major))
	active_mutation_offer.connect("declined", _on_portal_mutation_declined)
	previous_tree_paused = get_tree().paused
	get_tree().paused = true

func _on_portal_mutation_accepted(mutation: Dictionary, allow_major_replacement: bool) -> void:
	var result := {"applied": false, "reason": "player_unavailable"}
	if player != null and is_instance_valid(player) and player.has_method("apply_portal_mutation"):
		var result_variant: Variant = player.call(
			"apply_portal_mutation",
			mutation,
			allow_major_replacement
		)
		if result_variant is Dictionary:
			result = result_variant
	var payload := active_mutation_event_result.merged(result, true)
	payload["mutation_id"] = str(mutation.get("id", ""))
	payload["mutation_accepted"] = true
	_finish_portal_mutation_offer()
	_emit_portal_event_completed(payload)

func _get_active_major_mutation() -> Dictionary:
	if player == null or not is_instance_valid(player) or not player.has_method("get_portal_mutation_state"):
		return {}
	var state_variant: Variant = player.call("get_portal_mutation_state")
	if not (state_variant is Dictionary):
		return {}
	var major_variant: Variant = (state_variant as Dictionary).get("major_mutation", {})
	return (major_variant as Dictionary).duplicate(true) if major_variant is Dictionary else {}

func _on_portal_mutation_declined() -> void:
	var payload := active_mutation_event_result.duplicate(true)
	payload["mutation_accepted"] = false
	payload["reward_count"] = 0
	_finish_portal_mutation_offer()
	_emit_portal_event_completed(payload)

func _finish_portal_mutation_offer() -> void:
	get_tree().paused = previous_tree_paused
	if active_mutation_offer != null and is_instance_valid(active_mutation_offer):
		active_mutation_offer.queue_free()
	active_mutation_offer = null
	active_mutation_event_result = {}

func _start_double_elite_event(portal_position: Vector2, event_result: Dictionary) -> void:
	if log_portal_events:
		print("Portal event started: Double Elite")
	active_event_elites.clear()
	active_event_result = event_result.duplicate(true)
	_track_event_elite(_spawn_elite(portal_position + Vector2.LEFT * elite_spawn_distance))
	_track_event_elite(_spawn_elite(portal_position + Vector2.RIGHT * elite_spawn_distance))
	if active_event_elites.is_empty():
		if log_portal_events:
			print("Portal event completed: no active elites.")
		_emit_portal_event_completed(event_result)

func _start_power_for_hp_loss_event(event_result: Dictionary) -> void:
	active_event_result = {}
	if log_portal_events:
		print("Portal event started: Power for Max HP loss")
	var result := PortalEventManagerRuntime.apply_power_for_hp_loss(player)
	if log_portal_events and result.get("applied", false) == true:
		print("Power trade applied: +0.35 damage, -20 max HP")
	if log_portal_events:
		print("Portal event completed: Power for Max HP loss")
	_emit_portal_event_completed(event_result.merged(result, true))

func _start_attack_speed_for_damage_loss_event(event_result: Dictionary) -> void:
	active_event_result = {}
	if log_portal_events:
		print("Portal event started: Attack Speed for Damage loss")
	var result := PortalEventManagerRuntime.apply_attack_speed_for_damage_loss(player)
	if log_portal_events and result.get("applied", false) == true:
		print("Trade applied: +0.22 attack speed, -0.18 damage")
	if log_portal_events:
		print("Portal event completed: Attack Speed for Damage loss")
	_emit_portal_event_completed(event_result.merged(result, true))

func _start_enemy_flood_event(event_result: Dictionary) -> void:
	active_event_result = {}
	if log_portal_events:
		print("Portal event started: 20-second enemy flood")
	var result := PortalEventManagerRuntime.apply_enemy_flood(enemy_spawner)
	if result.get("applied", false) == true:
		flood_original_spawn_interval = float(result.get("original_spawn_interval", flood_original_spawn_interval))
		flood_original_max_alive = int(result.get("original_max_alive", flood_original_max_alive))
	flood_timer.set_meta("event_result", event_result.merged(result, true))
	flood_timer.start(20.0)

func _start_triple_reward_for_enemy_speed_event(event_result: Dictionary) -> void:
	active_event_result = {}
	if log_portal_events:
		print("Portal event started: Triple Reward for Enemy Speed")
	var result := PortalEventManagerRuntime.apply_enemy_speed_pressure(enemy_spawner, 1.25)
	speed_pressure_active = result.get("applied", false) == true
	speed_pressure_original_multiplier = float(result.get("original_move_speed_multiplier", 1.0))
	speed_pressure_reward_result = event_result.merged(result, true)
	speed_pressure_reward_result["reward_count"] = max(int(speed_pressure_reward_result.get("reward_count", 3)), 3)
	if speed_pressure_active:
		if log_portal_events:
			print("Greed pressure applied: enemy move speed x%.2f until wave end" % float(result.get("move_speed_multiplier", 1.25)))
		return
	if log_portal_events:
		print("Greed pressure could not be applied. Completing portal event immediately.")
	_emit_portal_event_completed(speed_pressure_reward_result)
	speed_pressure_reward_result = {}
	speed_pressure_original_multiplier = 1.0

func _on_flood_event_finished() -> void:
	PortalEventManagerRuntime.restore_enemy_flood(
		enemy_spawner,
		flood_original_spawn_interval,
		flood_original_max_alive
	)
	if log_portal_events:
		print("Portal event completed: enemy flood survived.")
	var event_result_variant: Variant = flood_timer.get_meta("event_result", {})
	var event_result: Dictionary = event_result_variant if event_result_variant is Dictionary else {}
	_emit_portal_event_completed(event_result)

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
		_emit_portal_event_completed(active_event_result)
		active_event_result = {}

func _resolve_portal_event_result() -> Dictionary:
	if debug_forced_event_id != "":
		var forced_event_id := debug_forced_event_id
		debug_forced_event_id = ""
		return PortalEventResolver.build_event_result_for_id(
			forced_event_id,
			PortalRiskRewardRuntime.build_profile(player)
		)
	return PortalRiskRewardRuntime.pick_event_result(rng, player)

func _pick_portal_event_id() -> String:
	return PortalEventResolver.pick_event_id(rng, PortalRiskRewardRuntime.build_profile(player))

func _pick_elite_role() -> String:
	return PortalEventManagerRuntime.pick_elite_role(rng)

func _resolve_rng(stream_name: String) -> RandomNumberGenerator:
	var run_rng := get_node_or_null("/root/RunRng")
	if run_rng != null and run_rng.has_method("get_rng"):
		var resolved: Variant = run_rng.call("get_rng", stream_name)
		if resolved is RandomNumberGenerator:
			return resolved
	return DeterministicRng.create_fallback_rng(stream_name, "PortalEventManager")

func _finish_enemy_speed_pressure_event() -> void:
	PortalEventManagerRuntime.restore_enemy_speed_pressure(enemy_spawner, speed_pressure_original_multiplier)
	speed_pressure_active = false
	if log_portal_events:
		print("Portal event completed: triple reward survived.")
	_emit_portal_event_completed(speed_pressure_reward_result)
	speed_pressure_reward_result = {}
	speed_pressure_original_multiplier = 1.0

func _emit_portal_event_completed(result: Dictionary) -> void:
	var payload := result.duplicate(true)
	if str(payload.get("event_id", "")) == "":
		payload["event_id"] = "double_elite"
	if not payload.has("reward_count"):
		payload["reward_count"] = 1
	portal_event_completed.emit(payload)
