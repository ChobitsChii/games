class_name CryptVfx
extends RefCounted
## Leichtgewichtige Partikel-, Schadenszahlen-, Nachbild- und Seelenflug-Effekte (delta-basiert, Web-kompatibel).


class TimedParticleBurst extends CPUParticles2D:
	var _life: float = 0.6

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()


class FloatingDamageText extends Node2D:
	var _label: Label
	var _vel: Vector2
	var _life: float = 0.55
	var _max_life: float = 0.55

	func setup(amount: int, is_crit: bool) -> void:
		z_index = 40
		_vel = Vector2(randf_range(-24.0, 24.0), -68.0)
		_label = Label.new()
		_label.text = "%d!" % amount if is_crit else "%d" % amount
		_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var f_size := 22 if is_crit else 16
		_label.add_theme_font_size_override("font_size", f_size)
		_label.add_theme_color_override("font_color", Color("facc15") if is_crit else Color("f8fafc"))
		_label.add_theme_color_override("font_outline_color", Color("020617"))
		_label.add_theme_constant_override("outline_size", 4)
		_label.position = Vector2(-36.0, -14.0)
		_label.custom_minimum_size = Vector2(72.0, 28.0)
		add_child(_label)
		if is_crit:
			scale = Vector2(1.25, 1.25)

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		position += _vel * delta
		_vel.y += 90.0 * delta
		var t := clampf(_life / _max_life, 0.0, 1.0)
		modulate.a = t
		scale = scale.lerp(Vector2.ONE, minf(1.0, delta * 10.0))


class DashAfterimage extends Sprite2D:
	var _life: float = 0.22
	var _max_life: float = 0.22

	func _process(delta: float) -> void:
		_life -= delta
		if _life <= 0.0:
			queue_free()
			return
		modulate.a = clampf(_life / _max_life, 0.0, 1.0) * 0.55


class HomingSoulOrb extends Sprite2D:
	var target: Node2D
	var _vel: Vector2
	var _age: float = 0.0
	var _max_age: float = 0.75

	func setup(start_vel: Vector2, p_target: Node2D) -> void:
		z_index = 25
		target = p_target
		_vel = start_vel
		texture = CryptAssets.get_glow_orb_texture()
		modulate = Color("c084fc")
		scale = Vector2(0.32, 0.32)

	func _process(delta: float) -> void:
		_age += delta
		if _age >= _max_age:
			queue_free()
			return
		if _age < 0.16 or target == null or not is_instance_valid(target):
			position += _vel * delta
			_vel *= maxf(0.0, 1.0 - delta * 4.5)
		else:
			var to_target := target.global_position - global_position
			var dist := to_target.length()
			if dist < 22.0:
				queue_free()
				return
			var speed := 420.0 + _age * 520.0
			position += (to_target / dist) * speed * delta
		modulate.a = clampf(1.0 - maxf(0.0, _age - 0.45) / 0.3, 0.0, 1.0)


static func spawn_burst(
		parent: Node,
		pos: Vector2,
		color: Color,
		count: int = 10,
		speed: float = 170.0,
		p_scale: float = 4.5) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var p := TimedParticleBurst.new()
	p.z_index = 22
	p.position = pos
	p.amount = maxi(1, count)
	p.lifetime = 0.38
	p._life = 0.55
	p.one_shot = true
	p.explosiveness = 0.92
	p.spread = 180.0
	p.direction = Vector2.RIGHT
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = speed * 0.35
	p.initial_velocity_max = speed
	p.damping_min = speed * 1.4
	p.damping_max = speed * 2.1
	p.scale_amount_min = p_scale * 0.55
	p.scale_amount_max = p_scale
	p.color = color
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.65, 1.0])
	grad.colors = PackedColorArray([color, color, Color(color.r, color.g, color.b, 0.0)])
	p.color_ramp = grad
	parent.add_child(p)
	p.emitting = true


static func spawn_damage_number(parent: Node, pos: Vector2, amount: int, is_crit: bool = false) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var node := FloatingDamageText.new()
	node.position = pos + Vector2(randf_range(-8.0, 8.0), -10.0)
	node.setup(amount, is_crit)
	parent.add_child(node)


static func spawn_dash_afterimage(
		parent: Node,
		pos: Vector2,
		tex: Texture2D,
		target_size: float,
		flip_h: bool,
		tint: Color = Color(0.25, 0.9, 1.0, 0.55)) -> void:
	if parent == null or not is_instance_valid(parent) or tex == null:
		return
	var img := DashAfterimage.new()
	img.z_index = 8
	img.position = pos
	img.texture = tex
	img.flip_h = flip_h
	img.modulate = tint
	var s := tex.get_size()
	var sc := target_size / maxf(s.x, s.y) if s.y > 0.0 else 1.0
	img.scale = Vector2(sc, sc)
	parent.add_child(img)


static func spawn_soul_orbs(parent: Node, pos: Vector2, target_player: Node2D, count: int) -> void:
	if parent == null or not is_instance_valid(parent):
		return
	var orb_count := clampi(count, 1, 5)
	for i in range(orb_count):
		var orb := HomingSoulOrb.new()
		orb.position = pos
		var ang := randf_range(0.0, TAU)
		orb.setup(Vector2(cos(ang), sin(ang)) * randf_range(90.0, 175.0), target_player)
		parent.add_child(orb)
