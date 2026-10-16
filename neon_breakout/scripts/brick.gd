class_name Brick
extends StaticBody2D
## Ein Block mit 1-3 Trefferpunkten oder unzerstörbar ("X").

## Bei jedem Treffer. `will_break` ist wahr, wenn dieser Treffer den Block zerstört.
signal hit_taken(brick: Brick, will_break: bool)
signal destroyed(brick: Brick)

const SIZE := Vector2(106, 36)

var max_hp := 1
var hp := 1
var indestructible := false

var _flash := 0.0
## Aufpoppen beim Levelstart (0 = unsichtbar, 1 = fertig). Betrifft nur die Zeichnung.
var _appear := 1.0
var _style := StyleBoxFlat.new()


func _ready() -> void:
	_style.set_corner_radius_all(9)
	_style.shadow_size = 10
	set_process(false)


## kind: "1".."3" oder "X".
func setup(kind: String) -> void:
	indestructible = kind == "X"
	max_hp = 0 if indestructible else int(kind)
	hp = max_hp
	queue_redraw()


## Lässt den Block nach `delay` Sekunden aufpoppen.
func appear(delay: float) -> void:
	_appear = 0.0
	set_process(true)
	var tween := create_tween()
	tween.tween_property(self, "_appear", 1.0, 0.4).set_delay(delay).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Aktuelle Blockfarbe (für Partikel).
func get_color() -> Color:
	if indestructible:
		return BreakoutConfig.BRICK_COLOR_UNBREAKABLE
	return BreakoutConfig.BRICK_COLORS[clampi(maxi(hp, 1), 1, 3)]


## Wird vom Ball aufgerufen. Gibt true zurück, wenn der Block zerstört wurde.
func hit() -> bool:
	var will_break := not indestructible and hp - 1 <= 0
	hit_taken.emit(self, will_break)
	_flash = 1.0
	set_process(true)
	if indestructible:
		return false
	hp -= 1
	if hp <= 0:
		destroyed.emit(self)
		queue_free()
		return true
	queue_redraw()
	return false


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta * 5.0, 0.0)
	if _flash == 0.0 and _appear >= 1.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var base := get_color()
	var color := base.lerp(Color.WHITE, _flash * 0.6)
	var scale_factor := maxf(_appear, 0.001)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * scale_factor)
	_style.bg_color = Color(color, 0.92 * clampf(_appear * 1.5, 0.0, 1.0))
	_style.border_color = color.lightened(0.35)
	_style.set_border_width_all(2)
	_style.shadow_color = Color(color, (0.35 + _flash * 0.4) * clampf(_appear, 0.0, 1.0))
	draw_style_box(_style, Rect2(-SIZE * 0.5, SIZE))
