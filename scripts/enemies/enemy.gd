extends CharacterBody2D
const ProjectileSpawnUtil = preload("res://scripts/combat/projectile_spawn_helper.gd")

@export var move_speed: float = 140.0
@export var max_hp: float = 20.0
@export var target_path: NodePath
@export var contact_damage: float = 6.0
@export var contact_range: float = 55.0
@export var damage_interval_seconds: float = 0.75
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var elite_role: String = ""
@export_enum("imp_runner", "husk_brute", "spit_fiend") var enemy_variant: String = "imp_runner"
@export var ranged_damage: float = 4.0
@export var ranged_interval_seconds: float = 1.2
@export var ranged_attack_range: float = 210.0

var target: Node2D
var current_hp: float
var damage_cooldown_left: float = 0.0
var ranged_cooldown_left: float = 0.0
@onready var visual: CanvasItem = get_node_or_null("Visual")
@onready var visual_sprite: Sprite2D = get_node_or_null("Visual")

const IMP_RUNNER_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/dust_imp.png")
const HUSK_BRUTE_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/hellhound.png")
const SPIT_FIEND_TEXTURE: Texture2D = preload("res://assets/sprites/enemies/hellshot_frontier/rift_cultist.png")
const SKULL_FIREBALL_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemy_skull_fireball.png")
const RIFT_SHARD_TEXTURE: Texture2D = preload("res://assets/sprites/projectiles/enemy_rift_shard.png")
const ENEMY_PROJECTILE_SCENE: PackedScene = preload("res://scenes/enemies/EnemyProjectile.tscn")
const ENEMY_DATA_PATHS: Dictionary = {
	"imp_runner": "res://data/enemies/imp_runner.tres",
	"husk_brute": "res://data/enemies/husk_brute.tres",
	"spit_fiend": "res://data/enemies/spit_fiend.tres"
}

func _ready() -> void:
	_apply_variant_stats()
	current_hp = max_hp
	add_to_group("enemies")
	if target_path != NodePath():
		target = get_node_or_null(target_path)
	_find_player_if_needed()

func set_target(new_target: Node2D) -> void:
	target = new_target

func _physics_process(delta: float) -> void:
	damage_cooldown_left = maxf(damage_cooldown_left - delta, 0.0)
	ranged_cooldown_left = maxf(ranged_cooldown_left - delta, 0.0)
	_find_player_if_needed()

	if target == null or not is_instance_valid(target):
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var direction := (target.global_position - global_position).normalized()
	velocity = direction * move_speed
	if enemy_variant == "spit_fiend":
		var distance_to_player := global_position.distance_to(target.global_position)
		if distance_to_player <= ranged_attack_range:
			velocity *= 0.25
	move_and_slide()
	_try_damage_player()
	_try_ranged_damage_player()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	_spawn_enemy_hit_flash()
	if current_hp <= 0.0:
		_spawn_death_puff()
		_grant_kill_rewards()
		queue_free()

func _grant_kill_rewards() -> void:
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	var reward_gold := 10 if is_boss else 1
	var reward_xp := 15 if is_boss else 1
	var player_node := players[0]
	if player_node != null and player_node.has_method("add_gold"):
		player_node.call("add_gold", reward_gold)
	if player_node != null and player_node.has_method("add_xp"):
		player_node.call("add_xp", reward_xp)

func _find_player_if_needed() -> void:
	if target != null and is_instance_valid(target):
		return
	var players := get_tree().get_nodes_in_group("players")
	if players.is_empty():
		return
	if players[0] is Node2D:
		target = players[0] as Node2D

func _try_damage_player() -> void:
	if enemy_variant == "spit_fiend":
		return
	if damage_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return

	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > contact_range:
		return

	print("ENEMY HIT PLAYER | distance %.1f | damage %.1f" % [distance_to_player, contact_damage])
	target.call("take_damage", contact_damage)
	damage_cooldown_left = damage_interval_seconds

func _try_ranged_damage_player() -> void:
	if enemy_variant != "spit_fiend":
		return
	if ranged_cooldown_left > 0.0:
		return
	if target == null or not is_instance_valid(target):
		return
	if not target.has_method("take_damage"):
		return
	var distance_to_player := global_position.distance_to(target.global_position)
	if distance_to_player > ranged_attack_range:
		return
	var projectile_speed := 360.0
	var projectile_lifetime := 2.0
	if elite_role == "rift_caller":
		projectile_speed = 300.0
		projectile_lifetime = 2.3
	else:
		projectile_speed = 390.0
		projectile_lifetime = 1.9
	var projectile := ProjectileSpawnUtil.spawn_projectile(
		ENEMY_PROJECTILE_SCENE,
		get_tree().current_scene,
		global_position,
		target.global_position - global_position,
		ranged_damage,
		projectile_speed,
		projectile_lifetime,
		PI
	)
	if projectile != null:
		var projectile_visual := projectile.get_node_or_null("Visual")
		if projectile_visual is Sprite2D:
			var projectile_sprite := projectile_visual as Sprite2D
			if elite_role == "rift_caller":
				projectile_sprite.texture = RIFT_SHARD_TEXTURE
			else:
				projectile_sprite.texture = SKULL_FIREBALL_TEXTURE
			projectile_sprite.rotation = (target.global_position - global_position).angle() + PI
	print("SPIT FIEND SHOT PROJECTILE | distance %.1f | damage %.1f" % [distance_to_player, ranged_damage])
	ranged_cooldown_left = ranged_interval_seconds

func _apply_variant_stats() -> void:
	var data := _load_enemy_data(enemy_variant)
	var has_data := data != null
	if has_data:
		_apply_enemy_data(data)
	match enemy_variant:
		"imp_runner":
			if not has_data:
				move_speed = 190.0
				max_hp = 16.0
				contact_damage = 5.0
				damage_interval_seconds = 0.65
			if visual != null:
				visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if visual_sprite != null:
				visual_sprite.texture = IMP_RUNNER_TEXTURE
				visual_sprite.scale = Vector2(0.085, 0.085)
		"husk_brute":
			if not has_data:
				move_speed = 95.0
				max_hp = 40.0
				contact_damage = 10.0
				damage_interval_seconds = 1.0
			if visual != null:
				visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if visual_sprite != null:
				visual_sprite.texture = HUSK_BRUTE_TEXTURE
				visual_sprite.scale = Vector2(0.1, 0.1)
		"spit_fiend":
			if not has_data:
				move_speed = 120.0
				max_hp = 24.0
				contact_damage = 3.0
				damage_interval_seconds = 1.2
				ranged_damage = 4.0
				ranged_interval_seconds = 1.1
				ranged_attack_range = 230.0
			if visual != null:
				visual.modulate = Color(1.0, 1.0, 1.0, 1.0)
			if visual_sprite != null:
				visual_sprite.texture = SPIT_FIEND_TEXTURE
				visual_sprite.scale = Vector2(0.09, 0.09)

func _load_enemy_data(variant_id: String) -> EnemyData:
	var resource_path := str(ENEMY_DATA_PATHS.get(variant_id, ""))
	if resource_path == "" or not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as EnemyData

func _apply_enemy_data(data: EnemyData) -> void:
	max_hp = data.max_hp
	move_speed = data.move_speed
	contact_damage = data.contact_damage
	contact_range = data.contact_range
	damage_interval_seconds = data.damage_interval_seconds
	ranged_damage = data.ranged_damage
	ranged_interval_seconds = data.ranged_interval_seconds
	ranged_attack_range = data.ranged_attack_range
	is_elite = data.is_elite
	is_boss = data.is_boss

func _spawn_enemy_hit_flash() -> void:
	if visual == null:
		return
	visual.modulate = Color(1.35, 1.35, 1.35, 1.0)
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _spawn_death_puff() -> void:
	if get_tree() == null or get_tree().current_scene == null:
		return
	var puff := Sprite2D.new()
	puff.global_position = global_position
	puff.z_index = z_index + 1
	if visual_sprite != null and visual_sprite.texture != null:
		puff.texture = visual_sprite.texture
		puff.scale = visual_sprite.scale * 0.85
	else:
		puff.self_modulate = Color(1.0, 0.45, 0.35, 0.9)
	get_tree().current_scene.add_child(puff)
	var tween := create_tween()
	tween.tween_property(puff, "scale", puff.scale * 1.35, 0.18)
	tween.parallel().tween_property(puff, "modulate", Color(1.0, 0.45, 0.35, 0.0), 0.18)
	tween.finished.connect(func() -> void:
		if is_instance_valid(puff):
			puff.queue_free()
	)
