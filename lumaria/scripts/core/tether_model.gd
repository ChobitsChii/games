class_name TetherModel
extends RefCounted
## Reine Logikklasse für das Kinetische Fangseil (Kinetic Tether).
## Berechnet Reichweite, Flugbahn, Geschwindigkeiten, Zustände
## und Interaktionen mit Pfählen, Gegenständen, Gegner-Schilden und Boss Carapax.
## Unabhängig vom Szenenbaum und vollständig unit-testbar.

enum State {
	IDLE,
	EXTENDING,
	ATTACHED_POST,
	PULLING_ITEM,
	STRIPPING_SHIELD,
	STUNNING_BOSS,
	RETRACTING
}

const MAX_RANGE: float = 480.0
const EXTEND_SPEED: float = 950.0
const RETRACT_SPEED: float = 1150.0
const PLAYER_PULL_SPEED: float = 680.0
const ITEM_PULL_SPEED: float = 850.0
const ARRIVAL_MARGIN: float = 48.0

var current_state: State = State.IDLE
var origin_pos: Vector2 = Vector2.ZERO
var aim_dir: Vector2 = Vector2.RIGHT
var current_tip_pos: Vector2 = Vector2.ZERO
var target_anchor_pos: Vector2 = Vector2.ZERO
var current_distance: float = 0.0

var target_id: String = ""
var target_type: String = "" # "post", "item", "shield", "boss"


func launch(origin: Vector2, direction: Vector2) -> void:
	current_state = State.EXTENDING
	origin_pos = origin
	aim_dir = direction.normalized() if direction.length_squared() > 0.001 else Vector2.RIGHT
	current_tip_pos = origin
	current_distance = 0.0
	target_anchor_pos = Vector2.ZERO
	target_id = ""
	target_type = ""


func update_extension(delta: float) -> Vector2:
	if current_state != State.EXTENDING:
		return current_tip_pos

	var step := EXTEND_SPEED * delta
	current_distance += step
	if current_distance >= MAX_RANGE:
		current_distance = MAX_RANGE
		current_tip_pos = origin_pos + aim_dir * MAX_RANGE
		current_state = State.RETRACTING
	else:
		current_tip_pos = origin_pos + aim_dir * current_distance

	return current_tip_pos


func update_retraction(delta: float) -> Vector2:
	if current_state != State.RETRACTING:
		return current_tip_pos

	current_distance = maxf(0.0, current_distance - RETRACT_SPEED * delta)
	current_tip_pos = origin_pos + aim_dir * current_distance
	if current_distance <= 4.0:
		reset()

	return current_tip_pos


func attach_to_post(post_pos: Vector2, post_id: String = "") -> bool:
	if current_state != State.EXTENDING:
		return false
	current_state = State.ATTACHED_POST
	target_type = "post"
	target_id = post_id
	target_anchor_pos = post_pos
	current_tip_pos = post_pos
	return true


func attach_to_item(item_pos: Vector2, item_id: String = "") -> bool:
	if current_state != State.EXTENDING:
		return false
	current_state = State.PULLING_ITEM
	target_type = "item"
	target_id = item_id
	target_anchor_pos = item_pos
	current_tip_pos = item_pos
	return true


func strip_shield(enemy_id: String = "") -> bool:
	if current_state != State.EXTENDING:
		return false
	current_state = State.STRIPPING_SHIELD
	target_type = "shield"
	target_id = enemy_id
	return true


func stun_boss(boss_id: String = "") -> bool:
	if current_state != State.EXTENDING:
		return false
	current_state = State.STUNNING_BOSS
	target_type = "boss"
	target_id = boss_id
	return true


func update_player_pull(player_pos: Vector2, delta: float) -> Dictionary:
	if current_state != State.ATTACHED_POST:
		return {"pos": player_pos, "finished": true}

	var to_anchor := target_anchor_pos - player_pos
	var dist := to_anchor.length()
	var step := PLAYER_PULL_SPEED * delta
	if dist - step <= ARRIVAL_MARGIN:
		var final_pos := target_anchor_pos - to_anchor.normalized() * ARRIVAL_MARGIN
		reset()
		return {"pos": final_pos, "finished": true}

	var new_pos := player_pos + to_anchor.normalized() * step
	return {"pos": new_pos, "finished": false}


func update_item_pull(item_pos: Vector2, player_pos: Vector2, delta: float) -> Dictionary:
	if current_state != State.PULLING_ITEM:
		return {"pos": item_pos, "finished": true}

	var to_player := player_pos - item_pos
	var dist := to_player.length()
	var step := ITEM_PULL_SPEED * delta
	if dist <= 24.0 or step >= dist:
		reset()
		return {"pos": player_pos, "finished": true}

	var new_pos := item_pos + to_player.normalized() * step
	current_tip_pos = new_pos
	return {"pos": new_pos, "finished": false}


func reset() -> void:
	current_state = State.IDLE
	current_distance = 0.0
	target_id = ""
	target_type = ""
	target_anchor_pos = Vector2.ZERO
