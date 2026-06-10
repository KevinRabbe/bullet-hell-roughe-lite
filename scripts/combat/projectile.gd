extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime_seconds: float = 2.0
@export var damage_multiplier: float = 1.0
@export var pierce_count: int = 0

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var shooter: Node
var source_weapon_id: String = ""
var source_slot_index: int = -1
var source_weapon_data: WeaponData
@onready var visual: Sprite2D = get_node_or_null("Visual")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	life_left -= delta
	if life_left <= 0.0:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() > 0.0:
		direction = new_direction.normalized()
		rotation = direction.angle()

func set_shooter(new_shooter: Node) -> void:
	shooter = new_shooter

func set_source_context(weapon_id: String, slot_index: int) -> void:
	source_weapon_id = weapon_id
	source_slot_index = slot_index

func set_source_weapon_data(new_weapon_data: WeaponData) -> void:
	source_weapon_data = new_weapon_data

func set_visual_texture(texture: Texture2D) -> void:
	if visual == null or texture == null:
		return
	visual.texture = texture

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage * damage_multiplier
		if shooter != null and shooter.has_method("get_damage_multiplier_for_target"):
			final_damage *= float(shooter.call("get_damage_multiplier_for_target", body))
		var weapon_data := _load_weapon_data()
		if weapon_data != null and weapon_data.bonus_damage_vs_status_id != "":
			var stacks := 0
			if body.has_method("get_status_stack_count"):
				stacks = int(body.call("get_status_stack_count", weapon_data.bonus_damage_vs_status_id))
			if stacks > 0:
				final_damage *= weapon_data.bonus_damage_vs_status_multiplier
				if weapon_data.bonus_damage_vs_status_max_hp_fraction > 0.0:
					final_damage += _get_body_max_hp(body) * weapon_data.bonus_damage_vs_status_max_hp_fraction * float(stacks)
		if weapon_data != null and weapon_data.bonus_damage_per_enemy_with_status_id != "" and weapon_data.bonus_damage_per_enemy_with_status_amount > 0.0:
			var empowered_enemy_count := 0
			if shooter != null and shooter.has_method("count_enemies_with_status"):
				empowered_enemy_count = int(shooter.call("count_enemies_with_status", weapon_data.bonus_damage_per_enemy_with_status_id))
			if weapon_data.bonus_damage_per_enemy_with_status_max_enemies > 0:
				empowered_enemy_count = mini(empowered_enemy_count, weapon_data.bonus_damage_per_enemy_with_status_max_enemies)
			if empowered_enemy_count > 0:
				final_damage *= 1.0 + (weapon_data.bonus_damage_per_enemy_with_status_amount * float(empowered_enemy_count))
		if weapon_data != null and weapon_data.bonus_damage_per_player_stat_id != "" and weapon_data.bonus_damage_per_player_stat_amount > 0.0:
			var player_stat_value := 0.0
			if shooter != null and shooter.has_method("get_stat_value_for_weapon_bonus"):
				player_stat_value = float(shooter.call("get_stat_value_for_weapon_bonus", weapon_data.bonus_damage_per_player_stat_id, 0.0))
			if weapon_data.bonus_damage_per_player_stat_max_value > 0.0:
				player_stat_value = minf(player_stat_value, weapon_data.bonus_damage_per_player_stat_max_value)
			if player_stat_value > 0.0:
				final_damage *= 1.0 + (weapon_data.bonus_damage_per_player_stat_amount * player_stat_value)
		body.call("take_damage", final_damage, shooter, source_weapon_id, source_slot_index)
		if pierce_count > 0:
			pierce_count -= 1
			return
		queue_free()

func _load_weapon_data() -> WeaponData:
	if source_weapon_data != null:
		return source_weapon_data
	if source_weapon_id == "":
		return null
	var resource_path := "res://data/weapons/%s.tres" % source_weapon_id
	if not ResourceLoader.exists(resource_path):
		return null
	return load(resource_path) as WeaponData

func _get_body_max_hp(body: Node) -> float:
	if body == null:
		return 0.0
	return maxf(float(body.get("max_hp")), 0.0)
