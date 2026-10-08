class_name Ball
extends CharacterBody2D
## Der Ball. Der Abprall wird selbst berechnet (kein Physik-Impuls), damit er sich
## präzise steuern lässt.

signal lost

enum Mode { STUCK, FLYING, IDLE }

const RADIUS := 12.0

var mode: Mode = Mode.STUCK
var speed := BreakoutMath.BASE_SPEED
var paddle: Paddle
## Fällt der Ball unter diese y-Koordinate, ist er verloren.
var bottom_y := 1200.0


func stick_to_paddle() -> void:
	mode = Mode.STUCK
	velocity = Vector2.ZERO
	_follow_paddle()


func launch(direction: Vector2) -> void:
	velocity = direction.normalized() * speed
	mode = Mode.FLYING


func stop() -> void:
	mode = Mode.IDLE
	velocity = Vector2.ZERO


func _physics_process(delta: float) -> void:
	match mode:
		Mode.STUCK:
			_follow_paddle()
		Mode.FLYING:
			var collision := move_and_collide(velocity * delta)
			if collision != null:
				_on_collision(collision)
			if mode == Mode.FLYING and global_position.y > bottom_y:
				stop()
				lost.emit()


func _follow_paddle() -> void:
	if paddle != null:
		global_position = paddle.global_position + Vector2(0.0, -(Paddle.SIZE.y * 0.5 + RADIUS + 1.0))


func _on_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	var normal := collision.get_normal()
	if collider is Paddle and normal.y < -0.5:
		# Nur die Oberseite lenkt gezielt ab, Seitentreffer prallen normal ab.
		velocity = BreakoutMath.paddle_bounce(global_position.x, (collider as Paddle).global_position.x, Paddle.SIZE.x, speed)
	else:
		velocity = velocity.bounce(normal)
		if collider is Brick:
			# Kann über Signale die Ballgeschwindigkeit ändern, daher vor der Normalisierung.
			(collider as Brick).hit()
	if mode == Mode.FLYING:
		velocity = BreakoutMath.enforce_min_vertical(velocity.normalized() * speed)


func _draw() -> void:
	var accent: Color = BreakoutConfig.PALETTE["text"]
	draw_circle(Vector2.ZERO, RADIUS * 2.2, Color(accent, 0.07))
	draw_circle(Vector2.ZERO, RADIUS * 1.5, Color(accent, 0.15))
	draw_circle(Vector2.ZERO, RADIUS, accent)
