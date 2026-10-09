class_name EnergyDropView
extends Node2D
## Grafische Darstellung einer fallenden oder erzeugten Sonne/Energie.

signal clicked(drop_id: int)

var drop: GameModel.SimEnergyDrop
var _sprite: Sprite2D
var _sun_tex: Texture2D


func _ready() -> void:
	if ResourceLoader.exists("res://assets/ui/sun.png"):
		_sun_tex = load("res://assets/ui/sun.png")
		_sprite = Sprite2D.new()
		_sprite.texture = _sun_tex
		# Passe Größe an (ca. 74x74 Pixel)
		_sprite.scale = Vector2(74.0 / float(_sun_tex.get_width()), 74.0 / float(_sun_tex.get_height()))
		add_child(_sprite)
		
		# Sanfte Puls-Animation
		var t := create_tween().set_loops()
		t.tween_property(_sprite, "scale", _sprite.scale * 1.08, 0.7).set_trans(Tween.TRANS_SINE)
		t.tween_property(_sprite, "scale", _sprite.scale, 0.7).set_trans(Tween.TRANS_SINE)


func setup(p_drop: GameModel.SimEnergyDrop) -> void:
	drop = p_drop
	position = drop.position


func _process(delta: float) -> void:
	if drop:
		position = drop.position
	if _sprite:
		_sprite.rotation += delta * 0.8
	else:
		queue_redraw()


func _draw() -> void:
	if _sprite != null:
		return
	# Fallback prozedurale Sonne
	var rays := 8
	for i in range(rays):
		var angle := float(Time.get_ticks_msec()) * 0.002 + (TAU / float(rays)) * float(i)
		var p1 := Vector2(cos(angle), sin(angle)) * 22.0
		var p2 := Vector2(cos(angle), sin(angle)) * 32.0
		draw_line(p1, p2, Color("ffe600"), 3.5)

	draw_circle(Vector2.ZERO, 22.0, Color("ffd700"))
	draw_circle(Vector2.ZERO, 16.0, Color("fff176"))
	draw_circle(Vector2(-5, -5), 5.0, Color.WHITE)
