class_name EnemyView
extends Node2D
## Grafische Darstellung eines Gegners auf dem Spielfeld.
## Nutzt hochauflösende Goblin-Sprites mit dynamischer Geh- und Sprung-Animation.

var enemy: GameModel.SimEnemy
var _sprite: Sprite2D
var _walk_cycle: float = 0.0
var _flash_timer: float = 0.0


func setup(p_enemy: GameModel.SimEnemy) -> void:
	enemy = p_enemy
	if enemy and enemy.data:
		var tex_path := "res://assets/enemies/%s.png" % enemy.data.id
		if ResourceLoader.exists(tex_path):
			var tex: Texture2D = load(tex_path)
			if _sprite == null:
				_sprite = Sprite2D.new()
				add_child(_sprite)
			_sprite.texture = tex
			_sprite.flip_h = true # Goblins schauen nach links zur Basis
			var max_dim := maxf(float(tex.get_width()), float(tex.get_height()))
			var target_size := 115.0 if not enemy.data.is_boss else 180.0
			var s := target_size / max_dim
			_sprite.scale = Vector2(s, s)
			_sprite.position = Vector2(0, -6.0)
	queue_redraw()


func play_hit_flash() -> void:
	_flash_timer = 0.12
	if _sprite:
		_sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
	queue_redraw()


func update_view(delta: float) -> void:
	if enemy == null:
		return
	_walk_cycle += delta * (8.0 if enemy.data.id == "fast_runner" else 5.5)

	var bob := sin(_walk_cycle) * 5.0
	var wobble := sin(_walk_cycle * 0.5) * 0.08
	var jump_offset := 0.0
	if enemy.is_jumping and enemy.jump_progress > 0.0:
		jump_offset = -sin(enemy.jump_progress * PI) * 55.0

	if _sprite:
		_sprite.position = Vector2(0, -6.0 + bob + jump_offset)
		_sprite.rotation = wobble

		if _flash_timer > 0.0:
			_flash_timer -= delta
			if _flash_timer <= 0.0:
				_sprite.modulate = Color.WHITE
		
		# Frost-Tönung
		if enemy.slow_timer > 0.0:
			_sprite.modulate = Color(0.5, 0.8, 1.2, 1.0)

	queue_redraw()


func _draw() -> void:
	if enemy == null or enemy.data == null:
		return

	var is_boss := enemy.data.is_boss
	# Weicher Schatten am Boden
	draw_circle(Vector2(0, 44), 36.0 if not is_boss else 65.0, Color(0, 0, 0, 0.3))

	# Fallback wenn kein Sprite geladen
	if _sprite == null:
		draw_circle(Vector2(0, -5), 32.0 if not is_boss else 60.0, enemy.data.color)

	# Frost-Ring wenn verlangsamt
	if enemy.slow_timer > 0.0:
		draw_circle(Vector2(0, 0), 40.0 if not is_boss else 75.0, Color(0.3, 0.8, 1.0, 0.25))

	# Lebensbalken (wenn beschädigt oder Boss)
	if enemy.current_hp < enemy.max_hp or is_boss:
		var bar_w := 72.0 if not is_boss else 140.0
		var bar_h := 8.0 if not is_boss else 14.0
		var bar_x := -bar_w * 0.5
		var bar_y := -60.0 if not is_boss else -100.0
		var pct := clampf(float(enemy.current_hp) / float(enemy.max_hp), 0.0, 1.0)
		draw_rect(Rect2(bar_x, bar_y, bar_w, bar_h), Color(0.1, 0.1, 0.1, 0.85), true)
		draw_rect(Rect2(bar_x + 1, bar_y + 1, (bar_w - 2) * pct, bar_h - 2), Color(0.95, 0.2, 0.2, 0.95), true)
