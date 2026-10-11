class_name BaseBoss
extends CharacterBody2D
## Basisklasse für Bosse in Crypt Dash.
## Nutzt BossPatternRunner für multi-phasige Angriffsmuster.

signal boss_died(boss_name: String)

@export var boss_display_name_key: String = "BOSS_FLOOR_1"
@export var max_health: int = 50

var runner: BossPatternRunner
var current_health: int = 50
var player: Player
var floor_number: int = 1

var _hurtbox: HurtboxComponent
var _hitbox: HitboxComponent
var _attack_timer: float = 0.0


func _ready() -> void:
	z_index = 6
	collision_layer = 8
	collision_mask = 1 | 8

	runner = BossPatternRunner.new()
	_setup_phases()
	current_health = max_health

	_hurtbox = HurtboxComponent.new()
	_hurtbox.is_player = false
	_hurtbox.hit_received.connect(_on_hit_received)
	var h_shape := CollisionShape2D.new()
	var h_circle := CircleShape2D.new()
	h_circle.radius = 36.0
	h_shape.shape = h_circle
	_hurtbox.add_child(h_shape)
	add_child(_hurtbox)

	_hitbox = HitboxComponent.new()
	_hitbox.is_player = false
	_hitbox.damage = 2
	_hitbox.source_node = self
	var hit_shape := CollisionShape2D.new()
	var hit_circle := CircleShape2D.new()
	hit_circle.radius = 36.0
	hit_shape.shape = hit_circle
	_hitbox.add_child(hit_shape)
	add_child(_hitbox)

	var body_col := CollisionShape2D.new()
	var body_circle := CircleShape2D.new()
	body_circle.radius = 36.0
	body_col.shape = body_circle
	add_child(body_col)


func _setup_phases() -> void:
	# Standard-Phasen (kann in Unterklassen überschrieben werden)
	var p1 := [
		BossPhase.create("idle", 1.5, "idle"),
		BossPhase.create("charge", 2.0, "charge"),
		BossPhase.create("spiral", 2.5, "spiral_shot"),
	]
	var p2 := [
		BossPhase.create("slam", 1.5, "slam"),
		BossPhase.create("summon", 2.0, "summon"),
		BossPhase.create("spiral_fast", 2.0, "spiral_shot"),
	]
	var p3 := [
		BossPhase.create("frenzy_charge", 1.2, "charge"),
		BossPhase.create("death_spiral", 2.0, "spiral_shot"),
	]
	runner.init_boss(max_health, [p1, p2, p3])


func _physics_process(delta: float) -> void:
	if runner.state == BossPatternRunner.BossState.DEFEATED:
		return

	if player == null or not is_instance_valid(player):
		var p_nodes = get_tree().get_nodes_in_group("player")
		if not p_nodes.is_empty():
			player = p_nodes[0]

	runner.update(delta)
	_execute_current_pattern(delta)
	queue_redraw()


func _execute_current_pattern(delta: float) -> void:
	var step: BossPhase = runner.get_current_step()
	if step == null or player == null:
		return

	var dir := (player.global_position - global_position).normalized()
	_attack_timer += delta

	match step.action:
		"idle":
			velocity = Vector2.ZERO
		"charge":
			velocity = dir * 260.0
			move_and_slide()
		"slam":
			velocity = dir * 380.0
			move_and_slide()
		"spiral_shot":
			velocity = Vector2.ZERO
			if _attack_timer >= 0.4:
				_attack_timer = 0.0
				_fire_spiral()
		"summon":
			velocity = Vector2.ZERO
			if _attack_timer >= 1.8:
				_attack_timer = 0.0
				var skel := EnemySkeleton.new()
				skel.global_position = global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
				get_parent().call_deferred("add_child", skel)


func _fire_spiral() -> void:
	var bullet_count := 8
	var angle_step := TAU / bullet_count
	for i in range(bullet_count):
		var p := Projectile.new()
		p.global_position = global_position
		p.direction = Vector2.RIGHT.rotated(i * angle_step + runner.step_timer * 3.0)
		p.speed = 320.0
		p.damage = 1
		p.is_player = false
		get_parent().call_deferred("add_child", p)


func _on_hit_received(dmg: int, _knockback: Vector2, _from_player: bool) -> void:
	if runner.state == BossPatternRunner.BossState.DEFEATED:
		return
	var dead := runner.take_damage(dmg)
	current_health = runner.hp
	EventBus.enemy_damaged.emit(self, dmg)
	if dead:
		set_deferred("collision_layer", 0)
		set_deferred("collision_mask", 0)
		if _hurtbox != null and is_instance_valid(_hurtbox):
			_hurtbox.set_deferred("monitoring", false)
			_hurtbox.set_deferred("monitorable", false)
		if _hitbox != null and is_instance_valid(_hitbox):
			_hitbox.set_deferred("monitoring", false)
			_hitbox.set_deferred("monitorable", false)
		EventBus.enemy_died.emit(self, 15)
		boss_died.emit(tr(boss_display_name_key))
		queue_free()


func _draw() -> void:
	# Mächtiger Boss-Körper mit Phasen-Farbe
	var aura_color := Color("f97316") # Orange (Phase 0)
	if runner.current_phase_idx == 1:
		aura_color = Color("dc2626") # Rot (Phase 1)
	elif runner.current_phase_idx == 2:
		aura_color = Color("9333ea") # Lila (Phase 2)

	draw_circle(Vector2(0, 12), 38.0, Color(0, 0, 0, 0.4))
	draw_circle(Vector2.ZERO, 38.0, Color(aura_color.r, aura_color.g, aura_color.b, 0.3))
	draw_circle(Vector2.ZERO, 32.0, aura_color)
	draw_circle(Vector2.ZERO, 22.0, Color("0f172a"))
	# Glowing Horns / Crown
	draw_line(Vector2(-14, -20), Vector2(-22, -36), aura_color, 4.0)
	draw_line(Vector2(14, -20), Vector2(22, -36), aura_color, 4.0)
