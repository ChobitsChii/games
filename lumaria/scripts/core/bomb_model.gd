class_name BombModel
extends RefCounted
## Reine Logikklasse für die Schall-Bomben (Sonic Bombs).
## Berechnet Zündschnur-Dauer, Pulsationsrate für das visuelle Blinken,
## Explosionsradius, Schaden und Zerstörungsprüfungen für brüchige Wände.
## Unabhängig vom Szenenbaum und vollständig unit-testbar.

enum State { IDLE, FUSING, EXPLODING, DETONATED }

const FUSE_DURATION: float = 2.4
const BLAST_RADIUS: float = 130.0
const ENEMY_DAMAGE: int = 60
const PLAYER_DAMAGE_QUARTERS: int = 2

var state: State = State.IDLE
var remaining_fuse: float = FUSE_DURATION


func start_fuse() -> void:
	state = State.FUSING
	remaining_fuse = FUSE_DURATION


func tick(delta: float) -> bool:
	if state != State.FUSING:
		return false

	remaining_fuse -= delta
	if remaining_fuse <= 0.0:
		state = State.EXPLODING
		return true
	return false


func finish_explosion() -> void:
	state = State.DETONATED


func get_pulse_frequency() -> float:
	if state != State.FUSING:
		return 0.0
	var progress: float = 1.0 - clampf(remaining_fuse / FUSE_DURATION, 0.0, 1.0)
	# Frequenz steigt von 4.0 Hz (langsam) auf 20.0 Hz (schnelles Flackern vor Blast)
	return lerpf(4.0, 20.0, progress * progress)


func is_in_blast_radius(bomb_pos: Vector2, target_pos: Vector2) -> bool:
	return bomb_pos.distance_squared_to(target_pos) <= (BLAST_RADIUS * BLAST_RADIUS)


func can_break_obstacle(obstacle_type: String) -> bool:
	match obstacle_type:
		"cracked_wall", "destructible_pot", "destructible_grass", "wind_shield":
			return true
		_:
			return false
