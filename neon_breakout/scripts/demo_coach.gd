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
