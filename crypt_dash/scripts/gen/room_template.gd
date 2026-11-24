class_name RoomTemplate
extends Node2D
## Vorlage für einen Raum in Crypt Dash (20 x 11 Kacheln à 64px = 1280 x 704 px).
## Rendert 2.5D-Steinwände, Etagen-Bodentexturen, animierte Eisentore, Kohlebecken mit echtem PointLight2D und Partikeln.

signal room_cleared
signal door_entered(direction: String)

var room_data: DungeonGenerator.DungeonRoom
var floor_num: int = 1
var is_cleared: bool = false
var spawned_enemies: Array[Node2D] = []

var _door_barriers: Dictionary = {}
var _door_triggers: Dictionary = {}
var _floor_theme: Dictionary = {}
var _floor_tex: Texture2D
var _wall_tex: Texture2D
var _door_arch_tex: Texture2D
var _brazier_tex: Texture2D

var _time: float = 0.0
var _door_open_anim: float = 0.0
var _brazier_lights: Array[PointLight2D] = []
var _brazier_positions: Array[Vector2] = []
var _floor_decals: Array[Dictionary] = []


class FloorExitNode extends Area2D:
	var floor_num: int = 1
	var triggered: bool = false
	var _time: float = 0.0
	var _sprite: Sprite2D
	var _light: PointLight2D
	var label: Label

	func _init() -> void:
		z_index = 2
		collision_layer = 0
		collision_mask = 2 # Spieler

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0
		shape.shape = circle
		add_child(shape)

		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var tex := CryptAssets.get_texture("res://assets/props/floor_portal.png")
		if tex != null:
			_sprite.texture = tex
			var s := 108.0 / maxf(tex.get_size().x, tex.get_size().y)
			_sprite.scale = Vector2(s, s)
		add_child(_sprite)

		_light = PointLight2D.new()
		_light.texture = CryptAssets.get_radial_light_texture()
		_light.color = Color("22d3ee")
		_light.energy = 1.45
		_light.texture_scale = 2.3
		add_child(_light)

		var particles := CPUParticles2D.new()
		particles.amount = 10
		particles.lifetime = 1.4
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 32.0
		particles.gravity = Vector2(0.0, -35.0)
		particles.initial_velocity_min = 8.0
		particles.initial_velocity_max = 22.0
		particles.scale_amount_min = 2.5
		particles.scale_amount_max = 5.0
		particles.color = Color("67e8f9")
		add_child(particles)

		label = Label.new()
		label.text = "ROOM_FLOOR_EXIT"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("67e8f9"))
		label.add_theme_color_override("font_outline_color", Color("020617"))
		label.add_theme_constant_override("outline_size", 4)
		label.position = Vector2(-130.0, -78.0)
		label.custom_minimum_size = Vector2(260.0, 26.0)
		add_child(label)

	func _process(delta: float) -> void:
		_time += delta
		if _sprite != null:
			_sprite.rotation = _time * 0.45
		if _light != null:
			_light.energy = 1.35 + sin(_time * 4.2) * 0.2
		queue_redraw()

	func _draw() -> void:
		var pulse := sin(_time * 3.8) * 0.12 + 0.88
		draw_circle(Vector2.ZERO, 56.0 * pulse, Color(0.13, 0.83, 0.93, 0.14))


class PedestalNode extends Area2D:
	var collected: bool = false
	var _time: float = 0.0
	var _sprite: Sprite2D
	var _shadow: Sprite2D
	var _light: PointLight2D
	var label: Label

	func _init() -> void:
		z_index = 2
		collision_layer = 0
		collision_mask = 2 # Spieler

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0
		shape.shape = circle
		add_child(shape)

		_shadow = Sprite2D.new()
		_shadow.texture = CryptAssets.get_soft_shadow_texture()
		_shadow.position = Vector2(0.0, 28.0)
		_shadow.scale = Vector2(0.85, 0.72)
		add_child(_shadow)

		_sprite = Sprite2D.new()
		_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var tex := CryptAssets.get_texture("res://assets/props/pedestal_chest.png")
		if tex != null:
			_sprite.texture = tex
			var s := 88.0 / maxf(tex.get_size().x, tex.get_size().y)
			_sprite.scale = Vector2(s, s)
		add_child(_sprite)

		_light = PointLight2D.new()
		_light.texture = CryptAssets.get_radial_light_texture()
		_light.color = Color("fbbf24")
		_light.energy = 1.25
		_light.texture_scale = 2.0
		add_child(_light)

		var particles := CPUParticles2D.new()
		particles.amount = 8
		particles.lifetime = 1.5
		particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		particles.emission_sphere_radius = 28.0
		particles.gravity = Vector2(0.0, -28.0)
		particles.initial_velocity_min = 6.0
		particles.initial_velocity_max = 18.0
		particles.scale_amount_min = 2.0
		particles.scale_amount_max = 4.2
		particles.color = Color("fde047")
		add_child(particles)

		label = Label.new()
		label.text = "ROOM_ALTAR_PEDESTAL"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("fde047"))
		label.add_theme_color_override("font_outline_color", Color("020617"))
		label.add_theme_constant_override("outline_size", 4)
		label.position = Vector2(-130.0, -78.0)
		label.custom_minimum_size = Vector2(260.0, 26.0)
		add_child(label)

	func _process(delta: float) -> void:
		_time += delta
		var bob := sin(_time * 2.8) * 3.5
		if _sprite != null:
			_sprite.position = Vector2(0.0, bob)
		if _light != null:
			_light.energy = 1.15 + sin(_time * 3.5) * 0.16
		queue_redraw()

	func _draw() -> void:
		var pulse := sin(_time * 3.0) * 0.1 + 0.9
		draw_circle(Vector2.ZERO, 52.0 * pulse, Color(0.98, 0.75, 0.14, 0.14))


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)


func _on_child_entered(node: Node) -> void:
	if (node is BaseEnemy or node is BaseBoss) and not spawned_enemies.has(node):
		spawned_enemies.append(node)


func setup_room(p_room: DungeonGenerator.DungeonRoom, p_floor_num: int = 1) -> void:
	z_index = -10
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	room_data = p_room
	floor_num = maxi(1, p_floor_num)
	is_cleared = p_room.cleared
	_door_open_anim = 1.0 if is_cleared else 0.0
	_floor_theme = CryptAssets.get_floor_theme(floor_num)
	_floor_tex = CryptAssets.get_texture(str(_floor_theme["floor_tex"]))
	_wall_tex = CryptAssets.get_texture(str(_floor_theme["wall_tex"]))
	_door_arch_tex = CryptAssets.get_texture("res://assets/props/door_arch.png")
	_brazier_tex = CryptAssets.get_texture("res://assets/props/brazier.png")

	_generate_floor_decals()
	_build_room_geometry()
	_build_decorative_props()

	if is_cleared:
		_unlock_doors()
		if room_data.type == DungeonGenerator.RoomType.BOSS:
			_spawn_floor_exit()
		elif room_data.type == DungeonGenerator.RoomType.TREASURE and not room_data.chest_opened:
			_spawn_pedestal()
	else:
		_spawn_room_contents()
	queue_redraw()


func _generate_floor_decals() -> void:
	_floor_decals.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(room_data.coords) + floor_num * 313
	var w := float(CryptDashConfig.ROOM_PIXEL_WIDTH)
	var h := float(CryptDashConfig.ROOM_PIXEL_HEIGHT)
	for i in range(12):
		_floor_decals.append({
			"pos": Vector2(rng.randf_range(110.0, w - 110.0), rng.randf_range(110.0, h - 110.0)),
			"radius": rng.randf_range(14.0, 42.0),
			"kind": rng.randi_range(0, 2),
			"angle": rng.randf_range(0.0, TAU),
		})


func _build_room_geometry() -> void:
	var static_body := StaticBody2D.new()
	static_body.collision_layer = 1
	add_child(static_body)

	var w := float(CryptDashConfig.ROOM_PIXEL_WIDTH)  # 1280
	var h := float(CryptDashConfig.ROOM_PIXEL_HEIGHT) # 704
	var wall_thick := 64.0
	var door_width := 128.0

	# Oben
	_add_wall_box(static_body, Vector2((w - door_width) / 4.0, wall_thick / 2.0), Vector2((w - door_width) / 2.0, wall_thick))
	_add_wall_box(static_body, Vector2(w - (w - door_width) / 4.0, wall_thick / 2.0), Vector2((w - door_width) / 2.0, wall_thick))
	# Unten
	_add_wall_box(static_body, Vector2((w - door_width) / 4.0, h - wall_thick / 2.0), Vector2((w - door_width) / 2.0, wall_thick))
	_add_wall_box(static_body, Vector2(w - (w - door_width) / 4.0, h - wall_thick / 2.0), Vector2((w - door_width) / 2.0, wall_thick))
	# Links
	_add_wall_box(static_body, Vector2(wall_thick / 2.0, (h - door_width) / 4.0), Vector2(wall_thick, (h - door_width) / 2.0))
	_add_wall_box(static_body, Vector2(wall_thick / 2.0, h - (h - door_width) / 4.0), Vector2(wall_thick, (h - door_width) / 2.0))
	# Rechts
	_add_wall_box(static_body, Vector2(w - wall_thick / 2.0, (h - door_width) / 4.0), Vector2(wall_thick, (h - door_width) / 2.0))
	_add_wall_box(static_body, Vector2(w - wall_thick / 2.0, h - (h - door_width) / 4.0), Vector2(wall_thick, (h - door_width) / 2.0))

	if not room_data.doors["north"]:
		_add_wall_box(static_body, Vector2(w / 2.0, wall_thick / 2.0), Vector2(door_width, wall_thick))
	else:
		_add_door("north", Vector2(w / 2.0, wall_thick / 2.0), Vector2(door_width, wall_thick))

	if not room_data.doors["south"]:
		_add_wall_box(static_body, Vector2(w / 2.0, h - wall_thick / 2.0), Vector2(door_width, wall_thick))
	else:
		_add_door("south", Vector2(w / 2.0, h - wall_thick / 2.0), Vector2(door_width, wall_thick))

	if not room_data.doors["west"]:
		_add_wall_box(static_body, Vector2(wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))
	else:
		_add_door("west", Vector2(wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))

	if not room_data.doors["east"]:
		_add_wall_box(static_body, Vector2(w - wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))
	else:
		_add_door("east", Vector2(w - wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))


func _build_decorative_props() -> void:
	var w := float(CryptDashConfig.ROOM_PIXEL_WIDTH)
	var h := float(CryptDashConfig.ROOM_PIXEL_HEIGHT)

	# 4 Ecken-Kohlebecken mit Schatten, PointLight2D & Glut-Partikeln
	_brazier_lights.clear()
	_brazier_positions = [
		Vector2(124.0, 126.0),
		Vector2(w - 124.0, 126.0),
		Vector2(124.0, h - 122.0),
		Vector2(w - 124.0, h - 122.0),
	]
	var torch_col: Color = _floor_theme.get("torch_color", Color("ff9848"))

	for pos: Vector2 in _brazier_positions:
		var holder := Node2D.new()
		holder.position = pos
		holder.z_index = 2
		add_child(holder)

		var sh := Sprite2D.new()
		sh.texture = CryptAssets.get_soft_shadow_texture()
		sh.position = Vector2(0.0, 22.0)
		sh.scale = Vector2(0.58, 0.5)
		holder.add_child(sh)

		if _brazier_tex != null:
			var spr := Sprite2D.new()
			spr.texture = _brazier_tex
			spr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
			var s := 62.0 / maxf(_brazier_tex.get_size().x, _brazier_tex.get_size().y)
			spr.scale = Vector2(s, s)
			holder.add_child(spr)

		var glow_spr := Sprite2D.new()
		glow_spr.texture = CryptAssets.get_glow_orb_texture()
		glow_spr.position = Vector2(0.0, -8.0)
		glow_spr.scale = Vector2(0.9, 0.75)
		glow_spr.modulate = Color(torch_col.r, torch_col.g, torch_col.b, 0.52)
		holder.add_child(glow_spr)

		var light := PointLight2D.new()
		light.texture = CryptAssets.get_radial_light_texture()
		light.color = torch_col
		light.energy = 1.68
		light.texture_scale = 3.25
		light.position = Vector2(0.0, -6.0)
		holder.add_child(light)
		_brazier_lights.append(light)

		var embers := CPUParticles2D.new()
		embers.position = Vector2(0.0, -10.0)
		embers.amount = 7
		embers.lifetime = 1.15
		embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
		embers.emission_sphere_radius = 12.0
		embers.gravity = Vector2(0.0, -34.0)
		embers.initial_velocity_min = 8.0
		embers.initial_velocity_max = 22.0
		embers.scale_amount_min = 2.0
		embers.scale_amount_max = 3.8
		embers.color = Color(torch_col.r, minf(1.0, torch_col.g + 0.15), 0.35, 0.9)
		holder.add_child(embers)

	# Gedämpfte Raum-Staubpartikel
	var dust := CPUParticles2D.new()
	dust.position = Vector2(w * 0.5, h * 0.5)
	dust.z_index = 4
	dust.amount = 18
	dust.lifetime = 4.0
	dust.preprocess = 1.5
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(540.0, 260.0)
	dust.gravity = Vector2(4.0, -6.0)
	dust.initial_velocity_min = 3.0
	dust.initial_velocity_max = 10.0
	dust.scale_amount_min = 1.5
	dust.scale_amount_max = 3.0
	var acc: Color = _floor_theme.get("accent", Color("22d3ee"))
	dust.color = Color(acc.r, acc.g, acc.b, 0.24)
	add_child(dust)

	# Steinerne Torbögen über aktiven Türen
	if _door_arch_tex != null:
		var door_specs := [
			{"dir": "north", "pos": Vector2(w * 0.5, 30.0), "rot": 0.0},
			{"dir": "south", "pos": Vector2(w * 0.5, h - 30.0), "rot": PI},
			{"dir": "west", "pos": Vector2(30.0, h * 0.5), "rot": -PI * 0.5},
			{"dir": "east", "pos": Vector2(w - 30.0, h * 0.5), "rot": PI * 0.5},
		]
		for spec in door_specs:
			if room_data.doors.get(spec["dir"], false):
				var arch := Sprite2D.new()
				arch.texture = _door_arch_tex
				arch.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
				arch.position = spec["pos"]
				arch.rotation = spec["rot"]
				arch.z_index = 3
				arch.scale = Vector2(0.84, 0.42)
				arch.modulate = Color(0.95, 0.96, 1.0, 0.96)
				add_child(arch)


func _add_wall_box(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
	parent.add_child(shape)


func _add_door(dir: String, pos: Vector2, size: Vector2) -> void:
	if not is_cleared:
		var barrier_body := StaticBody2D.new()
		barrier_body.collision_layer = 1
		var barrier_shape := CollisionShape2D.new()
		var barrier_rect := RectangleShape2D.new()
		barrier_rect.size = size
		barrier_shape.shape = barrier_rect
		barrier_body.add_child(barrier_shape)
		barrier_body.position = pos
		add_child(barrier_body)
		_door_barriers[dir] = barrier_body

	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2 # Spieler
	var trigger_shape := CollisionShape2D.new()
	var trigger_rect := RectangleShape2D.new()
	var trigger_size := size
	var trigger_pos := pos
	match dir:
		"north":
			trigger_size = Vector2(size.x, size.y + 36.0)
			trigger_pos = Vector2(pos.x, pos.y + 18.0)
		"south":
			trigger_size = Vector2(size.x, size.y + 36.0)
			trigger_pos = Vector2(pos.x, pos.y - 18.0)
		"west":
			trigger_size = Vector2(size.x + 36.0, size.y)
			trigger_pos = Vector2(pos.x + 18.0, pos.y)
		"east":
			trigger_size = Vector2(size.x + 36.0, size.y)
			trigger_pos = Vector2(pos.x - 18.0, pos.y)

	trigger_rect.size = trigger_size
	trigger_shape.shape = trigger_rect
	area.add_child(trigger_shape)
	area.position = trigger_pos
	area.body_entered.connect(func(body: Node2D) -> void:
		if is_cleared and body is Player:
			door_entered.emit.call_deferred(dir)
	)
	add_child(area)
	_door_triggers[dir] = area


func _unlock_doors() -> void:
	for dir in _door_barriers:
		var barrier_body: StaticBody2D = _door_barriers[dir]
		if is_instance_valid(barrier_body):
			barrier_body.queue_free()
	_door_barriers.clear()
	queue_redraw()


func _mark_room_cleared() -> void:
	if is_cleared:
		return
	is_cleared = true
	room_data.cleared = true
	_unlock_doors()
	room_cleared.emit()
	EventBus.room_cleared.emit(room_data.coords)
	queue_redraw()

	if room_data.type == DungeonGenerator.RoomType.BOSS:
		_spawn_floor_exit()


func _spawn_room_contents() -> void:
	if room_data.type == DungeonGenerator.RoomType.START:
		_mark_room_cleared()
		return

	if room_data.type == DungeonGenerator.RoomType.TREASURE:
		_mark_room_cleared()
		if not room_data.chest_opened:
			_spawn_pedestal()
		return

	if room_data.type == DungeonGenerator.RoomType.BOSS:
		var boss := BaseBoss.new()
		boss.floor_number = floor_num
		boss.boss_display_name_key = "BOSS_FLOOR_%d" % clampi(floor_num, 1, 3)
		boss.max_health = 50 + (floor_num - 1) * 25
		boss.global_position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
		boss.boss_died.connect(func(_name: String) -> void:
			_mark_room_cleared.call_deferred()
		)
		add_child(boss)
		spawned_enemies.append(boss)
		return

	# Standard-Kampfraum
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var count := 3 + room_data.template_index
	for i in range(count):
		var en: BaseEnemy
		var roll := randf()
		if roll < 0.4:
			en = EnemySkeleton.new()
		elif roll < 0.7:
			en = EnemyArcher.new()
		elif roll < 0.85:
			en = EnemySlime.new()
		elif roll < 0.95:
			en = EnemyGhost.new()
		else:
			en = EnemySummoner.new()

		var angle := randf_range(0, TAU)
		var dist := randf_range(110, 290)
		en.global_position = center + Vector2(cos(angle), sin(angle)) * dist
		add_child(en)
		spawned_enemies.append(en)


func _process(delta: float) -> void:
	_time += delta
	var target_open := 1.0 if is_cleared else 0.0
	if not is_equal_approx(_door_open_anim, target_open):
		_door_open_anim = move_toward(_door_open_anim, target_open, delta * 4.5)
		queue_redraw()
	elif room_data != null:
		queue_redraw()

	for i in range(_brazier_lights.size()):
		var light := _brazier_lights[i]
		if is_instance_valid(light):
			var phase := _time * 5.2 + float(i) * 1.7
			light.energy = 1.62 + sin(phase) * 0.14 + cos(phase * 2.3) * 0.07


func _physics_process(_delta: float) -> void:
	if not is_cleared:
		var all_dead := true
		for en in spawned_enemies:
			if is_instance_valid(en) and not en.is_queued_for_deletion():
				if en is BaseEnemy and (en as BaseEnemy).state == BaseEnemy.State.DEAD:
					continue
				if en is BaseBoss and (en as BaseBoss).runner.state == BossPatternRunner.BossState.DEFEATED:
					continue
				all_dead = false
				break
		if all_dead and not spawned_enemies.is_empty():
			_mark_room_cleared()
	else:
		for dir: String in _door_triggers:
			var area: Area2D = _door_triggers[dir]
			if is_instance_valid(area):
				for body in area.get_overlapping_bodies():
					if body is Player:
						door_entered.emit.call_deferred(dir)
						return


func _spawn_pedestal() -> void:
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var pedestal := PedestalNode.new()
	pedestal.position = center
	pedestal.body_entered.connect(func(body: Node2D) -> void:
		if not pedestal.collected and body is Player and body.global_position.distance_to(pedestal.global_position) <= 96.0:
			pedestal.collected = true
			room_data.chest_opened = true
			pedestal.set_deferred("monitoring", false)
			EventBus.item_collected.emit.call_deferred("treasure_opened")
			pedestal.queue_free()
	)
	add_child(pedestal)


func _spawn_floor_exit() -> void:
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var exit_node := FloorExitNode.new()
	exit_node.floor_num = floor_num
	exit_node.position = center
	exit_node.body_entered.connect(func(body: Node2D) -> void:
		if not exit_node.triggered and body is Player and body.global_position.distance_to(exit_node.global_position) <= 96.0:
			exit_node.triggered = true
			exit_node.set_deferred("monitoring", false)
			EventBus.floor_completed.emit.call_deferred(floor_num)
	)
	add_child(exit_node)


func _draw() -> void:
	if room_data == null:
		return
	var w := float(CryptDashConfig.ROOM_PIXEL_WIDTH)
	var h := float(CryptDashConfig.ROOM_PIXEL_HEIGHT)
	var wall_thick := 64.0
	var acc: Color = _floor_theme.get("accent", Color("22d3ee"))

	# 1. Dunkles Katakomben-Mauerwerk außerhalb des Raumes (kein schwarzes Nichts!)
	draw_rect(Rect2(-420.0, -280.0, w + 840.0, h + 560.0), Color(0.03, 0.04, 0.07, 1.0))
	if _wall_tex != null:
		for sx in range(-256, int(w) + 256, 256):
			for sy in range(-256, int(h) + 256, 256):
				draw_texture_rect(_wall_tex, Rect2(float(sx), float(sy), 256.0, 256.0), false, Color(0.24, 0.26, 0.34, 1.0))

	# 2. Raum-Boden (256x256 gekachelte hochauflösende Steinplatten)
	draw_rect(Rect2(wall_thick, wall_thick, w - wall_thick * 2.0, h - wall_thick * 2.0), Color("0b101b"))
	if _floor_tex != null:
		for fx in range(0, int(w), 256):
			for fy in range(0, int(h), 256):
				draw_texture_rect(_floor_tex, Rect2(float(fx), float(fy), 256.0, 256.0), false, Color(0.86, 0.88, 0.94, 1.0))
	else:
		var step := CryptDashConfig.TILE_SIZE
		for x in range(0, int(w), step):
			draw_line(Vector2(x, 0), Vector2(x, h), Color(0.15, 0.22, 0.35, 0.25), 1.0)
		for y in range(0, int(h), step):
			draw_line(Vector2(0, y), Vector2(w, y), Color(0.15, 0.22, 0.35, 0.25), 1.0)

	# Subtile deterministische Boden-Details (Moos-/Rußflecken & kleine Risse)
	for dec in _floor_decals:
		var dp: Vector2 = dec["pos"]
		var dr: float = float(dec["radius"])
		var kind: int = int(dec["kind"])
		if kind == 0:
			draw_circle(dp, dr, Color(0.02, 0.04, 0.06, 0.26))
		elif kind == 1:
			var d_ang: float = float(dec["angle"])
			var p2 := dp + Vector2(cos(d_ang), sin(d_ang)) * (dr * 0.85)
			var p3 := p2 + Vector2(cos(d_ang + 0.7), sin(d_ang + 0.7)) * (dr * 0.45)
			draw_line(dp, p2, Color(0.03, 0.04, 0.07, 0.55), 2.0)
			draw_line(p2, p3, Color(0.03, 0.04, 0.07, 0.45), 1.5)
		else:
			draw_circle(dp, dr * 0.65, Color(acc.r * 0.35, acc.g * 0.35, acc.b * 0.35, 0.08))

	# Raum-Typ Boden-Verzierung (Start-Runenkreis, Schatz-Teppich, Boss-Siegel)
	var center := Vector2(w * 0.5, h * 0.5)
	if room_data.type == DungeonGenerator.RoomType.START:
		draw_arc(center, 86.0, 0.0, TAU, 48, Color(acc.r, acc.g, acc.b, 0.22), 2.5)
		draw_arc(center, 64.0, 0.0, TAU, 36, Color(acc.r, acc.g, acc.b, 0.16), 1.5)
	elif room_data.type == DungeonGenerator.RoomType.TREASURE:
		draw_rect(Rect2(center.x - 118.0, center.y - 84.0, 236.0, 168.0), Color(0.28, 0.07, 0.10, 0.55))
		draw_rect(Rect2(center.x - 114.0, center.y - 80.0, 228.0, 160.0), Color(0.92, 0.70, 0.16, 0.45), false, 2.5)
	elif room_data.type == DungeonGenerator.RoomType.BOSS:
		draw_circle(center, 152.0, Color(0.45, 0.06, 0.10, 0.14))
		draw_arc(center, 150.0, 0.0, TAU, 64, Color(0.94, 0.27, 0.27, 0.32), 3.0)
		draw_arc(center, 114.0, 0.0, TAU, 48, Color(acc.r, acc.g, acc.b, 0.24), 2.0)

	# Boden-Schlagschatten entlang der 2.5D-Wände (Ambient Occlusion)
	draw_rect(Rect2(wall_thick, wall_thick, w - wall_thick * 2.0, 26.0), Color(0.01, 0.02, 0.04, 0.55))
	draw_rect(Rect2(wall_thick, wall_thick + 26.0, w - wall_thick * 2.0, 14.0), Color(0.01, 0.02, 0.04, 0.22))
	draw_rect(Rect2(wall_thick, h - wall_thick - 16.0, w - wall_thick * 2.0, 16.0), Color(0.01, 0.02, 0.04, 0.32))
	draw_rect(Rect2(wall_thick, wall_thick, 16.0, h - wall_thick * 2.0), Color(0.01, 0.02, 0.04, 0.34))
	draw_rect(Rect2(w - wall_thick - 16.0, wall_thick, 16.0, h - wall_thick * 2.0), Color(0.01, 0.02, 0.04, 0.34))

	# 3. 2.5D Wände
	_draw_25d_walls(w, h, wall_thick)

	# 4. Türen (offener Durchgang + animiertes Fallgitter)
	_draw_doors(w, h, wall_thick, acc)


func _draw_25d_walls(w: float, h: float, wall_thick: float) -> void:
	# Texturierte Mauer-Streifen
	if _wall_tex != null:
		# Nordwand: obere Brüstung (0..22) + abgedunkelte Frontwand (22..64)
		for wx in range(0, int(w), 256):
			var seg_w := minf(256.0, w - float(wx))
			draw_texture_rect_region(_wall_tex, Rect2(float(wx), 0.0, seg_w, 22.0), Rect2(0.0, 0.0, seg_w, 44.0), Color(0.95, 0.96, 1.0, 1.0))
			draw_texture_rect_region(_wall_tex, Rect2(float(wx), 22.0, seg_w, wall_thick - 22.0), Rect2(0.0, 64.0, seg_w, 84.0), Color(0.62, 0.65, 0.74, 1.0))
		# Südwand
		for wx in range(0, int(w), 256):
			var seg_w := minf(256.0, w - float(wx))
			draw_texture_rect_region(_wall_tex, Rect2(float(wx), h - wall_thick, seg_w, wall_thick), Rect2(0.0, 128.0, seg_w, 128.0), Color(0.84, 0.87, 0.95, 1.0))
		# West- & Ostwand
		for wy in range(0, int(h), 256):
			var seg_h := minf(256.0, h - float(wy))
			draw_texture_rect_region(_wall_tex, Rect2(0.0, float(wy), wall_thick, seg_h), Rect2(0.0, 0.0, 128.0, seg_h), Color(0.76, 0.80, 0.90, 1.0))
			draw_texture_rect_region(_wall_tex, Rect2(w - wall_thick, float(wy), wall_thick, seg_h), Rect2(128.0, 0.0, 128.0, seg_h), Color(0.76, 0.80, 0.90, 1.0))
	else:
		var wall_col := Color("182234")
		draw_rect(Rect2(0, 0, w, wall_thick), wall_col)
		draw_rect(Rect2(0, h - wall_thick, w, wall_thick), wall_col)
		draw_rect(Rect2(0, 0, wall_thick, h), wall_col)
		draw_rect(Rect2(w - wall_thick, 0, wall_thick, h), wall_col)

	# 2.5D Stein-Kanten, Sims & dunkle Kontur
	draw_line(Vector2(wall_thick, 22.0), Vector2(w - wall_thick, 22.0), Color(0.04, 0.06, 0.1, 0.9), 3.0)
	draw_line(Vector2(wall_thick, 20.0), Vector2(w - wall_thick, 20.0), Color(0.55, 0.65, 0.80, 0.35), 2.0)
	draw_rect(Rect2(wall_thick, wall_thick, w - wall_thick * 2.0, h - wall_thick * 2.0), Color(0.03, 0.05, 0.09, 0.95), false, 3.0)
	draw_rect(Rect2(0.0, 0.0, w, h), Color(0.02, 0.03, 0.06, 0.95), false, 4.0)

	# 4 Ecksäulen-Kappen
	for cp in [Vector2.ZERO, Vector2(w - wall_thick, 0.0), Vector2(0.0, h - wall_thick), Vector2(w - wall_thick, h - wall_thick)]:
		draw_rect(Rect2(cp, Vector2(wall_thick, wall_thick)), Color(0.08, 0.11, 0.18, 0.45))
		draw_rect(Rect2(cp + Vector2(3.0, 3.0), Vector2(wall_thick - 6.0, wall_thick - 6.0)), Color(0.52, 0.62, 0.78, 0.24), false, 2.0)


func _draw_doors(w: float, h: float, wall_thick: float, acc: Color) -> void:
	var glow_col := Color(acc.r, acc.g, acc.b, 0.34) if is_cleared else Color(0.94, 0.24, 0.24, 0.28)
	var bar_col := Color("64748b")
	var seal_col := Color("ef4444")
	var pulse := sin(_time * 4.0) * 0.18 + 0.82

	if room_data.doors["north"]:
		var r := Rect2(w * 0.5 - 64.0, 0.0, 128.0, wall_thick)
		draw_rect(r, Color("03060c"))
		draw_rect(Rect2(r.position.x + 12.0, wall_thick - 2.0, 104.0, 18.0), Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * pulse))
		_draw_gate_bars(r, false, bar_col, seal_col)

	if room_data.doors["south"]:
		var r := Rect2(w * 0.5 - 64.0, h - wall_thick, 128.0, wall_thick)
		draw_rect(r, Color("03060c"))
		draw_rect(Rect2(r.position.x + 12.0, h - wall_thick - 16.0, 104.0, 18.0), Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * pulse))
		_draw_gate_bars(r, false, bar_col, seal_col)

	if room_data.doors["west"]:
		var r := Rect2(0.0, h * 0.5 - 64.0, wall_thick, 128.0)
		draw_rect(r, Color("03060c"))
		draw_rect(Rect2(wall_thick - 2.0, r.position.y + 12.0, 18.0, 104.0), Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * pulse))
		_draw_gate_bars(r, true, bar_col, seal_col)

	if room_data.doors["east"]:
		var r := Rect2(w - wall_thick, h * 0.5 - 64.0, wall_thick, 128.0)
		draw_rect(r, Color("03060c"))
		draw_rect(Rect2(w - wall_thick - 16.0, r.position.y + 12.0, 18.0, 104.0), Color(glow_col.r, glow_col.g, glow_col.b, glow_col.a * pulse))
		_draw_gate_bars(r, true, bar_col, seal_col)


func _draw_gate_bars(r: Rect2, vertical_door: bool, bar_col: Color, seal_col: Color) -> void:
	if _door_open_anim >= 0.99:
		return
	var closed := 1.0 - _door_open_anim
	var alpha := clampf(closed, 0.0, 1.0)
	var b_col := Color(bar_col.r, bar_col.g, bar_col.b, alpha)
	var s_col := Color(seal_col.r, seal_col.g, seal_col.b, alpha * 0.85)
	if not vertical_door:
		var span := r.size.x * 0.5 * closed
		var cy := r.position.y + r.size.y * 0.5
		draw_line(Vector2(r.position.x, cy), Vector2(r.position.x + span, cy), b_col, 7.0)
		draw_line(Vector2(r.end.x, cy), Vector2(r.end.x - span, cy), b_col, 7.0)
		for i in range(1, 5):
			var bx := r.position.x + (r.size.x / 5.0) * float(i)
			if bx <= r.position.x + span or bx >= r.end.x - span:
				draw_line(Vector2(bx, r.position.y + 8.0), Vector2(bx, r.end.y - 8.0), b_col, 4.0)
		draw_circle(Vector2(r.position.x + r.size.x * 0.5, cy), 8.0 * closed, s_col)
	else:
		var span := r.size.y * 0.5 * closed
		var cx := r.position.x + r.size.x * 0.5
		draw_line(Vector2(cx, r.position.y), Vector2(cx, r.position.y + span), b_col, 7.0)
		draw_line(Vector2(cx, r.end.y), Vector2(cx, r.end.y - span), b_col, 7.0)
		for i in range(1, 5):
			var by := r.position.y + (r.size.y / 5.0) * float(i)
			if by <= r.position.y + span or by >= r.end.y - span:
				draw_line(Vector2(r.position.x + 8.0, by), Vector2(r.end.x - 8.0, by), b_col, 4.0)
		draw_circle(Vector2(cx, r.position.y + r.size.y * 0.5), 8.0 * closed, s_col)
