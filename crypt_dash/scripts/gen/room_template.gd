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

var _door_colliders: Dictionary = {}
var _door_triggers: Dictionary = {}


func setup_room(p_room: DungeonGenerator.DungeonRoom) -> void:
	z_index = -10
	room_data = p_room
	is_cleared = p_room.cleared
	_build_room_geometry()
	if not is_cleared:
		_spawn_room_contents()


func _build_room_geometry() -> void:
	# Außenwände mit Türen
	var wall_color := Color("0e1626")
	var floor_color := Color("090d16")

	# Statischer Körper für Wände
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

	# Tür-Blocker falls keine Tür in diese Richtung führt
	if not room_data.doors["north"]:
		_add_wall_box(static_body, Vector2(w / 2.0, wall_thick / 2.0), Vector2(door_width, wall_thick))
	else:
		_add_door_trigger("north", Vector2(w / 2.0, wall_thick / 2.0), Vector2(door_width, wall_thick))

	if not room_data.doors["south"]:
		_add_wall_box(static_body, Vector2(w / 2.0, h - wall_thick / 2.0), Vector2(door_width, wall_thick))
	else:
		_add_door_trigger("south", Vector2(w / 2.0, h - wall_thick / 2.0), Vector2(door_width, wall_thick))

	if not room_data.doors["west"]:
		_add_wall_box(static_body, Vector2(wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))
	else:
		_add_door_trigger("west", Vector2(wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))

	if not room_data.doors["east"]:
		_add_wall_box(static_body, Vector2(w - wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))
	else:
		_add_door_trigger("east", Vector2(w - wall_thick / 2.0, h / 2.0), Vector2(wall_thick, door_width))


func _add_wall_box(parent: Node2D, pos: Vector2, size: Vector2) -> void:
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	shape.position = pos
	parent.add_child(shape)


func _add_door_trigger(dir: String, pos: Vector2, size: Vector2) -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2 # Spieler
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	shape.shape = rect
	area.add_child(shape)
	area.position = pos
	area.body_entered.connect(func(body: Node2D) -> void:
		if is_cleared and body is Player:
			door_entered.emit.call_deferred(dir)
	)
	add_child(area)
	_door_triggers[dir] = area


func _spawn_room_contents() -> void:
	if room_data.type == DungeonGenerator.RoomType.START:
		is_cleared = true
		return

	if room_data.type == DungeonGenerator.RoomType.TREASURE:
		is_cleared = true
		# Schatzkiste / Altar
		_spawn_pedestal()
		return

	if room_data.type == DungeonGenerator.RoomType.BOSS:
		var boss := BaseBoss.new()
		boss.global_position = Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
		boss.boss_died.connect(func(_name: String) -> void:
			is_cleared = true
			room_cleared.emit()
			_spawn_floor_exit()
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


func _process(_delta: float) -> void:
	if not is_cleared:
		# Prüfen ob alle Gegner besiegt sind
		var all_dead := true
		for en in spawned_enemies:
			if is_instance_valid(en):
				all_dead = false
				break
		if all_dead:
			is_cleared = true
			room_data.cleared = true
			room_cleared.emit()
			EventBus.room_cleared.emit(room_data.coords)
			queue_redraw()


func _spawn_pedestal() -> void:
	# Item-Wahl auf Sockel
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 48.0
	shape.shape = circle
	area.add_child(shape)
	area.position = center
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			EventBus.item_collected.emit("treasure_opened")
			area.queue_free()
	)
	add_child(area)


func _spawn_floor_exit() -> void:
	# Ausgang zur nächsten Etage
	var center := Vector2(CryptDashConfig.ROOM_PIXEL_WIDTH / 2.0, CryptDashConfig.ROOM_PIXEL_HEIGHT / 2.0)
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 2
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 50.0
	shape.shape = circle
	area.add_child(shape)
	area.position = center
	area.body_entered.connect(func(body: Node2D) -> void:
		if body is Player:
			EventBus.floor_completed.emit(1)
	)
	add_child(area)


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

	# Türen hervorheben
	var door_col := Color("22d3ee") if is_cleared else Color("ef4444")
	if room_data.doors["north"]:
		draw_rect(Rect2(w / 2.0 - 64, 0, 128, wall_thick), door_col)
	if room_data.doors["south"]:
		draw_rect(Rect2(w / 2.0 - 64, h - wall_thick, 128, wall_thick), door_col)
	if room_data.doors["west"]:
		draw_rect(Rect2(0, h / 2.0 - 64, wall_thick, 128), door_col)
	if room_data.doors["east"]:
		draw_rect(Rect2(w - wall_thick, h / 2.0 - 64, wall_thick, 128), door_col)
