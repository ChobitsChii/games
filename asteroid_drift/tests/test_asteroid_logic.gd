extends TestCase
## Testet die Asteroiden-Berechnungen, Geometrie, Zerfall und Punkte.


func test_polygon_generation() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var radius := 80.0
	var poly := AsteroidMath.generate_polygon(radius, 12, rng)

	assert_true(poly.size() == 12, "Eckpunkteanzahl stimmt")
	for pt in poly:
		var dist := pt.length()
		assert_true(dist >= radius * 0.74 and dist <= radius * 1.16, "Punktabstand innerhalb Grenzen: %f" % dist)


func test_collision_radius() -> void:
	var r := 100.0
	var col_r := AsteroidMath.get_collision_radius(r)
	assert_true(is_equal_approx(col_r, 85.0), "Kollisionsradius ist 85% des geometrischen Radius")


func test_scoring_per_size() -> void:
	assert_true(AsteroidMath.get_score_for_size(Constants.AsteroidSize.LARGE) == 20, "Groß = 20 Punkte")
	assert_true(AsteroidMath.get_score_for_size(Constants.AsteroidSize.MEDIUM) == 50, "Mittel = 50 Punkte")
	assert_true(AsteroidMath.get_score_for_size(Constants.AsteroidSize.SMALL) == 100, "Klein = 100 Punkte")


func test_asteroid_splitting() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	# Groß zerfällt in 2 Mittlere
	var vel := Vector2(100.0, 0.0)
	var pos := Vector2(500.0, 500.0)
	var large_split := AsteroidMath.split_asteroid(Constants.AsteroidSize.LARGE, pos, vel, rng)
	assert_true(large_split.size() == 2, "Großer Asteroid ergibt 2 Teile")
	assert_true(large_split[0]["size"] == Constants.AsteroidSize.MEDIUM, "Teil 1 ist mittel")
	assert_true(large_split[1]["size"] == Constants.AsteroidSize.MEDIUM, "Teil 2 ist mittel")

	var speed_child := (large_split[0]["velocity"] as Vector2).length()
	assert_true(is_equal_approx(speed_child, 130.0), "Geschwindigkeit um Faktor 1.3 gesteigert: %f" % speed_child)

	# Mittel zerfällt in 2 Kleine
	var med_split := AsteroidMath.split_asteroid(Constants.AsteroidSize.MEDIUM, pos, vel, rng)
	assert_true(med_split.size() == 2, "Mittlerer Asteroid ergibt 2 Teile")
	assert_true(med_split[0]["size"] == Constants.AsteroidSize.SMALL, "Teil 1 ist klein")
	assert_true(med_split[1]["size"] == Constants.AsteroidSize.SMALL, "Teil 2 ist klein")

	# Klein zerfällt nicht weiter
	var small_split := AsteroidMath.split_asteroid(Constants.AsteroidSize.SMALL, pos, vel, rng)
	assert_true(small_split.is_empty(), "Kleiner Asteroid zerfällt nicht weiter")
