class_name RoomTemplate
extends Node2D
## Vorlage für einen Raum in Crypt Dash.
## 20 x 11 Kacheln à 64px (1280 x 704 px).
## Enthält Wände, Türen, Bodentexturierung und Gegner-Spawnpunkte.

signal room_cleared
signal door_entered(direction: String)

var room_data: DungeonGenerator.DungeonRoom
var is_cleared: bool = false
var spawned_enemies: Array[Node2D] = []

var _door_barriers: Dictionary = {}
var _door_triggers: Dictionary = {}


class FloorExitNode extends Area2D:
	var _time: float = 0.0
	var label: Label

	func _init() -> void:
		z_index = 1
		collision_layer = 0
		collision_mask = 2 # Spieler

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0
		shape.shape = circle
		add_child(shape)

		label = Label.new()
		label.text = "ROOM_FLOOR_EXIT"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("38bdf8"))
		label.position = Vector2(-120, -75)
		label.custom_minimum_size = Vector2(240, 24)
		add_child(label)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var pulse: float = sin(_time * 4.0) * 0.15 + 0.85
		# Äußerer Runenkreis / Glow
		draw_circle(Vector2.ZERO, 54.0 * pulse, Color(0.06, 0.71, 0.83, 0.25))
		# Steiniger Schacht-Rahmen
		draw_circle(Vector2.ZERO, 46.0, Color("0f172a"))
		draw_arc(Vector2.ZERO, 46.0, 0, TAU, 32, Color("38bdf8"), 3.5)
		# Dunkles Loch nach unten
		draw_circle(Vector2.ZERO, 38.0, Color("020617"))
		# Magischer Strudel / Spirale nach unten
		for i in range(4):
			var ang: float = _time * 2.5 + i * (PI / 2.0)
			var p1 := Vector2(cos(ang), sin(ang)) * 10.0
			var p2 := Vector2(cos(ang + 0.8), sin(ang + 0.8)) * 34.0
			draw_line(p1, p2, Color("06b6d4"), 2.5)
		# Leuchtendes Zentrum
		draw_circle(Vector2.ZERO, 8.0 * pulse, Color("67e8f9"))


class PedestalNode extends Area2D:
	var _time: float = 0.0
	var label: Label

	func _init() -> void:
		z_index = 1
		collision_layer = 0
		collision_mask = 2 # Spieler

		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 48.0
		shape.shape = circle
		add_child(shape)

		label = Label.new()
		label.text = "ROOM_ALTAR_PEDESTAL"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", Color("facc15"))
		label.position = Vector2(-120, -75)
		label.custom_minimum_size = Vector2(240, 24)
		add_child(label)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		var bob: float = sin(_time * 3.0) * 4.0
		# Altar-Sockel aus Stein
		draw_rect(Rect2(-32, 10, 64, 20), Color("1e293b"))
		draw_rect(Rect2(-28, -8, 56, 18), Color("334155"))
		# Goldene Runenverzierung
		draw_line(Vector2(-28, 10), Vector2(28, 10), Color("eab308"), 2.0)
		# Schwebende Schatzkiste / Relikt
		var chest_pos := Vector2(0, -22 + bob)
		draw_circle(chest_pos, 22.0, Color(0.9, 0.7, 0.1, 0.3))
		draw_rect(Rect2(chest_pos.x - 16, chest_pos.y - 12, 32, 24), Color("b45309"))
		draw_rect(Rect2(chest_pos.x - 14, chest_pos.y - 10, 28, 10), Color("d97706"))
		# Goldenes Schloss
		draw_circle(Vector2(chest_pos.x, chest_pos.y + 2), 4.0, Color("fef08a"))


func _ready() -> void:
	child_entered_tree.connect(_on_child_entered)


func _on_child_entered(node: Node) -> void:
	if (node is BaseEnemy or node is BaseBoss) and not spawned_enemies.has(node):
		spawned_enemies.append(node)


func setup_room(p_room: DungeonGenerator.DungeonRoom) -> void:
	z_index = -10
	room_data = p_room
	is_cleared = p_room.cleared
	_build_room_geometry()

	if is_cleared:
		_unlock_doors()
		if room_data.type == DungeonGenerator.RoomType.BOSS:
			_spawn_floor_exit()
		elif room_data.type == DungeonGenerator.RoomType.TREASURE and not room_data.chest_opened:
			_spawn_pedestal()
	else:
		_spawn_room_contents()


func _build_room_geometry() -> void:
	# Außenwände mit Türen
	var wall_color := Color("0e1626")
	var floor_color := Color("090d16")

	# Statischer Körper für feste Raumwände
	var static_body := StaticBody2D.new()
	static_body.collision_layer = 1
	add_child(static_body)

	var w := CryptDashConfig.ROOM_PIXEL_WIDTH  # 1280
	var h := CryptDashConfig.ROOM_PIXEL_HEIGHT # 704
	var wall_thick := 64.0
	var door_width := 128.0

	# Oben: 2 Wandsegmente links und rechts der Tür
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

	# Türen (oder solide Wände falls keine Tür in diese Richtung führt)
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


func _add_wall_box(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
	parent.add_child(shape)


func _add_door(dir: String, pos: Vector2, size: Vector2) -> void:
	# Physischer Sperr-Riegel als eigener StaticBody, solange der Raum nicht gesäubert ist
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

	# Trigger zum Betreten des nächsten Raumes (leicht in den Raum hinein ragend für flüssigen Übergang)
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
		boss.global_position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
		boss.boss_died.connect(func(_name: String) -> void:
			_mark_room_cleared()
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
		var dist := randf_range(100, 300)
		en.global_position = center + Vector2(cos(angle), sin(angle)) * dist
		add_child(en)
		spawned_enemies.append(en)


func _physics_process(_delta: float) -> void:
	if not is_cleared:
		# Prüfen ob alle Gegner besiegt sind
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
		# Wenn gesäubert: Prüfen ob Spieler auf Tür-Trigger steht
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
		if body is Player:
			room_data.chest_opened = true
			EventBus.item_collected.emit("treasure_opened")
			pedestal.queue_free()
	)
	add_child(pedestal)


func _spawn_floor_exit() -> void:
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var exit_node := FloorExitNode.new()
	exit_node.position = center
	exit_node.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			EventBus.floor_completed.emit(1)
	)
	add_child(exit_node)


func _draw() -> void:
	var w := CryptDashConfig.ROOM_PIXEL_WIDTH
	var h := CryptDashConfig.ROOM_PIXEL_HEIGHT
	# Raum-Boden
	draw_rect(Rect2(0, 0, w, h), Color("090d16"))

	# Zarte Fliesen-Gitter
	var step := CryptDashConfig.TILE_SIZE
	for x in range(0, w, step):
		draw_line(Vector2(x, 0), Vector2(x, h), Color(0.1, 0.15, 0.25, 0.2), 1.0)
	for y in range(0, h, step):
		draw_line(Vector2(0, y), Vector2(w, y), Color(0.1, 0.15, 0.25, 0.2), 1.0)

	# Fackeln an den vier Ecken
	var torch_glow := Color("f97316")
	for corner in [Vector2(120, 120), Vector2(w - 120, 120), Vector2(120, h - 120), Vector2(w - 120, h - 120)]:
		draw_circle(corner, 32.0, Color(torch_glow.r, torch_glow.g, torch_glow.b, 0.15))
		draw_circle(corner, 8.0, torch_glow)
		draw_circle(corner, 4.0, Color("fef08a"))

	# Wände
	var wall_color := Color("0e1626")
	var wall_thick := 64.0
	draw_rect(Rect2(0, 0, w, wall_thick), wall_color)
	draw_rect(Rect2(0, h - wall_thick, w, wall_thick), wall_color)
	draw_rect(Rect2(0, 0, wall_thick, h), wall_color)
	draw_rect(Rect2(w - wall_thick, 0, wall_thick, h), wall_color)

	# Türen hervorheben: Türkis wenn offen, Rot mit Gittern wenn verschlossen
	var door_col := Color("22d3ee") if is_cleared else Color("ef4444")
	if room_data.doors["north"]:
		draw_rect(Rect2(w / 2.0 - 64, 0, 128, wall_thick), door_col)
		if not is_cleared:
			draw_line(Vector2(w / 2.0 - 64, wall_thick / 2.0), Vector2(w / 2.0 + 64, wall_thick / 2.0), Color("7f1d1d"), 6.0)
	if room_data.doors["south"]:
		draw_rect(Rect2(w / 2.0 - 64, h - wall_thick, 128, wall_thick), door_col)
		if not is_cleared:
			draw_line(Vector2(w / 2.0 - 64, h - wall_thick / 2.0), Vector2(w / 2.0 + 64, h - wall_thick / 2.0), Color("7f1d1d"), 6.0)
	if room_data.doors["west"]:
		draw_rect(Rect2(0, h / 2.0 - 64, wall_thick, 128), door_col)
		if not is_cleared:
			draw_line(Vector2(wall_thick / 2.0, h / 2.0 - 64), Vector2(wall_thick / 2.0, h / 2.0 + 64), Color("7f1d1d"), 6.0)
	if room_data.doors["east"]:
		draw_rect(Rect2(w - wall_thick, h / 2.0 - 64, wall_thick, 128), door_col)
		if not is_cleared:
			draw_line(Vector2(w - wall_thick / 2.0, h / 2.0 - 64), Vector2(w - wall_thick / 2.0, h / 2.0 + 64), Color("7f1d1d"), 6.0)
