class_name Brick
extends StaticBody2D
## Ein Block mit 1-3 Trefferpunkten oder unzerstörbar ("X").

signal destroyed(brick: Brick)

const SIZE := Vector2(106, 36)

var max_hp := 1
var hp := 1
var indestructible := false

var _flash := 0.0
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


## Wird vom Ball aufgerufen. Gibt true zurück, wenn der Block zerstört wurde.
func hit() -> bool:
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
	if _flash == 0.0:
		set_process(false)
	queue_redraw()


func _draw() -> void:
	var base: Color = BreakoutConfig.BRICK_COLOR_UNBREAKABLE if indestructible else BreakoutConfig.BRICK_COLORS[clampi(hp, 1, 3)]
	var color := base.lerp(Color.WHITE, _flash * 0.6)
	_style.bg_color = Color(color, 0.92)
	_style.border_color = color.lightened(0.35)
	_style.set_border_width_all(2)
	_style.shadow_color = Color(color, 0.35 + _flash * 0.4)
	draw_style_box(_style, Rect2(-SIZE * 0.5, SIZE))
