class_name WaveDirectorLogic
extends RefCounted
## Logik für Wellensteuerung, Feindaufkommen und Schwierigkeitsskalierung.


static func get_wave_config(wave: int) -> Dictionary:
	var w: int = maxi(1, wave)
	var large_asteroids: int = mini(Constants.BASE_LARGE_ASTEROIDS + w, Constants.MAX_LARGE_ASTEROIDS)
	var speed_mult: float = 1.0 + (float(w) * Constants.SPEED_FACTOR_PER_WAVE)

	var spawn_large_ufo: bool = (w >= 2)
	var spawn_small_ufo: bool = (w >= 3)
	var spawn_mine: bool = (w >= 5)

	# Nach jeweils 3 Wellen Upgrade-Auswahl
	var is_upgrade_wave: bool = (w % 3 == 0)

	return {
		"wave": w,
		"large_asteroids": large_asteroids,
		"speed_multiplier": speed_mult,
		"spawn_large_ufo": spawn_large_ufo,
		"spawn_small_ufo": spawn_small_ufo,
		"spawn_mine": spawn_mine,
		"is_upgrade_wave": is_upgrade_wave,
	}


static func compute_difficulty_score(wave: int) -> float:
	var cfg := get_wave_config(wave)
	var score: float = float(cfg["large_asteroids"]) * float(cfg["speed_multiplier"])
	if cfg["spawn_large_ufo"]:
		score += 3.0
	if cfg["spawn_small_ufo"]:
		score += 5.0
	if cfg["spawn_mine"]:
		score += 4.0
	return score


static func get_spawn_position_outside_player(
		player_pos: Vector2,
		bounds: Rect2,
		min_dist: float,
		rng: RandomNumberGenerator) -> Vector2:
	# Wählt einen Punkt entlang der 4 Bildschirmränder
	for _attempt in range(20):
		var side := rng.randi_range(0, 3)
		var pt := Vector2.ZERO
		match side:
			0: # Oben
				pt = Vector2(rng.randf_range(bounds.position.x, bounds.end.x), bounds.position.y)
			1: # Unten
				pt = Vector2(rng.randf_range(bounds.position.x, bounds.end.x), bounds.end.y)
			2: # Links
				pt = Vector2(bounds.position.x, rng.randf_range(bounds.position.y, bounds.end.y))
			3: # Rechts
				pt = Vector2(bounds.end.x, rng.randf_range(bounds.position.y, bounds.end.y))

		if pt.distance_to(player_pos) >= min_dist:
			return pt

	# Fallback: weiteste Ecke
	var corners := [
		bounds.position,
		Vector2(bounds.end.x, bounds.position.y),
		Vector2(bounds.position.x, bounds.end.y),
		bounds.end
	]
	var best_corner: Vector2 = corners[0]
	var max_d: float = -1.0
	for c in corners:
		var d: float = c.distance_to(player_pos)
		if d > max_d:
			max_d = d
			best_corner = c
	return best_corner
