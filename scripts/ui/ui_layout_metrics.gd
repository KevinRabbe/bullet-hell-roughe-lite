class_name UiLayoutMetrics
extends RefCounted

# Shared desktop layout classes. Screens should query this helper instead of
# inventing unrelated breakpoint checks.
enum LayoutClass {
	NORMAL,
	COMPACT,
	TIGHT,
}

const TIGHT_MIN_WIDTH := 1280.0
const TIGHT_MIN_HEIGHT := 720.0
const NORMAL_MIN_WIDTH := 1440.0
const NORMAL_MIN_HEIGHT := 810.0

static func layout_class_for_size(viewport_size: Vector2) -> int:
	if viewport_size.x < TIGHT_MIN_WIDTH or viewport_size.y < TIGHT_MIN_HEIGHT:
		return LayoutClass.TIGHT
	if viewport_size.x < NORMAL_MIN_WIDTH or viewport_size.y < NORMAL_MIN_HEIGHT:
		return LayoutClass.COMPACT
	return LayoutClass.NORMAL

static func screen_margin_horizontal(layout_class: int) -> float:
	match layout_class:
		LayoutClass.TIGHT:
			return 18.0
		LayoutClass.COMPACT:
			return 44.0
		_:
			return 44.0

static func screen_margin_vertical(layout_class: int) -> float:
	match layout_class:
		LayoutClass.TIGHT:
			return 18.0
		LayoutClass.COMPACT:
			return 32.0
		_:
			return 32.0

static func shell_padding(layout_class: int) -> int:
	match layout_class:
		LayoutClass.TIGHT:
			return 16
		LayoutClass.COMPACT:
			return 28
		_:
			return 28

static func section_padding(layout_class: int) -> int:
	match layout_class:
		LayoutClass.TIGHT:
			return 12
		LayoutClass.COMPACT:
			return 16
		_:
			return 16

static func row_gap(layout_class: int) -> int:
	match layout_class:
		LayoutClass.TIGHT:
			return 8
		LayoutClass.COMPACT:
			return 12
		_:
			return 12

static func dense_gap(layout_class: int) -> int:
	match layout_class:
		LayoutClass.TIGHT:
			return 4
		LayoutClass.COMPACT:
			return 6
		_:
			return 6

static func primary_button_height(layout_class: int) -> float:
	match layout_class:
		LayoutClass.TIGHT:
			return 52.0
		LayoutClass.COMPACT:
			return 58.0
		_:
			return 58.0

static func secondary_button_height(layout_class: int) -> float:
	match layout_class:
		LayoutClass.TIGHT:
			return 44.0
		LayoutClass.COMPACT:
			return 48.0
		_:
			return 48.0
