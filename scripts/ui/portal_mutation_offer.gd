extends CanvasLayer

signal accepted
signal declined

@onready var title_label: Label = $Backdrop/Center/Panel/Margin/VBox/Title
@onready var description_label: Label = $Backdrop/Center/Panel/Margin/VBox/Description
@onready var tags_label: Label = $Backdrop/Center/Panel/Margin/VBox/Tags
@onready var duration_label: Label = $Backdrop/Center/Panel/Margin/VBox/Duration
@onready var reward_label: Label = $Backdrop/Center/Panel/Margin/VBox/Reward
@onready var risk_label: Label = $Backdrop/Center/Panel/Margin/VBox/Risk
@onready var accept_button: Button = $Backdrop/Center/Panel/Margin/VBox/Actions/Accept
@onready var decline_button: Button = $Backdrop/Center/Panel/Margin/VBox/Actions/Decline

var _definition: Dictionary = {}
var _resolved: bool = false

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	decline_button.pressed.connect(_on_decline_pressed)
	_refresh()
	accept_button.grab_focus()

func configure(definition: Dictionary) -> void:
	_definition = definition.duplicate(true)
	if is_node_ready():
		_refresh()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_decline_pressed()
		get_viewport().set_input_as_handled()

func _refresh() -> void:
	title_label.text = str(_definition.get("title", "Portal Mutation"))
	var description := str(_definition.get("description", ""))
	var replacement_warning := str(_definition.get("replacement_warning", ""))
	description_label.text = (
		"%s\n%s" % [description, replacement_warning]
		if replacement_warning != ""
		else description
	)
	tags_label.text = "Affected tags: %s" % _format_tags(_definition.get("effect_tags", []))
	duration_label.text = "Duration: %s" % str(_definition.get("duration", "run")).capitalize()
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
			tags.append(tag.capitalize())
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
