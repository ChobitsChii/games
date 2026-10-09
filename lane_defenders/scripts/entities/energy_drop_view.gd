class_name EnergyDropView
extends Node2D
## Grafische Darstellung einer fallenden oder erzeugten Sonne/Energie.

signal clicked(drop_id: int)

var drop: GameModel.SimEnergyDrop
var is_animating_out: bool = false
var _sprite: Sprite2D
var _sun_tex: Texture2D


func _ready() -> void:
	if ResourceLoader.exists("res://assets/ui/sun.png"):
		_sun_tex = load("res://assets/ui/sun.png")
		_sprite = Sprite2D.new()
		_sprite.texture = _sun_tex
		# Passe Größe an (ca. 76x76 Pixel)
		_sprite.scale = Vector2(76.0 / float(_sun_tex.get_width()), 76.0 / float(_sun_tex.get_height()))
		add_child(_sprite)

		# Sanfte Puls-Animation
		var t := create_tween().set_loops()
		t.tween_property(_sprite, "scale", _sprite.scale * 1.08, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_property(_sprite, "scale", _sprite.scale, 0.7).set_trans(Tween.TRANS_SINE)


func setup(p_drop: GameModel.SimEnergyDrop) -> void:
	drop = p_drop
	position = drop.position


func _process(delta: float) -> void:
	if drop and not is_animating_out:
		position = drop.position
	if _sprite:
		_sprite.rotation += delta * 0.8
	else:
		queue_redraw()


func fly_to_hud_and_free(target_pos: Vector2) -> void:
	is_animating_out = true
	var t := create_tween()
	t.tween_property(self, "position", target_pos, 0.35).set_trans(Tween.TRANS_BACK)
	t.parallel().tween_property(self, "scale", Vector2(0.2, 0.2), 0.35)
	t.finished.connect(queue_free)


func fade_out_and_free() -> void:
	is_animating_out = true
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.4)
	t.parallel().tween_property(self, "scale", Vector2(0.3, 0.3), 0.4)
	t.finished.connect(queue_free)


func _draw() -> void:
	if _sprite != null:
		return
	var rays := 8
	for i in range(rays):
		var angle := float(Time.get_ticks_msec()) * 0.002 + (TAU / float(rays)) * float(i)
		var p1 := Vector2(cos(angle), sin(angle)) * 22.0
		var p2 := Vector2(cos(angle), sin(angle)) * 32.0
		draw_line(p1, p2, Color("ffe600"), 3.5)

	draw_circle(Vector2.ZERO, 22.0, Color("ffd700"))
	draw_circle(Vector2.ZERO, 16.0, Color("fff176"))
	draw_circle(Vector2(-5, -5), 5.0, Color.WHITE)
