extends Area2D

@export var speed: float = 700.0
@export var damage: float = 10.0
@export var lifetime_seconds: float = 2.0
@export var damage_multiplier: float = 1.0
@export var pierce_count: int = 0
@export var trail_enabled: bool = true
@export var trail_color: Color = Color(1.0, 0.35, 0.55, 0.9)

var direction: Vector2 = Vector2.RIGHT
var life_left: float = 0.0
var shooter: Node
var _trail_points: PackedVector2Array = PackedVector2Array()
@onready var trail_line: Line2D = get_node_or_null("Trail")

func _ready() -> void:
	life_left = lifetime_seconds
	body_entered.connect(_on_body_entered)
	if trail_line != null:
		trail_line.visible = trail_enabled
		trail_line.default_color = trail_color

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_update_trail()
	life_left -= delta
	if life_left <= 0.0:
		queue_free()

func set_direction(new_direction: Vector2) -> void:
	if new_direction.length_squared() > 0.0:
		direction = new_direction.normalized()
		rotation = direction.angle()

func set_shooter(new_shooter: Node) -> void:
	shooter = new_shooter

func _update_trail() -> void:
	if trail_line == null or not trail_enabled:
		return
	_trail_points.push_back(Vector2.ZERO)
	while _trail_points.size() > 6:
		_trail_points.remove_at(0)
	for index in range(_trail_points.size()):
		var falloff := float(_trail_points.size() - index)
		_trail_points[index] = -direction * (falloff * 5.0)
	trail_line.points = _trail_points

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		var final_damage := damage * damage_multiplier
		if shooter != null and shooter.has_method("get_damage_multiplier_for_target"):
			final_damage *= float(shooter.call("get_damage_multiplier_for_target", body))
		body.call("take_damage", final_damage)
		if pierce_count > 0:
			pierce_count -= 1
			return
		queue_free()
