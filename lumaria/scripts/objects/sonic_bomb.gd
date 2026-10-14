class_name SonicBomb
extends Node2D
## Schall-Bombe (Sonic Bomb) in Lumaria:
## Ticked mit zunehmender Frequenz, explodiert nach 2.4 Sekunden
## und zerstört brüchige Wände, bricht Windschilde und fügt Gegnern Flächenschaden zu.

signal exploded(blast_pos: Vector2)

@onready var sprite: Sprite2D = $Sprite2D
@onready var blast_area: Area2D = $BlastArea

var model: BombModel
var _pulse_timer: float = 0.0


func _ready() -> void:
	model = BombModel.new()
	model.start_fuse()
	if blast_area:
		blast_area.monitoring = false
		blast_area.area_entered.connect(_on_blast_area_entered)
		blast_area.body_entered.connect(_on_blast_body_entered)


func _process(delta: float) -> void:
	if model == null:
		return

	if model.state == BombModel.State.FUSING:
		var freq := model.get_pulse_frequency()
		_pulse_timer += delta * freq
		if sprite:
			var flash: float = 1.0 + absf(sin(_pulse_timer)) * 0.8
			sprite.modulate = Color(flash, flash * 0.9, flash * 0.7)

		if model.tick(delta):
			detonate()


func detonate() -> void:
	if model.state == BombModel.State.DETONATED:
		return
	model.finish_explosion()
	exploded.emit(global_position)

	AudioManager.play_sfx("explosion", 1.1)

	# Screen Shake
	if is_inside_tree():
		var players := get_tree().get_nodes_in_group("player")
		if players.size() > 0 and players[0] is Player:
			players[0].camera_shake_requested.emit(0.6)

	# Blast-Area aktivieren
	if blast_area:
		blast_area.monitoring = true

	# Visuelle Druckwelle & Ausblendung
	if sprite:
		var tw := create_tween()
		tw.tween_property(sprite, "scale", Vector2(1.8, 1.8), 0.12)
		tw.parallel().tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5, 0.0), 0.2)
		tw.tween_callback(queue_free)
	else:
		queue_free()


func _on_blast_area_entered(area: Area2D) -> void:
	var parent_node := area.get_parent()
	if parent_node == null:
		return

	if parent_node.has_method("shatter"):
		parent_node.shatter()


func _on_blast_body_entered(body: Node2D) -> void:
	# 1. Brüchige Wand sprengen
	if body is CrackedWall:
		body.shatter()
		return

	# 2. Boss Zephyros: Windschild sprengen & abstürzen lassen
	if body.has_method("bomb_blast_hit"):
		body.bomb_blast_hit()
		return

	# 3. Kristallschalter umschalten
	if body is SwitchCrystal:
		body.toggle()
		return

	# 4. Standard-Gegner: Hoher Explosionsschaden
	if body is EnemyBase:
		var dir := (body.global_position - global_position).normalized()
		body.take_hit(BombModel.ENEMY_DAMAGE, global_position, 480.0)
		body.apply_stun(2.0)
		return

	# 5. Spieler (falls zu nah an der Bombe)
	if body is Player:
		var p: Player = body as Player
		if p.current_state != Player.State.ROLL:
			p.take_damage(BombModel.PLAYER_DAMAGE_QUARTERS, global_position)
