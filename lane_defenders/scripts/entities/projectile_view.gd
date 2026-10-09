class_name ProjectileView
extends Node2D
## Grafische Darstellung eines fliegenden Geschosses.

var projectile: GameModel.SimProjectile
var _sprite: Sprite2D


func setup(p_proj: GameModel.SimProjectile) -> void:
	projectile = p_proj
	var tex_path := ""
	if projectile.slow_duration > 0.0:
		tex_path = "res://assets/projectiles/ice_shard.png"
	elif not projectile.is_area:
		tex_path = "res://assets/projectiles/pea.png"

	if tex_path != "" and ResourceLoader.exists(tex_path):
		var tex: Texture2D = load(tex_path)
		_sprite = Sprite2D.new()
		_sprite.texture = tex
		var s := 36.0 / float(maxi(tex.get_width(), tex.get_height()))
		_sprite.scale = Vector2(s, s)
		add_child(_sprite)

	queue_redraw()


func _process(delta: float) -> void:
	if _sprite:
		_sprite.rotation += delta * 6.0


func _draw() -> void:
	if projectile == null or _sprite != null:
		return

	if projectile.is_area:
		draw_circle(Vector2.ZERO, 16.0, Color("ab47bc"))
		draw_circle(Vector2.ZERO, 10.0, Color("e1bee7"))
	elif projectile.slow_duration > 0.0:
		draw_circle(Vector2.ZERO, 12.0, Color("80d8ff"))
		draw_circle(Vector2.ZERO, 8.0, Color.WHITE)
	else:
		draw_circle(Vector2.ZERO, 11.0, projectile.color)
		draw_circle(Vector2.ZERO, 6.0, Color.WHITE)
