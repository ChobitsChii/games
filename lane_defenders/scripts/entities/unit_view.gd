class_name UnitView
extends Node2D
## Grafische Darstellung einer Einheit auf dem Spielfeld.
## Nutzt hochauflösende Flat-Cartoon-Sprites und sanfte Idle-/Angriffs-Tweens.

var unit: GridModel.GridUnit
var _sprite: Sprite2D
var _tween: Tween


func _ready() -> void:
	_start_idle_tween()


func setup(p_unit: GridModel.GridUnit) -> void:
	unit = p_unit
	if unit and unit.unit_data:
		var tex_path := "res://assets/units/%s.png" % unit.unit_data.id
		if ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path)
			if _sprite == null:
				_sprite = Sprite2D.new()
				add_child(_sprite)
			_sprite.texture = tex
			var max_dim := maxf(float(tex.get_width()), float(tex.get_height()))
			var target_size := 105.0
			var s := target_size / max_dim
			_sprite.scale = Vector2(s, s)
			_sprite.position = Vector2(0, -6.0)
	queue_redraw()


func play_attack_animation() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	# Rückstoß beim Schuss
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(0.85, 1.15), 0.08)
	t.tween_property(self, "scale", Vector2(1.1, 0.9), 0.1)
	t.tween_property(self, "scale", Vector2.ONE, 0.12)
	t.finished.connect(_start_idle_tween)


func _start_idle_tween() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_loops()
	# Sanftes Wippen/Atmen
	_tween.tween_property(self, "scale", Vector2(1.03, 0.97), 0.8).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(self, "scale", Vector2(0.97, 1.03), 0.8).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	if unit == null or unit.unit_data == null:
		return

	# Weicher Schatten
	draw_circle(Vector2(0, 48), 42.0, Color(0, 0, 0, 0.28))

	# Wenn kein Sprite geladen werden konnte: Fallback-Form
	if _sprite == null:
		draw_circle(Vector2(0, -5), 38.0, unit.unit_data.color)

	# Lebenspunkte-Balken (nur anzeigen wenn beschädigt)
	if unit.current_hp < unit.max_hp and unit.max_hp > 0:
		var bar_w := 76.0
		var bar_h := 8.0
		var bar_x := -bar_w * 0.5
		var bar_y := -58.0
		var pct := clampf(float(unit.current_hp) / float(unit.max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.8), true)
		draw_rect(Rect2(bar_x + 1, bar_y + 1, (bar_w - 2) * pct, bar_h - 2), Color(0.2, 0.85, 0.3, 0.9), true)
