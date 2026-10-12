extends TestCase
## Tests für Gegner-KI, Stat-Berechnungen, Projektil-Reflektion und Bumerang-Physik.

const SCOUT_SCENE := preload("res://scenes/entities/enemies/moss_scout.tscn")
const SPITTER_SCENE := preload("res://scenes/entities/enemies/thorn_spitter.tscn")
const BONE_SCENE := preload("res://scenes/entities/enemies/bone_warrior.tscn")
const BOOMERANG_SCENE := preload("res://scenes/objects/prismatic_boomerang.tscn")
const PROJECTILE_SCENE := preload("res://scenes/objects/thorn_projectile.tscn")


func test_enemy_initial_stats() -> void:
	var scout: MossScout = SCOUT_SCENE.instantiate()
	assert_eq(scout.max_health, 40, "MossScout hat 40 HP")
	assert_eq(scout.speed, 160.0, "MossScout Speed ist 160")
	scout.free()

	var spitter: ThornSpitter = SPITTER_SCENE.instantiate()
	assert_eq(spitter.max_health, 30, "ThornSpitter hat 30 HP")
	assert_eq(spitter.knockback_resistance, 0.8, "ThornSpitter hat hohe Standfestigkeit")
	spitter.free()

	var bone: BoneWarrior = BONE_SCENE.instantiate()
	assert_eq(bone.max_health, 50, "BoneWarrior hat 50 HP")
	assert_eq(bone.speed, 110.0, "BoneWarrior Speed ist 110")
	bone.free()


func test_enemy_take_damage_and_stun() -> void:
	var scout: MossScout = SCOUT_SCENE.instantiate()
	scout.global_position = Vector2(100, 100)

	scout.take_hit(15, Vector2(50, 100), 200.0)
	assert_eq(scout.current_health, 25, "HP sinkt von 40 auf 25")
	assert_true(scout.is_invulnerable, "Gegner erhält kurze i-Frames")
	assert_true(scout.velocity.x > 0, "Rückstoß schiebt Gegner nach rechts")

	# Stun anwenden
	scout.apply_stun(2.0)
	assert_true(scout.is_stunned, "Gegner ist betäubt")
	assert_eq(scout.stun_timer, 2.0, "Stun Timer ist 2.0s")

	scout.free()


func test_bone_warrior_shield_blocking() -> void:
	var bone: BoneWarrior = BONE_SCENE.instantiate()
	bone.global_position = Vector2(200, 200)
	bone.facing_direction = Vector2.LEFT # Schaut nach links

	# Treffer von links (frontal vor dem Schild)
	bone.take_hit(20, Vector2(100, 200), 300.0)
	assert_eq(bone.current_health, 50, "Frontaler Treffer wurde geblockt, HP unverändert")

	# Treffer von rechts (von hinten / im Rücken)
	bone.take_hit(20, Vector2(300, 200), 300.0)
	assert_eq(bone.current_health, 30, "Treffer im Rücken überwindet Schildblock!")

	# Betäubter Knochen-Krieger verliert Schildblock
	bone.is_invulnerable = false
	bone.apply_stun(2.5)
	assert_true(bone.is_stunned, "Knochen-Krieger ist betäubt")
	bone.take_hit(15, Vector2(100, 200), 300.0)
	assert_eq(bone.current_health, 15, "Betäubter Knochen-Krieger kann nicht blocken!")

	bone.free()


func test_thorn_projectile_reflection() -> void:
	var proj: ThornProjectile = PROJECTILE_SCENE.instantiate()
	proj.launch(Vector2.RIGHT)
	assert_eq(proj.direction, Vector2.RIGHT, "Flugrichtung ist anfangs rechts")
	assert_false(proj.is_reflected, "Anfangs nicht reflektiert")

	proj.reflect()
	assert_true(proj.is_reflected, "Nach Konter reflektiert")
	assert_eq(proj.direction, Vector2.LEFT, "Flugrichtung kehrt sich um 180 Grad um")

	proj.free()


func test_prismatic_boomerang_mechanics() -> void:
	var boom: PrismaticBoomerang = BOOMERANG_SCENE.instantiate()
	var dummy := Node2D.new()
	dummy.position = Vector2(300, 300)

	boom.launch(dummy, Vector2.UP)
	assert_eq(boom.direction, Vector2.UP, "Richtung ist nach oben")
	assert_false(boom.is_returning, "Startet im Hinflug")
	assert_eq(boom.current_speed, 540.0, "Initialgeschwindigkeit ist 540")

	boom.free()
	dummy.free()
