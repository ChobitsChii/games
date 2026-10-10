class_name AsteroidMath
extends RefCounted
## Reine mathematische Logik für Asteroiden: Generierung, Zerfall und Punkte.


static func generate_polygon(radius: float, vertex_count: int, rng: RandomNumberGenerator) -> PackedVector2Array:
	var points := PackedVector2Array()
	var n: int = clampi(vertex_count, Constants.ASTEROID_MIN_VERTICES, Constants.ASTEROID_MAX_VERTICES)
	for i in range(n):
		var angle: float = (float(i) * TAU) / float(n)
		var r: float = radius * rng.randf_range(0.75, 1.15)
		points.append(Vector2(cos(angle) * r, sin(angle) * r))
	return points


static func get_collision_radius(radius: float) -> float:
	return radius * Constants.ASTEROID_COLLISION_RADIUS_FACTOR


static func get_score_for_size(size: Constants.AsteroidSize) -> int:
	var cfg: Dictionary = Constants.ASTEROID_CONFIG.get(size, {})
	return int(cfg.get("score", 0))


static func split_asteroid(
		size: Constants.AsteroidSize,
		pos: Vector2,
		vel: Vector2,
		rng: RandomNumberGenerator) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var cfg: Dictionary = Constants.ASTEROID_CONFIG.get(size, {})
	var next_size: int = int(cfg.get("splits_into", -1))
	var split_count: int = int(cfg.get("split_count", 0))

	if next_size == -1 or split_count <= 0:
		return results

	var base_speed: float = vel.length()
	if base_speed < 10.0:
		var next_cfg: Dictionary = Constants.ASTEROID_CONFIG.get(next_size, {})
		base_speed = float(next_cfg.get("base_speed", 120.0))

	var new_speed: float = base_speed * Constants.ASTEROID_SPLIT_SPEED_FACTOR
	var base_angle: float = vel.angle() if vel.length_squared() > 1.0 else rng.randf_range(0.0, TAU)

	# Teilstücke in ±(20-60) Grad
	for i in range(split_count):
		var sign_dir: float = -1.0 if (i % 2 == 0) else 1.0
		var angle_offset: float = deg_to_rad(rng.randf_range(20.0, 60.0)) * sign_dir
		var child_angle: float = base_angle + angle_offset
		var child_vel := Vector2.RIGHT.rotated(child_angle) * new_speed
		# Leichter Positions-Offset zur Vermeidung sofortiger Überlappung
		var child_pos := pos + Vector2.RIGHT.rotated(child_angle) * (float(cfg.get("radius", 40.0)) * 0.4)

		results.append({
			"size": next_size as Constants.AsteroidSize,
			"position": child_pos,
			"velocity": child_vel,
		})

	return results
