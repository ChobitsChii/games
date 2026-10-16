class_name Paddle
extends AnimatableBody2D
## Der Schläger. Steuerung per Maus, Tastatur oder Gamepad.

const SIZE := Vector2(180, 24)

@export var move_speed := 1200.0

## Wenn gesetzt, folgt der Schläger diesem Node (für automatische Tests).
var auto_target: Node2D = null

var _auto_time := 0.0
var _min_x := 0.0
var _max_x := 0.0
var _use_mouse := false
## Aufprall-Impuls (1 → 0): Schläger wird kurz flacher, breiter und heller.
var _pulse := 0.0
var _style := StyleBoxFlat.new()


func _ready() -> void:
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(12)
	_style.shadow_size = 18
	_apply_colors(accent)
	set_process(false)


func set_bounds(left: float, right: float) -> void:
	_min_x = left + SIZE.x * 0.5
	_max_x = right - SIZE.x * 0.5


## Kurzer optischer Impuls beim Ballkontakt (ändert nicht die Kollisionsform).
func pulse() -> void:
	_pulse = 1.0
	set_process(true)


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
		# Wechselnder Versatz, damit der Autopilot verschiedene Abprallwinkel trifft.
		_auto_time += delta
		var aim := auto_target.global_position.x + sin(_auto_time * 1.7) * SIZE.x * 0.4
		x = move_toward(x, aim, move_speed * delta)
	elif _use_mouse:
		x = move_toward(x, get_global_mouse_position().x, move_speed * 3.0 * delta)
	else:
		x += Input.get_axis("move_left", "move_right") * move_speed * delta
	global_position.x = clampf(x, _min_x, _max_x)


func _draw() -> void:
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	_apply_colors(accent.lerp(Color.WHITE, _pulse * 0.6))
	var size := Vector2(SIZE.x * (1.0 + 0.08 * _pulse), SIZE.y * (1.0 - 0.3 * _pulse))
	draw_style_box(_style, Rect2(-size * 0.5 + Vector2(0.0, (SIZE.y - size.y) * 0.5), size))


func _apply_colors(color: Color) -> void:
	# Leicht über 1: der Schläger leuchtet im Glow-Effekt.
	_style.bg_color = Color(color.r * 1.25, color.g * 1.25, color.b * 1.25, 1.0)
	_style.border_color = color.lightened(0.5)
	_style.shadow_color = Color(color, 0.55)
