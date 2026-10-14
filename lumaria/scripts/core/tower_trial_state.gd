class_name TowerTrialState
extends RefCounted
## Reine Modellklasse für den Turm des Ewigen Prismas und den Showdown gegen Malakor.
## Verwaltet den Fortschritt der 3 Multitool-Prüfungen (Wurzel, Tiefe, Wind)
## sowie den 3-Phasen-Kampf gegen den dimensionalen Endboss Malakor.
## Vollständig unit-testbar.

signal trial_completed(trial_name: String)
signal apex_unlocked()
signal malakor_phase_changed(phase: int)
signal malakor_defeated()

var trial_roots: bool = false
var trial_depths: bool = false
var trial_winds: bool = false

var malakor_phase: int = 1 # 1: Schattenduelle, 2: Kristallbarriere, 3: Riss-Souverän
var malakor_barrier_elements: Array[String] = ["nature", "tide", "storm"]
var is_malakor_defeated: bool = false


func complete_trial(trial_name: String) -> bool:
	var newly_completed := false
	match trial_name:
		"roots":
			if not trial_roots:
				trial_roots = true
				newly_completed = true
		"depths":
			if not trial_depths:
				trial_depths = true
				newly_completed = true
		"winds":
			if not trial_winds:
				trial_winds = true
				newly_completed = true

	if newly_completed:
		trial_completed.emit(trial_name)
		if is_apex_unlocked():
			apex_unlocked.emit()
	return newly_completed


func is_apex_unlocked() -> bool:
	return trial_roots and trial_depths and trial_winds


func break_barrier_element(element: String) -> bool:
	if malakor_phase != 2:
		return false
	if malakor_barrier_elements.has(element):
		malakor_barrier_elements.erase(element)
		if malakor_barrier_elements.is_empty():
			advance_malakor_phase()
		return true
	return false


func advance_malakor_phase() -> int:
	if malakor_phase < 3:
		malakor_phase += 1
		malakor_phase_changed.emit(malakor_phase)
	elif malakor_phase == 3 and not is_malakor_defeated:
		is_malakor_defeated = true
		malakor_defeated.emit()
	return malakor_phase


func serialize() -> Dictionary:
	return {
		"trial_roots": trial_roots,
		"trial_depths": trial_depths,
		"trial_winds": trial_winds,
		"malakor_phase": malakor_phase,
		"malakor_barrier_elements": malakor_barrier_elements.duplicate(),
		"is_malakor_defeated": is_malakor_defeated,
	}


func deserialize(data: Dictionary) -> void:
	trial_roots = bool(data.get("trial_roots", false))
	trial_depths = bool(data.get("trial_depths", false))
	trial_winds = bool(data.get("trial_winds", false))
	malakor_phase = int(data.get("malakor_phase", 1))
	malakor_barrier_elements = Array(data.get("malakor_barrier_elements", ["nature", "tide", "storm"]), TYPE_STRING, "", null)
	is_malakor_defeated = bool(data.get("is_malakor_defeated", false))
