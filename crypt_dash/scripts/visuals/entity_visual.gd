class_name EntityVisual
extends Node2D
## Visuelles Sprite-Rig mit weichem Bodenschatten, Lauf-/Atem-Animation, Hit-Flash-Shader und optionalem HP-Balken.

var shadow_sprite: Sprite2D
var main_sprite: Sprite2D

var _base_scale: float = 1.0
var _target_size: float = 64.0
var _anim_time: float = 0.0
var _flash_timer: float = 0.0
var _flash_duration: float = 0.12
var _shader_mat: ShaderMaterial

var _show_mini_hp: bool = false
var _hp_ratio: float = 1.0
var _hp_bar_y: float = -38.0
var _hover_amplitude: float = 0.0
var _bounce_strength: float = 1.0


func setup(
		tex: Texture2D,
		target_size: float = 64.0,
		shadow_scale: Vector2 = Vector2(0.48, 0.42),
		show_mini_hp: bool = false,
		hover_amplitude: float = 0.0,
		bounce_strength: float = 1.0) -> void:
	_target_size = target_size
	_show_mini_hp = show_mini_hp
	_hover_amplitude = hover_amplitude
	_bounce_strength = bounce_strength
	_hp_bar_y = -(target_size * 0.56)
	_anim_time = randf_range(0.0, TAU)

	if shadow_sprite == null:
		shadow_sprite = Sprite2D.new()
		shadow_sprite.texture = CryptAssets.get_soft_shadow_texture()
		shadow_sprite.z_index = -1
		add_child(shadow_sprite)
	shadow_sprite.position = Vector2(0.0, target_size * 0.34)
	shadow_sprite.scale = shadow_scale * (target_size / 64.0)

	if main_sprite == null:
		main_sprite = Sprite2D.new()
		main_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		add_child(main_sprite)

	main_sprite.texture = tex
	if tex != null and tex.get_size().y > 0.0:
		_base_scale = target_size / maxf(tex.get_size().x, tex.get_size().y)
	else:
		_base_scale = 1.0
	main_sprite.scale = Vector2(_base_scale, _base_scale)
	main_sprite.position = Vector2.ZERO

	var shader := CryptAssets.get_hit_flash_shader()
	if shader != null:
		_shader_mat = ShaderMaterial.new()
		_shader_mat.shader = shader
		_shader_mat.set_shader_parameter("flash_amount", 0.0)
		main_sprite.material = _shader_mat


func set_target_size(new_size: float) -> void:
	_target_size = new_size
	_hp_bar_y = -(new_size * 0.56)
	if main_sprite != null and main_sprite.texture != null:
		var s := main_sprite.texture.get_size()
		_base_scale = new_size / maxf(s.x, s.y)
		main_sprite.scale = Vector2(_base_scale, _base_scale)
	if shadow_sprite != null:
		shadow_sprite.position = Vector2(0.0, new_size * 0.34)


func set_tint(color: Color) -> void:
	if main_sprite != null:
		main_sprite.modulate = color


func update_motion(delta: float, vel: Vector2, look_dir: Vector2) -> void:
	_anim_time += delta
	if _flash_timer > 0.0:
		_flash_timer = maxf(0.0, _flash_timer - delta)
		if _shader_mat != null:
			var t := _flash_timer / maxf(_flash_duration, 0.001)
			_shader_mat.set_shader_parameter("flash_amount", clampf(t, 0.0, 1.0))

	if main_sprite == null:
		return

	if absf(look_dir.x) > 0.08:
		main_sprite.flip_h = look_dir.x < 0.0

	var speed := vel.length()
	if speed > 15.0:
		var walk_phase := _anim_time * 13.0
		var hop := absf(sin(walk_phase)) * 4.5 * _bounce_strength
		var tilt := sin(walk_phase) * 0.085 * _bounce_strength
		var squash := 1.0 + sin(walk_phase * 2.0) * 0.055 * _bounce_strength
		main_sprite.position = Vector2(0.0, -hop - sin(_anim_time * 3.5) * _hover_amplitude)
		main_sprite.rotation = lerpf(main_sprite.rotation, tilt, minf(1.0, delta * 14.0))
		main_sprite.scale = Vector2(_base_scale * (2.0 - squash), _base_scale * squash)
	else:
		var breath := 1.0 + sin(_anim_time * 3.2) * 0.025
		var hover := sin(_anim_time * 3.5) * _hover_amplitude
		main_sprite.position = Vector2(0.0, -hover)
		main_sprite.rotation = lerpf(main_sprite.rotation, 0.0, minf(1.0, delta * 10.0))
		main_sprite.scale = Vector2(_base_scale * (2.0 - breath), _base_scale * breath)

	if _show_mini_hp and _hp_ratio < 0.999:
		queue_redraw()


func flash_hit(color: Color = Color.WHITE, duration: float = 0.13) -> void:
	_flash_duration = maxf(duration, 0.02)
	_flash_timer = _flash_duration
	if _shader_mat != null:
		_shader_mat.set_shader_parameter("flash_color", color)
		_shader_mat.set_shader_parameter("flash_amount", 1.0)


func set_hp_ratio(ratio: float) -> void:
	_hp_ratio = clampf(ratio, 0.0, 1.0)
	queue_redraw()


func _draw() -> void:
	if not _show_mini_hp or _hp_ratio >= 0.999 or _hp_ratio <= 0.0:
		return
	var bar_w := clampf(_target_size * 0.68, 34.0, 58.0)
	var bar_h := 5.0
	var top_left := Vector2(-bar_w * 0.5, _hp_bar_y)
	draw_rect(Rect2(top_left - Vector2(1.5, 1.5), Vector2(bar_w + 3.0, bar_h + 3.0)), Color(0.02, 0.04, 0.08, 0.9))
	draw_rect(Rect2(top_left, Vector2(bar_w, bar_h)), Color(0.15, 0.18, 0.25, 0.9))
	draw_rect(Rect2(top_left, Vector2(bar_w * _hp_ratio, bar_h)), Color("ef4444"))
	draw_rect(Rect2(top_left, Vector2(bar_w * _hp_ratio, 1.5)), Color("fca5a5"))
