extends Area2D

const ProjectileImpactUtil = preload("res://scripts/combat/projectile_impact_helper.gd")
const ProjectileVisualUtil = preload("res://scripts/combat/projectile_visual_runtime.gd")
const WeaponRuntimeUtil = preload("res://scripts/weapons/weapon_runtime_resolver.gd")

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
var _weapon_data_cache: Dictionary = {}
var _visual_animation_profile: Dictionary = {}
var _visual_base_scale: Vector2 = Vector2.ONE
var _visual_base_rotation: float = 0.0
var _visual_elapsed: float = 0.0
var _visual_phase: float = 0.0
@onready var visual: Sprite2D = get_node_or_null("Visual")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	if visual != null:
		_visual_base_scale = visual.scale
		_visual_base_rotation = visual.rotation

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_update_visual_animation(delta)
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
	_visual_phase = float(abs((weapon_id + ":%d" % slot_index).hash()) % 628) / 100.0

func set_source_weapon_data(new_weapon_data: WeaponData) -> void:
	source_weapon_data = new_weapon_data
	_visual_animation_profile = ProjectileVisualUtil.build_profile(new_weapon_data)

func set_visual_texture(texture: Texture2D) -> void:
	if visual == null or texture == null:
		return
	visual.texture = texture

func _update_visual_animation(delta: float) -> void:
	if visual == null or _visual_animation_profile.is_empty():
		return
	_visual_elapsed += delta
	var scale_multiplier := ProjectileVisualUtil.sample_scale_multiplier(
		_visual_animation_profile,
		_visual_elapsed,
		_visual_phase
	)
	visual.scale = _visual_base_scale * scale_multiplier
	visual.rotation = _visual_base_rotation + (
		_visual_elapsed * float(_visual_animation_profile.get("spin_speed", 0.0))
	)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var weapon_data := _load_weapon_data()
		var final_damage := ProjectileImpactUtil.compute_final_damage(
			damage,
			damage_multiplier,
			shooter,
			body,
			weapon_data
		)
		body.call("take_damage", final_damage, shooter, source_weapon_id, source_slot_index)
		if pierce_count > 0:
			pierce_count -= 1
			return
		queue_free()

func _load_weapon_data() -> WeaponData:
	if source_weapon_data != null:
		return source_weapon_data
	return WeaponRuntimeUtil.load_weapon_data(_weapon_data_cache, source_weapon_id)
