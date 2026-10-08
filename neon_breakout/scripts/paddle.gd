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
var _style := StyleBoxFlat.new()


func _ready() -> void:
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	_style.bg_color = accent
	_style.border_color = accent.lightened(0.5)
	_style.set_border_width_all(2)
	_style.set_corner_radius_all(12)
	_style.shadow_color = Color(accent, 0.55)
	_style.shadow_size = 16


func set_bounds(left: float, right: float) -> void:
	_min_x = left + SIZE.x * 0.5
	_max_x = right - SIZE.x * 0.5


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
	draw_style_box(_style, Rect2(-SIZE * 0.5, SIZE))
