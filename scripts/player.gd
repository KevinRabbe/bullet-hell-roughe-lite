extends CharacterBody2D

const StatBlock = preload("res://scripts/core/stat_block.gd")

@export var debug_starting_hp: float = 100.0
@export var debug_move_speed: float = 300.0

var stats: StatBlock
var current_hp: float

func _physics_process(_delta: float) -> void:
	var input_direction := Vector2.ZERO

	input_direction.x = Input.get_axis("move_left", "move_right")
	input_direction.y = Input.get_axis("move_up", "move_down")
	input_direction = input_direction.normalized()

	velocity = input_direction * stats.movement_speed
	move_and_slide()

func _ready() -> void:
	stats = StatBlock.new()
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp
