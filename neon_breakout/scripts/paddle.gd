class_name Paddle
extends AnimatableBody2D
## Der Schläger. Steuerung per Maus, Tastatur oder Gamepad. Die Breite ist
## veränderlich (Power-Up "Breiter Schläger").

const SIZE := Vector2(180, 24)

@export var move_speed := 1200.0

## Aktuelle Breite. Ändert auch die Kollisionsform und die Bewegungsgrenzen.
var width := SIZE.x:
	set(value):
		width = value
		_apply_width()

## Wenn gesetzt, folgt der Schläger diesem Node (für automatische Tests).
var auto_target: Node2D = null

var _auto_time := 0.0
var _left := 0.0
var _right := 0.0
var _use_mouse := false
## Aufprall-Impuls (1 → 0): Schläger wird kurz flacher, breiter und heller.
var _pulse := 0.0
## Laser-Aufladung: leuchtet an den Enden, solange Laser aktiv ist.
var laser_glow := false:
	set(value):
		laser_glow = value
		queue_redraw()
var _style := StyleBoxFlat.new()
var _width_tween: Tween


func _ready() -> void:
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(12)
	_style.shadow_size = 18
	_apply_colors(accent)
	_apply_width()
	set_process(false)


func set_bounds(left: float, right: float) -> void:
	_left = left
	_right = right


## Fährt die Breite weich auf `target` (Sekunden `duration`).
func animate_width(target: float, duration: float = 0.25) -> void:
	if _width_tween != null:
		_width_tween.kill()
	_width_tween = create_tween()
	_width_tween.tween_property(self, "width", target, duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Kurzer optischer Impuls beim Ballkontakt (ändert nicht die Kollisionsform).
func pulse() -> void:
	_pulse = 1.0
	set_process(true)


## Weltposition, an der ein Laser-Schuss startet (-1 links, 1 rechts).
func muzzle(side: int) -> Vector2:
	return global_position + Vector2(side * (width * 0.5 - 14.0), -SIZE.y * 0.5)


func _process(delta: float) -> void:
	_pulse = maxf(_pulse - delta * 7.0, 0.0)
	if _pulse == 0.0:
		set_process(false)
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		_use_mouse = true
	elif event.is_action_pressed("move_left") or event.is_action_pressed("move_right"):
		_use_mouse = false


func _physics_process(delta: float) -> void:
	var x := global_position.x
	if auto_target != null:
		# Wechselnder Versatz aus zwei unregelmäßigen Wellen: verschiedene Abprallwinkel,
		# und der Ball läuft nicht in einer festen Schleife.
		_auto_time += delta
		var wobble := 0.6 * sin(_auto_time * 1.7) + 0.4 * sin(_auto_time * 0.53 + 1.3)
		var aim := auto_target.global_position.x + wobble * width * 0.42
		x = move_toward(x, aim, move_speed * delta)
	elif _use_mouse:
		x = move_toward(x, get_global_mouse_position().x, move_speed * 3.0 * delta)
	else:
		x += Input.get_axis("move_left", "move_right") * move_speed * delta
	global_position.x = clampf(x, _left + width * 0.5, _right - width * 0.5)


func _draw() -> void:
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	_apply_colors(accent.lerp(Color.WHITE, _pulse * 0.6))
	var size := Vector2(width * (1.0 + 0.08 * _pulse), SIZE.y * (1.0 - 0.3 * _pulse))
	draw_style_box(_style, Rect2(-size * 0.5 + Vector2(0.0, (SIZE.y - size.y) * 0.5), size))
	if laser_glow:
		var laser: Color = PowerUps.COLORS[PowerUps.Kind.LASER]
		for side in [-1, 1]:
			var tip := Vector2(side * (width * 0.5 - 14.0), -SIZE.y * 0.5 - 6.0)
			draw_circle(tip, 11.0, Color(laser, 0.25))
			draw_circle(tip, 6.0, Color(laser.r * 1.6, laser.g * 1.6, laser.b * 1.6, 1.0))


func _apply_width() -> void:
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision != null and collision.shape is RectangleShape2D:
		(collision.shape as RectangleShape2D).size = Vector2(width, SIZE.y)
	queue_redraw()


func _apply_colors(color: Color) -> void:
	# Leicht über 1: der Schläger leuchtet im Glow-Effekt.
	_style.bg_color = Color(color.r * 1.25, color.g * 1.25, color.b * 1.25, 1.0)
	_style.border_color = color.lightened(0.5)
	_style.shadow_color = Color(color, 0.55)
