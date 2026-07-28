extends CanvasLayer

signal accepted
signal declined

const InfernalUiStyleRef = preload("res://scripts/ui/infernal_ui_style.gd")
const InfernalRitualBackdropRef = preload("res://scripts/ui/components/infernal_ritual_backdrop.gd")

@onready var modal_shell: PanelContainer = $Backdrop/Center/ModalShell

var description_label: Label
var tags_label: Label
var duration_label: Label
var reward_label: Label
var risk_label: Label
var accept_button: Button
var decline_button: Button

var _definition: Dictionary = {}
var _resolved: bool = false

func _ready() -> void:
	_build_ritual_backdrop()
	_build_standard_content()
	_refresh()
	if accept_button != null:
		accept_button.grab_focus()

func _build_ritual_backdrop() -> void:
	if modal_shell == null or modal_shell.get_node_or_null("RitualBackdrop") != null:
		return
	var backdrop := InfernalRitualBackdropRef.new() as Control
	backdrop.name = "RitualBackdrop"
	modal_shell.add_child(backdrop)
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal_shell.move_child(backdrop, 0)

func _build_standard_content() -> void:
	var content_container: VBoxContainer = modal_shell.call("get_content_container") as VBoxContainer
	var actions_container: HBoxContainer = modal_shell.call("get_actions_container") as HBoxContainer
	if content_container == null or actions_container == null:
		push_error("Portal mutation offer requires StandardModalShell content and action slots.")
		return

	description_label = Label.new()
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size.y = 48.0
	InfernalUiStyleRef.apply_text_role(description_label, InfernalUiStyleRef.TEXT_BODY)
	content_container.add_child(description_label)

	var metadata_row := HBoxContainer.new()
	metadata_row.alignment = BoxContainer.ALIGNMENT_CENTER
	metadata_row.add_theme_constant_override("separation", 18)
	content_container.add_child(metadata_row)

	tags_label = Label.new()
	tags_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InfernalUiStyleRef.apply_text_role(tags_label, InfernalUiStyleRef.TEXT_MUTED)
	metadata_row.add_child(tags_label)

	duration_label = Label.new()
	duration_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	InfernalUiStyleRef.apply_text_role(duration_label, InfernalUiStyleRef.TEXT_MUTED)
	metadata_row.add_child(duration_label)

	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	reward_label.custom_minimum_size.y = 42.0
	InfernalUiStyleRef.apply_text_role(reward_label, InfernalUiStyleRef.TEXT_VALUE)
	content_container.add_child(reward_label)

	risk_label = Label.new()
	risk_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	risk_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	risk_label.custom_minimum_size.y = 42.0
	InfernalUiStyleRef.apply_text_role(risk_label, InfernalUiStyleRef.TEXT_WARNING)
	content_container.add_child(risk_label)

	decline_button = Button.new()
	decline_button.text = "Decline"
	decline_button.custom_minimum_size = Vector2(180, 48)
	InfernalUiStyleRef.apply_button(decline_button, InfernalUiStyleRef.BUTTON_SECONDARY)
	decline_button.pressed.connect(_on_decline_pressed)
	actions_container.add_child(decline_button)

	accept_button = Button.new()
	accept_button.text = "Accept Mutation"
	accept_button.custom_minimum_size = Vector2(220, 48)
	InfernalUiStyleRef.apply_button(accept_button, InfernalUiStyleRef.BUTTON_PRIMARY)
	accept_button.pressed.connect(_on_accept_pressed)
	actions_container.add_child(accept_button)
	actions_container.alignment = BoxContainer.ALIGNMENT_CENTER

func configure(definition: Dictionary) -> void:
	_definition = definition.duplicate(true)
	if is_node_ready():
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_decline_pressed()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	if modal_shell == null:
		return
	var mutation_title := str(_definition.get("title", "Portal Mutation"))
	var tier := str(_definition.get("mutation_tier", "")).strip_edges()
	var shell_subtitle := "PORTAL MUTATION"
	if tier != "":
		shell_subtitle += " · %s" % tier.to_upper()
	modal_shell.call("configure", mutation_title, shell_subtitle)
	if description_label == null:
		return
	var description := str(_definition.get("description", ""))
	var replacement_warning := str(_definition.get("replacement_warning", ""))
	description_label.text = (
		"%s\n%s" % [description, replacement_warning]
		if replacement_warning != ""
		else description
	)
	tags_label.text = "Tags: %s" % _format_tags(_definition.get("effect_tags", []))
	duration_label.text = "Duration: %s" % str(_definition.get("duration", "run")).replace("_", " ").capitalize()
	reward_label.text = "Reward: %s" % str(_definition.get("reward", ""))
	risk_label.text = "Risk: %s" % str(_definition.get("risk", ""))
	accept_button.text = "Replace Mutation" if replacement_warning != "" else "Accept Mutation"

func _format_tags(tags_variant: Variant) -> String:
	if not (tags_variant is Array):
		return "-"
	var tags: Array[String] = []
	for tag_variant in tags_variant:
		var tag := str(tag_variant).strip_edges()
		if tag != "":
			tags.append(tag.replace("_", " ").capitalize())
	return ", ".join(tags) if not tags.is_empty() else "-"

func _on_accept_pressed() -> void:
	if _resolved:
		return
	_resolved = true
	accepted.emit()

func _on_decline_pressed() -> void:
	if _resolved:
		return
	_resolved = true
	declined.emit()
