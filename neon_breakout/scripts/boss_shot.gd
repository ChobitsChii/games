class_name BossShot
extends Node2D
## Ein Schuss des Bosses. Fällt nach unten. Trifft er den Schläger, geht ein Leben
## verloren. Keine Physik: Die Prüfung läuft über einfache Rechtecke.

signal hit_paddle

const SIZE := Vector2(22.0, 46.0)

var speed := 340.0
var paddle: Paddle
var bottom_y := 1200.0
var _time := 0.0


func _ready() -> void:
	z_index = 3


func _physics_process(delta: float) -> void:
	_time += delta
	position.y += speed * delta
	if paddle != null and _rect().intersects(_paddle_rect()):
		hit_paddle.emit()
		queue_free()
		return
	if position.y > bottom_y:
		queue_free()


func _rect() -> Rect2:
	return Rect2(global_position - SIZE * 0.5, SIZE)


func _paddle_rect() -> Rect2:
	var size := Vector2(paddle.width, Paddle.SIZE.y)
	return Rect2(paddle.global_position - size * 0.5, size)


func _draw() -> void:
	var color := Color(1.0, 0.25, 0.3)
	var wobble := 1.0 + 0.1 * sin(_time * 18.0)
	draw_circle(Vector2.ZERO, 26.0 * wobble, Color(color, 0.18))
	draw_rect(Rect2(-SIZE * 0.5, SIZE), Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 1.0))
	draw_rect(Rect2(-SIZE * 0.25, SIZE * 0.5), Color(1.6, 1.4, 1.4, 1.0))
