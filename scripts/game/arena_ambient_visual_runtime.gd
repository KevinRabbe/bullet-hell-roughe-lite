extends Node2D

const EMBER_COUNT: int = 18
const EMBER_CORE_COLOR := Color(1.0, 0.28, 0.10, 1.0)
const EMBER_HALO_COLOR := Color(0.82, 0.05, 0.10, 1.0)

@onready var arena_backdrop: ColorRect = get_node_or_null("../Arena") as ColorRect
@onready var lava_fissures: Sprite2D = get_node_or_null("Decals/LavaFissures") as Sprite2D
@onready var ritual_circle: Sprite2D = get_node_or_null("Decals/RitualCircle") as Sprite2D
@onready var hell_crystal: Sprite2D = get_node_or_null("Props/CrystalNW") as Sprite2D

var elapsed: float = 0.0

func _ready() -> void:
	_apply_ambient_pulse()
	queue_redraw()

func _process(delta: float) -> void:
	elapsed = fmod(elapsed + maxf(delta, 0.0), 120.0)
	_apply_ambient_pulse()
	queue_redraw()

func _draw() -> void:
	var arena_rect := _resolve_arena_rect()
	if arena_rect.size.x <= 0.0 or arena_rect.size.y <= 0.0:
		return
	for ember_index in range(EMBER_COUNT):
		_draw_ember(arena_rect, ember_index)

func _draw_ember(arena_rect: Rect2, ember_index: int) -> void:
	var horizontal_seed := _unit_hash(ember_index * 37 + 11)
	var vertical_seed := _unit_hash(ember_index * 53 + 7)
	var speed_seed := _unit_hash(ember_index * 71 + 19)
	var phase_seed := _unit_hash(ember_index * 29 + 5)
	var rise_cycle := fposmod(
		vertical_seed + elapsed * lerpf(0.018, 0.032, speed_seed),
		1.0
	)
	var horizontal_drift := sin(elapsed * lerpf(0.45, 0.82, speed_seed) + phase_seed * TAU) * 9.0
	var position := Vector2(
		lerpf(arena_rect.position.x, arena_rect.end.x, horizontal_seed) + horizontal_drift,
		lerpf(arena_rect.end.y, arena_rect.position.y, rise_cycle)
	)
	var twinkle := 0.5 + 0.5 * sin(elapsed * lerpf(1.4, 2.2, speed_seed) + phase_seed * TAU)
	var core_alpha := lerpf(0.10, 0.32, twinkle)
	var radius := lerpf(0.9, 1.8, speed_seed)
	draw_circle(position, radius * 3.2, Color(EMBER_HALO_COLOR, core_alpha * 0.18))
	draw_circle(position, radius, Color(EMBER_CORE_COLOR, core_alpha))

func _apply_ambient_pulse() -> void:
	_apply_sprite_pulse(
		lava_fissures,
		Color(1.0, 0.72, 0.68, 1.0),
		0.43,
		0.61,
		0.58
	)
	_apply_sprite_pulse(
		ritual_circle,
		Color(1.0, 0.78, 0.78, 1.0),
		0.40,
		0.54,
		0.46
	)
	_apply_sprite_pulse(
		hell_crystal,
		Color(1.0, 0.78, 0.82, 1.0),
		0.78,
		0.98,
		0.72
	)

func _apply_sprite_pulse(
	sprite: Sprite2D,
	tint: Color,
	minimum_alpha: float,
	maximum_alpha: float,
	speed: float
) -> void:
	if sprite == null:
		return
	var pulse := 0.5 + 0.5 * sin(elapsed * speed)
	sprite.modulate = Color(tint.r, tint.g, tint.b, lerpf(minimum_alpha, maximum_alpha, pulse))

func _resolve_arena_rect() -> Rect2:
	if arena_backdrop == null:
		return Rect2()
	return Rect2(
		Vector2(arena_backdrop.offset_left, arena_backdrop.offset_top),
		Vector2(
			arena_backdrop.offset_right - arena_backdrop.offset_left,
			arena_backdrop.offset_bottom - arena_backdrop.offset_top
		)
	)

static func _unit_hash(seed: int) -> float:
	var value := sin(float(seed) * 12.9898) * 43758.5453
	return fposmod(value, 1.0)
