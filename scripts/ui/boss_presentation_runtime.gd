class_name BossPresentationRuntime
extends RefCounted

const EventBannerRuntimeRef = preload("res://scripts/ui/event_banner_runtime.gd")
const SfxRuntimeRef = preload("res://scripts/audio/sfx_runtime.gd")

static func show_boss_spawn(owner: Node, boss_id: String) -> void:
	match boss_id:
		"gate_beast":
			show_gate_beast_spawn(owner)
		"cinder_marshal":
			show_cinder_marshal_spawn(owner)
		"pyre_archon":
			show_pyre_archon_spawn(owner)
		"last_shade":
			show_last_shade_spawn(owner)

static func show_boss_defeated(owner: Node, boss_id: String) -> void:
	match boss_id:
		"gate_beast":
			show_gate_beast_defeated(owner)
		"cinder_marshal":
			show_cinder_marshal_defeated(owner)
		"pyre_archon":
			show_pyre_archon_defeated(owner)
		"last_shade":
			show_last_shade_defeated(owner)

static func show_gate_beast_spawn(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_spawn", -5.0, 1.0, 400)
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 5 MILESTONE",
		"GATE BEAST",
		"Break the guardian. Claim the Ascension beyond it."
	)

static func show_gate_beast_defeated(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_defeat", -5.0, 1.0, 400)
	EventBannerRuntimeRef.show(
		owner,
		"GUARDIAN BROKEN",
		"THE ASCENSION OPENS",
		"Clear the frontier and choose what the curse becomes."
	)

static func show_cinder_marshal_spawn(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_spawn", -5.0, 0.96, 400)
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 10 MILESTONE",
		"CINDER MARSHAL",
		"Read the firing line. Break formation during recovery."
	)

static func show_cinder_marshal_defeated(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_defeat", -5.0, 1.0, 400)
	EventBannerRuntimeRef.show(
		owner,
		"MARSHAL SILENCED",
		"THE FRONTIER YIELDS",
		"Claim the bounty, rebuild, and push beyond the midpoint."
	)

static func show_pyre_archon_spawn(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_spawn", -5.0, 0.90, 400)
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 15 MILESTONE",
		"PYRE ARCHON",
		"The pyres divide the arena. Hold the corridor."
	)

static func show_pyre_archon_defeated(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_defeat", -5.0, 0.94, 400)
	EventBannerRuntimeRef.show(
		owner,
		"THE PYRES FALL",
		"THE LAST FRONTIER OPENS",
		"Rebuild once more. The collapse waits beyond."
	)

static func show_last_shade_spawn(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_spawn", -4.0, 0.82, 500)
	EventBannerRuntimeRef.show(
		owner,
		"WAVE 20 — FINAL FRONTIER",
		"LAST SHADE",
		"Read the mark. Cross the safe corridor. End the collapse."
	)

static func show_last_shade_defeated(owner: Node) -> void:
	SfxRuntimeRef.play(owner, "boss_defeat", -4.0, 0.88, 500)
	EventBannerRuntimeRef.show(
		owner,
		"THE LAST SHADE FALLS",
		"FRONTIER CONQUERED",
		"The twenty-wave hunt is complete."
	)
