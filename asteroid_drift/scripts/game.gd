class_name Game
extends Node2D
## Hauptspiel-Controller für Asteroid Drift.

enum State {
	PLAYING,
	PAUSED,
	UPGRADE,
	GAME_OVER
}

@export var autoplay: bool = false

var state: State = State.PLAYING
var score: int = 0
var level: int = 1 # Alias / entspricht wave
var wave: int = 1
var lives: int = 3
var highscore: int = 0

var _rng := RandomNumberGenerator.new()
var _acquired_upgrades: Dictionary = {}

var _wave_in_progress: bool = false
var _wave_transition_timer: float = 0.0

# Kamera-Shake
var _shake_intensity: float = 0.0

@onready var camera: Camera2D = $Camera2D
@onready var ship: Ship = $Ship
@onready var bullets_container: Node2D = $Bullets
@onready var enemies_container: Node2D = $Enemies
@onready var drops_container: Node2D = $Drops

# UI Nodes
@onready var hud: Control = $CanvasLayer/HUD
@onready var score_label: Label = %ScoreLabel
@onready var wave_label: Label = %WaveLabel
@onready var highscore_label: Label = %HighscoreLabel
@onready var lives_label: Label = %LivesLabel
@onready var shield_progress: ProgressBar = %ShieldProgress
@onready var banner_label: Label = %BannerLabel

@onready var pause_menu: Control = %PauseMenu
@onready var game_over_menu: Control = %GameOverMenu
@onready var new_high_score_label: Label = %NewHighScoreLabel
@onready var final_score_label: Label = %FinalScoreLabel
@onready var final_wave_label: Label = %FinalWaveLabel
@onready var upgrade_picker: UpgradePicker = %UpgradePicker

var _audio_mgr: AudioManager


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	var app_theme: Theme = ThemeFactory.build(Constants.PALETTE)
	hud.theme = app_theme
	pause_menu.theme = app_theme
	game_over_menu.theme = app_theme
	upgrade_picker.theme = app_theme

	_audio_mgr = AudioManager.new()
	add_child(_audio_mgr)

	_rng.randomize()
	var seed_arg: int = _get_seed_from_cmdline()
	if seed_arg != 0:
		_rng.seed = seed_arg
		print("Asteroid Drift – Seed gesetzt: %d" % seed_arg)
	else:
		print("Asteroid Drift – Seed: %d" % _rng.seed)

	highscore = int(SaveService.get_value("highscore", "best", 0))

	# Signal-Verbindungen Schiff
	ship.fired_bullet.connect(_on_ship_fired_bullet)
	ship.took_damage.connect(_on_ship_took_damage)
	ship.destroyed.connect(_on_ship_destroyed)
	ship.hyperspace_used.connect(_on_ship_hyperspace)
	ship.autoplay = autoplay

	# UI-Buttons
	%ResumeButton.pressed.connect(_resume_game)
	%RestartButton.pressed.connect(_restart_game)
	%PauseMainMenuButton.pressed.connect(_to_main_menu)
	%RetryButton.pressed.connect(_restart_game)
	%GameOverMainMenuButton.pressed.connect(_to_main_menu)

	upgrade_picker.upgrade_selected.connect(_on_upgrade_chosen)

	_update_hud()
	_start_wave(1)


func _get_seed_from_cmdline() -> int:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--seed="):
			return int(arg.trim_prefix("--seed="))
	return 0


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			_pause_game()
			get_viewport().set_input_as_handled()
		elif state == State.PAUSED:
			_resume_game()
			get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	# Kamera-Shake abklingen
	if _shake_intensity > 0.0:
		_shake_intensity = maxf(0.0, _shake_intensity - (delta * 25.0))
		camera.offset = Vector2(
			_rng.randf_range(-_shake_intensity, _shake_intensity),
			_rng.randf_range(-_shake_intensity, _shake_intensity)
		)
	else:
		camera.offset = Vector2.ZERO

	if state != State.PLAYING:
		return

	# Prüfe ob Welle abgeschlossen ist
	if _wave_in_progress:
		var has_asteroids_or_enemies := false
		for c in enemies_container.get_children():
			if (c is Asteroid or c is UFO or c is Mine) and is_instance_valid(c):
				has_asteroids_or_enemies = true
				break

		if not has_asteroids_or_enemies:
			_wave_in_progress = false
			_wave_transition_timer = 2.0
			_show_banner(tr("MSG_WAVE_CLEARED"))
			_audio_mgr.play("win")

	elif _wave_transition_timer > 0.0:
		_wave_transition_timer -= delta
		if _wave_transition_timer <= 0.0:
			_on_wave_cleared()


func _start_wave(wave_num: int) -> void:
	wave = wave_num
	level = wave_num
	_wave_in_progress = true

	_show_banner(tr("MSG_WAVE_START_FMT") % wave)
	_audio_mgr.play("wave_start")

	var cfg := WaveDirectorLogic.get_wave_config(wave)
	var large_count: int = cfg["large_asteroids"]
	var speed_mult: float = cfg["speed_multiplier"]

	# Asteroiden spawnen
	for _i in range(large_count):
		var spawn_pos := WaveDirectorLogic.get_spawn_position_outside_player(
			ship.global_position,
			Constants.VIEWPORT_RECT,
			Constants.WAVE_MIN_SPAWN_DIST,
			_rng
		)
		var angle := _rng.randf_range(0.0, TAU)
		var base_spd: float = float(Constants.ASTEROID_CONFIG[Constants.AsteroidSize.LARGE]["base_speed"]) * speed_mult
		var vel := Vector2.RIGHT.rotated(angle) * base_spd
		_spawn_asteroid(Constants.AsteroidSize.LARGE, spawn_pos, vel)

	# UFOs spawnen
	if cfg["spawn_large_ufo"]:
		_spawn_ufo(false)
	if cfg["spawn_small_ufo"]:
		_spawn_ufo(true)

	# Mine spawnen
	if cfg["spawn_mine"]:
		_spawn_mine()

	_update_hud()


func _spawn_asteroid(sz: Constants.AsteroidSize, pos: Vector2, vel: Vector2) -> void:
	var scene: PackedScene = load("res://scenes/asteroid.tscn")
	var ast: Asteroid = scene.instantiate() as Asteroid
	ast.setup(sz, pos, vel, _rng)
	ast.destroyed.connect(_on_asteroid_destroyed)
	enemies_container.add_child(ast)


func _spawn_ufo(is_small: bool) -> void:
	var scene: PackedScene = load("res://scenes/ufo.tscn")
	var ufo: UFO = scene.instantiate() as UFO
	enemies_container.add_child(ufo)
	var spawn_y := _rng.randf_range(150.0, Constants.VIEWPORT_HEIGHT - 150.0)
	var from_left := _rng.randf() > 0.5
	var start_pos := Vector2(0.0 if from_left else Constants.VIEWPORT_WIDTH, spawn_y)
	var dir := Vector2.RIGHT if from_left else Vector2.LEFT

	ufo.setup_ufo(is_small, start_pos, dir)
	ufo.target_player = ship
	ufo.shoot_bullet.connect(_on_enemy_fired_bullet)
	ufo.destroyed.connect(_on_ufo_destroyed)


func _spawn_mine() -> void:
	var scene: PackedScene = load("res://scenes/mine.tscn")
	var mine: Mine = scene.instantiate() as Mine
	enemies_container.add_child(mine)
	var spawn_pos := WaveDirectorLogic.get_spawn_position_outside_player(
		ship.global_position,
		Constants.VIEWPORT_RECT,
		Constants.WAVE_MIN_SPAWN_DIST,
		_rng
	)
	mine.global_position = spawn_pos
	mine.target_player = ship
	mine.detonated.connect(_on_mine_detonated)


func _spawn_drop(pos: Vector2) -> void:
	var scene: PackedScene = load("res://scenes/drop.tscn")
	var drop: Drop = scene.instantiate() as Drop
	drops_container.add_child(drop)
	drop.global_position = pos
	drop.velocity = Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * 40.0
	drop.target_player = ship
	drop.magnet_radius = ship.magnet_radius
	drop.collected.connect(_on_drop_collected)


func _on_wave_cleared() -> void:
	var cfg := WaveDirectorLogic.get_wave_config(wave)
	if cfg["is_upgrade_wave"]:
		var options := UpgradeSystem.roll_random_upgrades(_acquired_upgrades, 3, _rng)
		if not options.is_empty():
			state = State.UPGRADE
			upgrade_picker.display_options(options)
			get_tree().paused = true
			return

	_start_wave(wave + 1)


func _on_upgrade_chosen(upgrade_id: String) -> void:
	var current: int = int(_acquired_upgrades.get(upgrade_id, 0))
	_acquired_upgrades[upgrade_id] = current + 1
	ship.apply_upgrades(_acquired_upgrades)
	get_tree().paused = false
	state = State.PLAYING
	_start_wave(wave + 1)


func _on_asteroid_destroyed(ast: Asteroid, splits: Array[Dictionary], pts: int) -> void:
	add_score(pts)
	_audio_mgr.play("explosion")
	_shake(4.0)

	var ast_pos := ast.global_position
	# Teilstücke erzeugen (deferred, um Flushing Queries nicht zu stören)
	call_deferred(&"_spawn_splits_and_drops", splits, ast_pos)


func _spawn_splits_and_drops(splits: Array[Dictionary], ast_pos: Vector2) -> void:
	for s in splits:
		_spawn_asteroid(s["size"], s["position"], s["velocity"])

	# 20% Chance auf Drop
	if _rng.randf() < 0.20:
		_spawn_drop(ast_pos)


func _on_ufo_destroyed(_ufo: UFO, pts: int) -> void:
	add_score(pts)
	_audio_mgr.play("explosion")
	_shake(6.0)
	_spawn_drop(_ufo.global_position)


func _on_mine_detonated(mine: Mine, pos: Vector2, radius: float, pts: int) -> void:
	add_score(pts)
	_audio_mgr.play("explosion")
	_shake(8.0)

	# Flächenschaden an Spieler falls im Radius
	if is_instance_valid(ship) and ship.global_position.distance_to(pos) <= radius:
		ship.take_hit_from_source(mine)


func _on_drop_collected(drop: Drop) -> void:
	add_score(50)
	ship.repair_shield(0.5)
	_audio_mgr.play("pickup")


func _on_ship_fired_bullet(pos: Vector2, vel: Vector2, explosive: bool) -> void:
	var scene: PackedScene = load("res://scenes/bullet.tscn")
	var b: Bullet = scene.instantiate() as Bullet
	bullets_container.add_child(b)
	b.global_position = pos
	b.velocity = vel
	b.is_enemy = false
	b.is_explosive = explosive
	_audio_mgr.play("shoot")


func _on_enemy_fired_bullet(pos: Vector2, vel: Vector2) -> void:
	var scene: PackedScene = load("res://scenes/bullet.tscn")
	var b: Bullet = scene.instantiate() as Bullet
	bullets_container.add_child(b)
	b.global_position = pos
	b.velocity = vel
	b.is_enemy = true
	_audio_mgr.play("shoot")


func _on_ship_took_damage(new_lives: int, shield_val: float) -> void:
	lives = new_lives
	if shield_val > 0.0:
		_audio_mgr.play("hit_shield")
	else:
		_audio_mgr.play("hit")
	_shake(10.0)
	_update_hud()


func _on_ship_destroyed() -> void:
	_audio_mgr.play("game_over")
	_shake(15.0)
	_game_over()


func _on_ship_hyperspace(success: bool) -> void:
	if success:
		_audio_mgr.play("hyperspace")
		_show_banner(tr("MSG_HYPERSPACE_READY"))
	else:
		_audio_mgr.play("hit")
		_shake(8.0)
		_show_banner(tr("MSG_HYPERSPACE_DANGER"))


func add_score(amount: int) -> void:
	score += amount
	if score > highscore:
		highscore = score
		SaveService.set_value("highscore", "best", highscore)
	_update_hud()


func _shake(amount: float) -> void:
	_shake_intensity = maxf(_shake_intensity, amount)


func _show_banner(text_to_show: String) -> void:
	banner_label.text = text_to_show
	banner_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(1.2)
	tween.tween_property(banner_label, "modulate:a", 0.0, 0.4)


func _update_hud() -> void:
	score_label.text = tr("HUD_SCORE_FMT") % score
	wave_label.text = tr("HUD_WAVE_FMT") % wave
	highscore_label.text = tr("HUD_HIGH_SCORE_FMT") % highscore
	lives_label.text = "%s: %d" % [tr("HUD_LIVES"), lives]
	shield_progress.max_value = ship.shield_max if is_instance_valid(ship) else 1.0
	shield_progress.value = ship.shield_current if is_instance_valid(ship) else 0.0


func _pause_game() -> void:
	state = State.PAUSED
	pause_menu.visible = true
	%ResumeButton.grab_focus()
	get_tree().paused = true


func _resume_game() -> void:
	state = State.PLAYING
	pause_menu.visible = false
	get_tree().paused = false


func _restart_game() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


func _to_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _game_over() -> void:
	state = State.GAME_OVER
	game_over_menu.visible = true
	final_score_label.text = tr("GAME_OVER_SCORE_FMT") % score
	final_wave_label.text = tr("GAME_OVER_WAVE_FMT") % wave

	if score >= highscore and score > 0:
		new_high_score_label.visible = true
	else:
		new_high_score_label.visible = false
