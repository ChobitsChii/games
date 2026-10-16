class_name Ball
extends CharacterBody2D
## Der Ball. Der Abprall wird selbst berechnet (kein Physik-Impuls), damit er sich
## präzise steuern lässt.

signal lost
## Ballkontakt: kind ist &"paddle", &"brick" oder &"wall".
signal bounced(kind: StringName, position: Vector2)

enum Mode { STUCK, FLYING, IDLE }

const RADIUS := 12.0
const TRAIL_POINTS := 22

var mode: Mode = Mode.STUCK
var speed := BreakoutMath.BASE_SPEED
var paddle: Paddle
## Fällt der Ball unter diese y-Koordinate, ist er verloren.
var bottom_y := 1200.0

var _trail: Line2D


func _ready() -> void:
	_build_trail()


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


func _process(_delta: float) -> void:
	# Schweif: neue Punkte nur im Flug, sonst schnell wieder einziehen.
	if mode == Mode.FLYING:
		_trail.add_point(global_position)
		while _trail.get_point_count() > TRAIL_POINTS:
			_trail.remove_point(0)
	elif _trail.get_point_count() > 0:
		_trail.remove_point(0)


func _follow_paddle() -> void:
	if paddle != null:
		global_position = paddle.global_position + Vector2(0.0, -(Paddle.SIZE.y * 0.5 + RADIUS + 1.0))


func _on_collision(collision: KinematicCollision2D) -> void:
	var collider := collision.get_collider()
	var normal := collision.get_normal()
	var kind := &"wall"
	if collider is Paddle and normal.y < -0.5:
		# Nur die Oberseite lenkt gezielt ab, Seitentreffer prallen normal ab.
		velocity = BreakoutMath.paddle_bounce(global_position.x, (collider as Paddle).global_position.x, Paddle.SIZE.x, speed)
		kind = &"paddle"
	else:
		velocity = velocity.bounce(normal)
		if collider is Brick:
			kind = &"brick"
			# Kann über Signale die Ballgeschwindigkeit ändern, daher vor der Normalisierung.
			(collider as Brick).hit()
	if mode == Mode.FLYING:
		velocity = BreakoutMath.enforce_min_vertical(velocity.normalized() * speed)
	bounced.emit(kind, collision.get_position())


func _build_trail() -> void:
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.z_index = -1
	_trail.width = RADIUS * 2.0
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.end_cap_mode = Line2D.LINE_CAP_ROUND
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	# Alt (Anfang der Linie) dünn und durchsichtig, neu (Ende) breit und hell.
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.0))
	curve.add_point(Vector2(1.0, 1.0))
	_trail.width_curve = curve
	var gradient := Gradient.new()
	gradient.set_color(0, Color(BreakoutConfig.PALETTE["accent"], 0.0))
	gradient.set_color(1, Color(0.8, 1.3, 1.4, 0.85))
	_trail.gradient = gradient
	add_child(_trail)


func _draw() -> void:
	var core: Color = BreakoutConfig.PALETTE["text"]
	var accent: Color = BreakoutConfig.PALETTE["accent"]
	draw_circle(Vector2.ZERO, RADIUS * 2.4, Color(accent, 0.07))
	draw_circle(Vector2.ZERO, RADIUS * 1.6, Color(accent, 0.16))
	# Werte über 1: der Ball leuchtet am stärksten.
	draw_circle(Vector2.ZERO, RADIUS, Color(core.r * 1.5, core.g * 1.5, core.b * 1.5, 1.0))
