class_name PowerUpItem
extends Node2D
## Ein fallendes Power-Up. Der Schläger sammelt es ein, am unteren Rand verschwindet es.
## Keine Physik: Die Prüfung läuft über einfache Rechtecke.

signal collected(kind: PowerUps.Kind)

const SIZE := Vector2(76, 42)

var kind: PowerUps.Kind = PowerUps.Kind.WIDE
var paddle: Paddle
var bottom_y := 1200.0

var _time := 0.0


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_time += delta
	position.y += PowerUps.FALL_SPEED * delta
	if paddle != null and _rect().intersects(_paddle_rect()):
		collected.emit(kind)
		queue_free()
		return
	if position.y > bottom_y:
		queue_free()


func _process(_delta: float) -> void:
	queue_redraw()


func _rect() -> Rect2:
	return Rect2(position - SIZE * 0.5, SIZE)


func _paddle_rect() -> Rect2:
	var size := Vector2(paddle.width, Paddle.SIZE.y)
	return Rect2(paddle.global_position - size * 0.5, size)


func _draw() -> void:
	var color: Color = PowerUps.COLORS[kind]
	var pulse := 0.5 + 0.5 * sin(_time * 6.0)
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(18)
	style.bg_color = Color(color.r * 0.25, color.g * 0.25, color.b * 0.25, 0.95)
	style.border_color = Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 1.0)
	style.set_border_width_all(3)
	style.shadow_color = Color(color, 0.35 + 0.25 * pulse)
	style.shadow_size = 14
	draw_style_box(style, Rect2(-SIZE * 0.5, SIZE))
	_draw_icon(Color(color.r * 1.6, color.g * 1.6, color.b * 1.6, 1.0))


## Einfache Symbole aus Linien und Kreisen (sprachunabhängig, ohne Bilddateien).
func _draw_icon(c: Color) -> void:
	match kind:
		PowerUps.Kind.WIDE:
			draw_line(Vector2(-20, 0), Vector2(20, 0), c, 4.0, true)
			draw_line(Vector2(-20, -7), Vector2(-20, 7), c, 4.0, true)
			draw_line(Vector2(20, -7), Vector2(20, 7), c, 4.0, true)
		PowerUps.Kind.MULTI:
			for x in [-16, 0, 16]:
				draw_circle(Vector2(x, 0), 6.0, c)
		PowerUps.Kind.LASER:
			for x in [-12, 12]:
				draw_line(Vector2(x, 10), Vector2(x, -10), c, 4.0, true)
				draw_line(Vector2(x - 5, -4), Vector2(x, -11), c, 3.0, true)
				draw_line(Vector2(x + 5, -4), Vector2(x, -11), c, 3.0, true)
		PowerUps.Kind.STICKY:
			draw_arc(Vector2(0, -2), 11.0, PI, TAU, 18, c, 4.0, true)
			draw_line(Vector2(-11, -2), Vector2(-11, 8), c, 4.0, true)
			draw_line(Vector2(11, -2), Vector2(11, 3), c, 4.0, true)
			draw_circle(Vector2(11, 9), 4.0, c)
		PowerUps.Kind.SLOW:
			draw_arc(Vector2.ZERO, 12.0, 0.0, TAU, 24, c, 3.5, true)
			draw_line(Vector2.ZERO, Vector2(0, -8), c, 3.5, true)
			draw_line(Vector2.ZERO, Vector2(6, 3), c, 3.5, true)
		PowerUps.Kind.LIFE:
			draw_line(Vector2(-10, 0), Vector2(10, 0), c, 6.0, true)
			draw_line(Vector2(0, -10), Vector2(0, 10), c, 6.0, true)
