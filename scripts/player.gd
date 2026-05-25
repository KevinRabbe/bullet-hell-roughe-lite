extends CharacterBody2D

const StatBlock = preload("res://scripts/core/stat_block.gd")

@export var debug_starting_hp: float = 100.0
@export var debug_move_speed: float = 300.0

var stats: StatBlock = StatBlock.new()
var current_hp: float

func _ready() -> void:
	stats.max_hp = debug_starting_hp
	stats.movement_speed = debug_move_speed
	current_hp = stats.max_hp

func _physics_process(_delta: float) -> void:
	var input_direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_direction * stats.movement_speed
	move_and_slide()

func take_damage(amount: float) -> void:
	current_hp = maxf(current_hp - amount, 0.0)
	if current_hp <= 0.0:
		die()

func die() -> void:
	print("Player died - placeholder")
