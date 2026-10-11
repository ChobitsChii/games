class_name BossPhase
extends RefCounted
## Datenstruktur für Boss-Angriffsmuster und Phasen.

var name: String = ""
var duration: float = 2.0
var action: String = "idle" # "idle", "charge", "summon", "spiral_shot", "slam"
var step_index: int = 0


static func create(p_name: String, p_duration: float, p_action: String) -> BossPhase:
	var phase := BossPhase.new()
	phase.name = p_name
	phase.duration = p_duration
	phase.action = p_action
	return phase
