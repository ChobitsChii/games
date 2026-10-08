class_name EnergyDropView
extends Node2D
## Grafische Darstellung einer fallenden oder erzeugten Sonne/Energie.

signal clicked(drop_id: int)

var drop: GameModel.SimEnergyDrop
var _rotation_angle: float = 0.0


func setup(p_drop: GameModel.SimEnergyDrop) -> void:
	drop = p_drop
	queue_redraw()


func _process(delta: float) -> void:
	_rotation_angle += delta * 1.5
	queue_redraw()


func _draw() -> void:
	# Goldene glühende Sonne mit Strahlen
	var rays := 8
	for i in range(rays):
		var angle := _rotation_angle + (TAU / float(rays)) * float(i)
		var p1 := Vector2(cos(angle), sin(angle)) * 22.0
		var p2 := Vector2(cos(angle), sin(angle)) * 32.0
		draw_line(p1, p2, Color("ffe600"), 3.5)

	# Kern
	draw_circle(Vector2.ZERO, 22.0, Color("ffd700"))
	draw_circle(Vector2.ZERO, 16.0, Color("fff176"))
	draw_circle(Vector2(-5, -5), 5.0, Color.WHITE)
