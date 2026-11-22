class_name DemoCoach
extends RefCounted
## Tipps im Demo-Modus (reine Logik, testbar). Der Autopilot spielt, und zu passenden
## Ereignissen erscheint ein kurzer Tipp. Zwischen zwei Tipps liegt eine Pause, und
## Tipps, die noch nie gezeigt wurden, kommen zuerst.

## Ereignis -> Tipp-Schlüssel (mehrere möglich, werden reihum gezeigt).
const TIPS := {
	&"level_start": ["TIP_START", "TIP_PLAN"],
	&"paddle_edge": ["TIP_EDGE"],
	&"paddle_center": ["TIP_CENTER"],
	&"combo": ["TIP_COMBO"],
	&"wide": ["TIP_WIDE"],
	&"multi": ["TIP_MULTI"],
	&"laser": ["TIP_LASER"],
	&"sticky": ["TIP_STICKY"],
	&"slow": ["TIP_SLOW"],
	&"life": ["TIP_LIFE"],
	&"unbreakable": ["TIP_UNBREAKABLE"],
	&"life_lost": ["TIP_LIFE_LOST"],
}
const COOLDOWN := 7.0
## Maximale Trefferstelle beim Zielen (Sicherheitsabstand zum Schlägerrand).
const MAX_AIM_RATIO := 0.88
## Wie viele Abpraller (Wände, Decke, Blöcke) die Ziel-Vorschau vorausberechnet.
const MAX_SIM_BOUNCES := 4
const SWEEP_STEPS := 19

var _since_last := COOLDOWN
var _shown: Dictionary = {}
var _index: Dictionary = {}


## Zählt die Zeit seit dem letzten Tipp weiter.
func advance(delta: float) -> void:
	_since_last += delta


## Liefert den Tipp-Schlüssel für das Ereignis oder "" (zu früh, unbekannt, schon gezeigt).
func tip_for(event: StringName) -> String:
	if _since_last < COOLDOWN or not TIPS.has(event):
		return ""
	var options: Array = TIPS[event]
	var i: int = _index.get(event, 0)
	var key: String = options[i % options.size()]
	# Jeden Tipp erst zeigen, wenn er noch nicht dran war; danach nur selten wiederholen.
	if _shown.get(key, 0) > 0 and _since_last < COOLDOWN * 3.0:
		return ""
	_index[event] = i + 1
	_shown[key] = _shown.get(key, 0) + 1
	_since_last = 0.0
	return key


func times_shown(key: String) -> int:
	return _shown.get(key, 0)


## Wie weit außen trifft der Ball den Schläger? -1..1 (0 = Mitte).
static func hit_ratio(ball_x: float, paddle_x: float, paddle_width: float) -> float:
	return clampf((ball_x - paddle_x) / (paddle_width * 0.5), -1.0, 1.0)


## Ereignis für einen Schlägertreffer.
static func paddle_event(ratio: float) -> StringName:
	return &"paddle_edge" if absf(ratio) >= 0.6 else &"paddle_center"


## Wohin soll der Ball gelenkt werden? Gibt die gewünschte Trefferstelle (-1..1) zurück,
## sodass der Ball zur Mitte der verbliebenen Blöcke fliegt. `ball_x`: aktuelle Ballposition,
## `target_x`: x der Blockmitte, `reach`: Abstand in Pixeln, ab dem der volle Randtreffer nötig ist.
static func aim_ratio(ball_x: float, target_x: float, reach: float = 420.0) -> float:
	var delta := target_x - ball_x
	var strength := clampf(absf(delta) / reach, 0.0, 1.0)
	return signf(delta) * lerpf(0.15, 0.85, strength)


## Kann der Demo-Autopilot einen Umweg zu einem fallenden Power-Up machen, ohne den Ball zu verpassen?
## `ball_y`/`ball_vy`: Ballposition und vertikale Geschwindigkeit, `top_y`: Oberkante des Spielfelds,
## `paddle_y`: Höhe des Schlägers, `to_item`: Weg des Schlägers zum Item (x), `item_to_ball`: Weg vom
## Item zurück unter den Ball (x), `paddle_speed`: Schlägertempo in Pixeln pro Sekunde.
static func can_detour(ball_y: float, ball_vy: float, top_y: float, paddle_y: float,
		to_item: float, item_to_ball: float, paddle_speed: float) -> bool:
	var vy := maxf(absf(ball_vy), 1.0)
	var arrival: float
	if ball_vy < 0.0:
		# Der Ball steigt erst bis oben und kommt dann zurück.
		arrival = ((ball_y - top_y) + (paddle_y - top_y)) / vy
	else:
		arrival = (paddle_y - ball_y) / vy
	var needed := (to_item + item_to_ball) / maxf(paddle_speed, 1.0)
	return arrival > needed * 1.3 + 0.15


## Spiegelt eine horizontale Zielkoordinate `raw_x` beliebig oft an den Seitenwänden
## `[left_x, right_x]` (exakte Wand-Reflexion in O(1)).
static func fold_x(raw_x: float, left_x: float, right_x: float) -> float:
	var span := right_x - left_x
	if span <= 0.0:
		return left_x
	var period := span * 2.0
	var offset := fposmod(raw_x - left_x, period)
	return left_x + (offset if offset <= span else period - offset)


## Sagt voraus, an welcher x-Position ein fallender Ball auf Schlägerhöhe `hit_y` ankommt
## (inklusive Abprallern an linker und rechter Wand). Steigt der Ball, wird seine aktuelle x-Position zurückgegeben.
static func predict_landing_x(ball_pos: Vector2, ball_vel: Vector2, field: Rect2,
		hit_y: float, ball_radius: float = Ball.RADIUS) -> float:
	var left_x := field.position.x + ball_radius
	var right_x := field.end.x - ball_radius
	if ball_vel.y <= 1.0 or ball_pos.y >= hit_y:
		return clampf(ball_pos.x, left_x, right_x)
	var time := (hit_y - ball_pos.y) / ball_vel.y
	return fold_x(ball_pos.x + ball_vel.x * time, left_x, right_x)


## Geschätzte Zeit bis der Ball auf Schlägerhöhe `hit_y` ankommt (für Multiball-Priorität).
## Fallende Bälle haben immer Vorrang vor steigenden Bällen.
static func time_to_paddle(ball_pos: Vector2, ball_vel: Vector2, top_y: float, hit_y: float) -> float:
	if ball_vel.y > 1.0:
		return maxf((hit_y - ball_pos.y) / ball_vel.y, 0.0)
	var vy := maxf(absf(ball_vel.y), 1.0)
	return (maxf(ball_pos.y - top_y, 0.0) + maxf(hit_y - top_y, 0.0)) / vy


## Strahl-gegen-Rechteck-Schnitt für die Ziel-Vorschau. Gibt `{}` oder `{"t": float, "normal": Vector2}` zurück.
static func ray_aabb_hit(origin: Vector2, dir: Vector2, center: Vector2, half_size: Vector2) -> Dictionary:
	var min_p := center - half_size
	var max_p := center + half_size
	var t_min := -INF
	var t_max := INF
	var hit_x := true
	if absf(dir.x) < 0.00001:
		if origin.x < min_p.x or origin.x > max_p.x:
			return {}
	else:
		var tx1 := (min_p.x - origin.x) / dir.x
		var tx2 := (max_p.x - origin.x) / dir.x
		var tx_enter := minf(tx1, tx2)
		var tx_exit := maxf(tx1, tx2)
		if tx_enter > t_min:
			t_min = tx_enter
			hit_x = true
		t_max = minf(t_max, tx_exit)
	if absf(dir.y) < 0.00001:
		if origin.y < min_p.y or origin.y > max_p.y:
			return {}
	else:
		var ty1 := (min_p.y - origin.y) / dir.y
		var ty2 := (max_p.y - origin.y) / dir.y
		var ty_enter := minf(ty1, ty2)
		var ty_exit := maxf(ty1, ty2)
		if ty_enter > t_min:
			t_min = ty_enter
			hit_x = false
		t_max = minf(t_max, ty_exit)
	if t_max < t_min or t_min <= 0.001:
		return {}
	var normal := Vector2(-signf(dir.x), 0.0) if hit_x else Vector2(0.0, -signf(dir.y))
	return {"t": t_min, "normal": normal}


## Simuliert eine Schussbahn ab `origin` in Richtung `dir` mit bis zu `max_bounces` Abprallern.
## `bricks` enthält Dictionaries `{"pos": Vector2, "indestructible": bool, "hp": int}`.
## Zerstörbare Blöcke werden leicht verkleinert geprüft (garantierter Voll-Treffer statt Eck-Streifschuss),
## unzerstörbare Blöcke leicht vergrößert (Sicherheitsabstand).
static func simulate_shot(origin: Vector2, dir: Vector2, field: Rect2, bricks: Array,
		max_bounces: int = MAX_SIM_BOUNCES, ball_radius: float = Ball.RADIUS,
		brick_size: Vector2 = Brick.SIZE) -> Dictionary:
	var left_x := field.position.x + ball_radius
	var right_x := field.end.x - ball_radius
	var top_y := field.position.y + ball_radius
	var bottom_y := origin.y + 40.0
	var destr_half := brick_size * 0.5 + Vector2(ball_radius - 4.0, ball_radius - 4.0)
	var solid_half := brick_size * 0.5 + Vector2(ball_radius + 1.5, ball_radius + 1.5)
	var pos := origin
	var vel := dir.normalized()
	var hits := 0
	var first_bounces := -1
	var first_margin := 0.0
	var first_dist := INF
	var total_dist := 0.0
	var bounces_before_hit := 0
	var hit_counts: Dictionary = {}

	for _step in max_bounces + 1:
		var best_t := INF
		var best_normal := Vector2.ZERO
		var best_kind := 0 # 0 = nichts, 1 = Wand, 2 = Boden, 3 = Block
		var best_brick := -1

		if vel.x < -0.00001:
			var t_left := (left_x - pos.x) / vel.x
			if t_left > 0.001 and t_left < best_t:
				best_t = t_left
				best_normal = Vector2.RIGHT
				best_kind = 1
		elif vel.x > 0.00001:
			var t_right := (right_x - pos.x) / vel.x
			if t_right > 0.001 and t_right < best_t:
				best_t = t_right
				best_normal = Vector2.LEFT
				best_kind = 1
		if vel.y < -0.00001:
			var t_top := (top_y - pos.y) / vel.y
			if t_top > 0.001 and t_top < best_t:
				best_t = t_top
				best_normal = Vector2.DOWN
				best_kind = 1
		elif vel.y > 0.00001:
			var t_bot := (bottom_y - pos.y) / vel.y
			if t_bot > 0.001 and t_bot < best_t:
				best_t = t_bot
				best_kind = 2

		for i in bricks.size():
			var brick: Dictionary = bricks[i]
			var indestr: bool = brick["indestructible"]
			if not indestr and int(hit_counts.get(i, 0)) >= int(brick["hp"]):
				continue
			var half := solid_half if indestr else destr_half
			var hit := ray_aabb_hit(pos, vel, brick["pos"], half)
			if not hit.is_empty():
				var t_hit: float = hit["t"]
				if t_hit < best_t:
					best_t = t_hit
					best_normal = hit["normal"]
					best_kind = 3
					best_brick = i

		if best_kind == 0 or best_kind == 2:
			break
		pos += vel * best_t
		total_dist += best_t
		if best_kind == 3:
			var brick: Dictionary = bricks[best_brick]
			if not brick["indestructible"]:
				if hits == 0:
					first_bounces = bounces_before_hit
					first_dist = total_dist
					var bpos: Vector2 = brick["pos"]
					if absf(best_normal.x) > 0.5:
						first_margin = brick_size.y * 0.5 - absf(pos.y - bpos.y)
					else:
						first_margin = brick_size.x * 0.5 - absf(pos.x - bpos.x)
				hits += 1
				hit_counts[best_brick] = int(hit_counts.get(best_brick, 0)) + 1
			elif hits == 0:
				bounces_before_hit += 1
		elif hits == 0:
			bounces_before_hit += 1

		vel = BreakoutMath.enforce_min_vertical(vel.bounce(best_normal).normalized())
		pos += best_normal * 0.5

	return {
		"hits": hits,
		"first_bounces": first_bounces,
		"first_margin": first_margin,
		"first_dist": first_dist,
	}


## Berechnet die beste Trefferstelle (-1..1) auf dem Schläger, um von `(landing_x, hit_y)`
## direkt oder über Wand-/Deckenbande einen zerstörbaren Block zu treffen.
## `avoid_ratio`: Wenn nach Fehlschüssen eine Endlosschleife droht, wird dieser Winkel gemieden.
static func plan_shot(landing_x: float, hit_y: float, field: Rect2, bricks: Array,
		paddle_width: float, avoid_ratio: float = NAN) -> float:
	var half_w := maxf(paddle_width * 0.5, 1.0)
	var paddle_min_x := field.position.x + half_w
	var paddle_max_x := field.end.x - half_w
	var ratio_min := maxf(-MAX_AIM_RATIO, (landing_x - paddle_max_x) / half_w)
	var ratio_max := minf(MAX_AIM_RATIO, (landing_x - paddle_min_x) / half_w)
	if ratio_min > ratio_max:
		var fallback := clampf((landing_x - field.get_center().x) / half_w, -0.92, 0.92)
		ratio_min = fallback
		ratio_max = fallback

	var destr: Array = []
	for brick in bricks:
		if not brick["indestructible"]:
			destr.append(brick)
	if destr.is_empty():
		return clampf(0.0, ratio_min, ratio_max)

	var left_x := field.position.x + Ball.RADIUS
	var right_x := field.end.x - Ball.RADIUS
	var top_y := field.position.y + Ball.RADIUS
	var raw_candidates: Array[float] = []

	# Direkte Schüsse und Bandenschüsse (links, rechts, Decke, kombiniert) auf verbliebene Blöcke.
	var step := maxi(1, ceili(float(destr.size()) / 12.0))
	for i in range(0, destr.size(), step):
		var bpos: Vector2 = destr[i]["pos"]
		var targets: Array[Vector2] = [
			bpos,
			Vector2(2.0 * left_x - bpos.x, bpos.y),
			Vector2(2.0 * right_x - bpos.x, bpos.y),
			Vector2(bpos.x, 2.0 * top_y - bpos.y),
			Vector2(2.0 * left_x - bpos.x, 2.0 * top_y - bpos.y),
			Vector2(2.0 * right_x - bpos.x, 2.0 * top_y - bpos.y),
		]
		for target in targets:
			var dy := hit_y - target.y
			if dy <= 10.0:
				continue
			var ratio := atan2(target.x - landing_x, dy) / BreakoutMath.MAX_BOUNCE_ANGLE
			if ratio >= ratio_min and ratio <= ratio_max:
				raw_candidates.append(ratio)

	# Zusätzlicher grober Winkel-Fächer für Lücken zwischen unzerstörbaren Blöcken.
	for s in SWEEP_STEPS:
		var frac := float(s) / float(SWEEP_STEPS - 1) if SWEEP_STEPS > 1 else 0.5
		raw_candidates.append(lerpf(ratio_min, ratio_max, frac))

	raw_candidates.sort()
	var candidates: Array[float] = []
	for ratio in raw_candidates:
		if candidates.is_empty() or ratio - candidates[-1] >= 0.012:
			candidates.append(ratio)

	# Nächster zerstörbarer Block als Ausweichziel, falls kein Strahl im Horizont trifft.
	var nearest_pos: Vector2 = destr[0]["pos"]
	var nearest_dist := INF
	var origin := Vector2(landing_x, hit_y)
	for brick in destr:
		var d := origin.distance_squared_to(brick["pos"])
		if d < nearest_dist:
			nearest_dist = d
			nearest_pos = brick["pos"]
	var fallback_ratio := clampf(atan2(nearest_pos.x - landing_x, maxf(hit_y - nearest_pos.y, 10.0)) / BreakoutMath.MAX_BOUNCE_ANGLE, ratio_min, ratio_max)

	var best_ratio := fallback_ratio
	var best_score := -INF
	for ratio in candidates:
		var angle := ratio * BreakoutMath.MAX_BOUNCE_ANGLE
		var dir := Vector2(sin(angle), -cos(angle))
		var sim := simulate_shot(origin, dir, field, bricks)
		var score := _score_shot(sim, ratio, fallback_ratio, avoid_ratio)
		if score > best_score:
			best_score = score
			best_ratio = ratio
	return best_ratio


static func _score_shot(sim: Dictionary, ratio: float, fallback_ratio: float, avoid_ratio: float) -> float:
	var score := 0.0
	var hits: int = sim["hits"]
	if hits > 0:
		score = 1000.0
		score -= float(sim["first_bounces"]) * 180.0
		score += clampf(float(sim["first_margin"]), -10.0, 53.0) * 2.5
		score += float(mini(hits - 1, 3)) * 55.0
		score -= absf(ratio) * 35.0
		score -= minf(float(sim["first_dist"]), 3000.0) * 0.02
	else:
		score = -absf(ratio - fallback_ratio) * 100.0
	if not is_nan(avoid_ratio) and absf(ratio - avoid_ratio) < 0.14:
		score -= 500.0
	return score


## Wählt beim Power-Up "Klebrig" eine Schlägerposition `x`, von der aus der klebende Ball
## mit seiner festen Abflugrichtung `dir` einen zerstörbaren Block trifft.
static func plan_sticky_x(stick_offset: float, dir: Vector2, hit_y: float, field: Rect2,
		bricks: Array, paddle_width: float, current_x: float) -> float:
	var half_w := maxf(paddle_width * 0.5, 1.0)
	var min_x := field.position.x + half_w
	var max_x := field.end.x - half_w
	var best_x := clampf(current_x, min_x, max_x)
	var best_score := -INF
	var steps := 15
	for i in steps:
		var px := lerpf(min_x, max_x, float(i) / float(steps - 1))
		var ball_x := clampf(px + stick_offset, field.position.x + Ball.RADIUS, field.end.x - Ball.RADIUS)
		var sim := simulate_shot(Vector2(ball_x, hit_y), dir, field, bricks)
		var score := _score_shot(sim, 0.0, 0.0, NAN) - absf(px - current_x) * 0.08
		if score > best_score:
			best_score = score
			best_x = px
	return best_x


## Findet bei aktivem Laser eine Schlägerposition `x`, damit eine der beiden Laser-Mündungen
## unter einem freien zerstörbaren Block steht (ohne unzerstörbaren Block darunter). Sonst NAN.
static func laser_target_x(paddle_x: float, paddle_width: float, field: Rect2, bricks: Array,
		muzzle_inset: float = 14.0, brick_size: Vector2 = Brick.SIZE) -> float:
	var half_w := paddle_width * 0.5
	var min_x := field.position.x + half_w
	var max_x := field.end.x - half_w
	var half_brick_x := brick_size.x * 0.5
	var muzzle_offset := maxf(half_w - muzzle_inset, 0.0)
	var best_x := NAN
	var best_dist := INF
	for i in bricks.size():
		var brick: Dictionary = bricks[i]
		if brick["indestructible"]:
			continue
		var bpos: Vector2 = brick["pos"]
		var blocked := false
		for j in bricks.size():
			var other: Dictionary = bricks[j]
			if other["indestructible"]:
				var opos: Vector2 = other["pos"]
				if opos.y > bpos.y and absf(opos.x - bpos.x) < half_brick_x:
					blocked = true
					break
		if blocked:
			continue
		for side: float in [-1.0, 1.0]:
			var candidate_x: float = bpos.x - side * muzzle_offset
			if candidate_x < min_x or candidate_x > max_x:
				continue
			var dist := absf(candidate_x - paddle_x)
			if dist < best_dist:
				best_dist = dist
				best_x = candidate_x
	return best_x
