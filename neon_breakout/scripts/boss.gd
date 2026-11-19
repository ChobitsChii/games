class_name Boss
extends Brick
## Ein großer Boss-Block mit Lebensleiste. Er schwingt über das Spielfeld und schießt
## nach unten. Der Ball prallt an ihm ab wie an jedem Block (`Brick`).

signal shot_fired(position: Vector2, speed: float)
signal phase_changed(phase: int)

const BOSS_SIZE := Vector2(360.0, 110.0)

var tier := 1
## Wird vom Spiel gesetzt: nur im Spielzustand bewegt und schießt der Boss.
var active := false

var _time := 0.0
var _attack_timer := 0.0
var _phase := 0
var _center_x := 0.0
var _amplitude := 0.0
var _boss_hp := 1
var _boss_style := StyleBoxFlat.new()


## Baut den Boss für Stufe `boss_tier`. `center_x`/`range_x`: Mitte und Breite des Spielfelds.
func setup_boss(boss_tier: int, center_x: float, range_x: float) -> void:
	tier = boss_tier
	_boss_hp = BossRules.hp_for(tier)
	max_hp = _boss_hp
	hp = _boss_hp
	indestructible = false
	_center_x = center_x
	_amplitude = maxf((range_x - BOSS_SIZE.x) * 0.5 - 10.0, 0.0)
	_attack_timer = BossRules.attack_interval(tier, 0)
	var shape := RectangleShape2D.new()
	shape.size = BOSS_SIZE
	var collision := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if collision == null:
		collision = CollisionShape2D.new()
		collision.name = "CollisionShape2D"
		add_child(collision)
	collision.shape = shape
	collision_layer = 8
	collision_mask = 0
	set_process(true)
	_boss_style.set_corner_radius_all(26)
	_boss_style.shadow_size = 24
	queue_redraw()


func hp_fraction() -> float:
	return clampf(float(hp) / float(maxi(max_hp, 1)), 0.0, 1.0)


func phase() -> int:
	return BossRules.phase_for(hp_fraction())


## Treffer: wie `Brick.hit()`, aber ohne die Farbe nach Treffern zu wechseln.
func hit() -> bool:
	var will_break := hp - 1 <= 0
	hit_taken.emit(self, will_break)
	_flash = 1.0
	set_process(true)
	hp -= 1
	var new_phase := phase()
	if new_phase != _phase and hp > 0:
		_phase = new_phase
		phase_changed.emit(_phase)
	if hp <= 0:
		destroyed.emit(self)
		queue_free()
		return true
	queue_redraw()
	return false


func get_color() -> Color:
	return BreakoutConfig.BRICK_COLORS[3]


func _physics_process(delta: float) -> void:
	if not active:
		return
	_time += delta
	position.x = _center_x + sin(_time * TAU * BossRules.move_speed(tier, _phase)) * _amplitude
	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack_timer = BossRules.attack_interval(tier, _phase)
		for offset in BossRules.shot_offsets(BossRules.shots_for(_phase)):
			shot_fired.emit(global_position + Vector2(offset, BOSS_SIZE.y * 0.5), BossRules.shot_speed(tier))
		queue_redraw()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 5.0, 0.0)
	queue_redraw()


func _draw() -> void:
	var base := get_color()
	var pulse := 0.5 + 0.5 * sin(_time * 4.0 + _phase)
	var color := base.lerp(Color(1.0, 0.25, 0.3), _phase * 0.35).lerp(Color.WHITE, _flash * 0.6)
	_boss_style.bg_color = Color(color.r, color.g, color.b, 0.9)
	_boss_style.border_color = color.lightened(0.4)
	_boss_style.set_border_width_all(4)
	_boss_style.shadow_color = Color(color, 0.35 + 0.25 * pulse)
	draw_style_box(_boss_style, Rect2(-BOSS_SIZE * 0.5, BOSS_SIZE))
	# Augen: werden mit der Wut größer und heller.
	var eye := Color(1.6, 1.6, 1.8, 1.0)
	for side in [-1.0, 1.0]:
		var center := Vector2(side * 74.0, -6.0)
		draw_circle(center, 22.0 + 4.0 * _phase, Color(0.05, 0.02, 0.1, 0.9))
		draw_circle(center + Vector2(0.0, 2.0), 10.0 + 2.0 * _phase, eye)
	# Lebensleiste über dem Boss.
	var bar := Rect2(-BOSS_SIZE.x * 0.5, -BOSS_SIZE.y * 0.5 - 26.0, BOSS_SIZE.x, 12.0)
	draw_rect(bar, Color(0.0, 0.0, 0.0, 0.55))
	var fill := bar
	fill.size.x = bar.size.x * hp_fraction()
	draw_rect(fill, Color(1.2, 0.9, 0.3, 1.0).lerp(Color(1.4, 0.2, 0.3, 1.0), 1.0 - hp_fraction()))
	draw_rect(bar, Color(1, 1, 1, 0.6), false, 2.0)
