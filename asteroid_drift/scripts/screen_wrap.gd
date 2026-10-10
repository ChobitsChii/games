class_name ScreenWrap
extends RefCounted
## Zentraler Helfer für Bildschirmrand-Umbruch (Wrap-around).


static func wrap_position(pos: Vector2, rect: Rect2) -> Vector2:
	var x: float = rect.position.x + fposmod(pos.x - rect.position.x, rect.size.x)
	var y: float = rect.position.y + fposmod(pos.y - rect.position.y, rect.size.y)
	return Vector2(x, y)


static func wrap_with_margin(pos: Vector2, rect: Rect2, margin: float) -> Vector2:
	var expanded := rect.grow(margin)
	var wrapped := wrap_position(pos, expanded)
	return wrapped
