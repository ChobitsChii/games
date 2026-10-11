class_name BossPatternRunner
extends RefCounted
## Zustands- und Ablauf-Logik für Bosse mit 2-3 Phasen und Angriffsmustern.

enum BossState {
	IDLE,
	TELEGRAPH,
	ATTACKING,
	RECOVERY,
	PHASE_TRANSITION,
	DEFEATED,
}

var current_phase_idx: int = 0
var max_phases: int = 3
var phases: Array[Array] = [] # Liste von Arrays mit BossPhase Schritten
var current_step_idx: int = 0
var state: BossState = BossState.IDLE
var step_timer: float = 0.0
var hp: int = 100
var max_hp: int = 100


func init_boss(p_max_hp: int, p_phase_patterns: Array[Array]) -> void:
	max_hp = p_max_hp
	hp = p_max_hp
	phases = p_phase_patterns
	max_phases = p_phase_patterns.size()
	current_phase_idx = 0
	current_step_idx = 0
	state = BossState.IDLE
	step_timer = 0.0


func get_current_step() -> BossPhase:
	if current_phase_idx < phases.size():
		var p_list: Array = phases[current_phase_idx]
		if current_step_idx < p_list.size():
			return p_list[current_step_idx]
	return null


func update(delta: float) -> void:
	if state == BossState.DEFEATED:
		return

	step_timer += delta
	var step: BossPhase = get_current_step()
	if step != null and step_timer >= step.duration:
		step_timer = 0.0
		advance_step()


func advance_step() -> void:
	if current_phase_idx >= phases.size():
		return
	var p_list: Array = phases[current_phase_idx]
	current_step_idx = (current_step_idx + 1) % p_list.size()


func take_damage(amount: int) -> bool:
	if state == BossState.DEFEATED:
		return false

	hp = maxi(0, hp - amount)
	if hp <= 0:
		state = BossState.DEFEATED
		return true

	# Phasen-Wechsel prüfen basierend auf HP Schwellen
	var hp_fraction: float = float(hp) / float(max_hp)
	var target_phase: int = 0
	if max_phases == 2:
		if hp_fraction <= 0.5:
			target_phase = 1
	elif max_phases == 3:
		if hp_fraction <= 0.33:
			target_phase = 2
		elif hp_fraction <= 0.66:
			target_phase = 1

	if target_phase > current_phase_idx:
		current_phase_idx = target_phase
		current_step_idx = 0
		step_timer = 0.0
		state = BossState.PHASE_TRANSITION

	return false
