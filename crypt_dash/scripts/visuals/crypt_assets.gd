class_name CryptAssets
extends RefCounted
## Zentraler, gecachter Asset-Loader und prozedurale Licht-/Schatten-Texturen für Crypt Dash.

static var _cache_owner_checked: bool = false


static func _get_cache_dict() -> Dictionary:
	var ml := Engine.get_main_loop()
	if ml is SceneTree:
		var root := (ml as SceneTree).root
		if root != null:
			if not root.has_meta("_crypt_asset_cache"):
				root.set_meta("_crypt_asset_cache", {})
			return root.get_meta("_crypt_asset_cache") as Dictionary
	return {}


static func get_texture(path: String) -> Texture2D:
	var cache := _get_cache_dict()
	if cache.has(path):
		return cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		return null
	var tex := load(path) as Texture2D
	if tex != null and Engine.get_main_loop() is SceneTree:
		cache[path] = tex
	return tex


static func get_hit_flash_shader() -> Shader:
	var key := "__hit_flash_shader"
	var cache := _get_cache_dict()
	if cache.has(key):
		return cache[key] as Shader
	if ResourceLoader.exists("res://shaders/hit_flash.gdshader"):
		var sh := load("res://shaders/hit_flash.gdshader") as Shader
		if sh != null and Engine.get_main_loop() is SceneTree:
			cache[key] = sh
		return sh
	return null


static func get_radial_light_texture() -> Texture2D:
	var key := "__radial_light_tex"
	var cache := _get_cache_dict()
	if cache.has(key):
		return cache[key] as Texture2D
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.35, 0.72, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.65),
		Color(1.0, 1.0, 1.0, 0.16),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var gtex := GradientTexture2D.new()
	gtex.width = 256
	gtex.height = 256
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.gradient = grad
	if Engine.get_main_loop() is SceneTree:
		cache[key] = gtex
	return gtex


static func get_soft_shadow_texture() -> Texture2D:
	var key := "__soft_shadow_tex"
	var cache := _get_cache_dict()
	if cache.has(key):
		return cache[key] as Texture2D
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.55, 1.0])
	grad.colors = PackedColorArray([
		Color(0.0, 0.0, 0.0, 0.65),
		Color(0.0, 0.0, 0.0, 0.32),
		Color(0.0, 0.0, 0.0, 0.0),
	])
	var gtex := GradientTexture2D.new()
	gtex.width = 128
	gtex.height = 64
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.gradient = grad
	if Engine.get_main_loop() is SceneTree:
		cache[key] = gtex
	return gtex


static func get_glow_orb_texture() -> Texture2D:
	var key := "__glow_orb_tex"
	var cache := _get_cache_dict()
	if cache.has(key):
		return cache[key] as Texture2D
	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.0, 0.4, 1.0])
	grad.colors = PackedColorArray([
		Color(1.0, 1.0, 1.0, 1.0),
		Color(1.0, 1.0, 1.0, 0.45),
		Color(1.0, 1.0, 1.0, 0.0),
	])
	var gtex := GradientTexture2D.new()
	gtex.width = 64
	gtex.height = 64
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(0.5, 0.0)
	gtex.gradient = grad
	if Engine.get_main_loop() is SceneTree:
		cache[key] = gtex
	return gtex


static func get_floor_theme(floor_num: int) -> Dictionary:
	match clampi(floor_num, 1, 3):
		2:
			return {
				"id": "forge",
				"name_key": "HUD_FLOOR_NAME_2",
				"floor_tex": "res://assets/env/floor_forge.png",
				"wall_tex": "res://assets/env/wall_forge.png",
				"modulate": Color(0.56, 0.45, 0.44, 1.0),
				"torch_color": Color("ff7836"),
				"accent": Color("f97316"),
				"fog_color": Color(0.24, 0.10, 0.06, 1.0),
				"fog_strength": 0.15,
			}
		3:
			return {
				"id": "citadel",
				"name_key": "HUD_FLOOR_NAME_3",
				"floor_tex": "res://assets/env/floor_citadel.png",
				"wall_tex": "res://assets/env/wall_citadel.png",
				"modulate": Color(0.48, 0.44, 0.68, 1.0),
				"torch_color": Color("b46cff"),
				"accent": Color("c084fc"),
				"fog_color": Color(0.14, 0.06, 0.24, 1.0),
				"fog_strength": 0.17,
			}
		_:
			return {
				"id": "catacombs",
				"name_key": "HUD_FLOOR_NAME_1",
				"floor_tex": "res://assets/env/floor_catacombs.png",
				"wall_tex": "res://assets/env/wall_catacombs.png",
				"modulate": Color(0.50, 0.56, 0.72, 1.0),
				"torch_color": Color("ff9848"),
				"accent": Color("22d3ee"),
				"fog_color": Color(0.08, 0.16, 0.26, 1.0),
				"fog_strength": 0.14,
			}


static func get_enemy_portrait_path(enemy_id: String) -> String:
	match enemy_id:
		"skeleton":
			return "res://assets/sprites/enemy_skeleton.png"
		"archer":
			return "res://assets/sprites/enemy_archer.png"
		"ghost":
			return "res://assets/sprites/enemy_ghost.png"
		"slime":
			return "res://assets/sprites/enemy_slime.png"
		"summoner":
			return "res://assets/sprites/enemy_summoner.png"
		"boss1":
			return "res://assets/sprites/boss_malok.png"
		"boss2":
			return "res://assets/sprites/boss_vex.png"
		"boss3":
			return "res://assets/sprites/boss_thanatos.png"
		_:
			return "res://assets/sprites/enemy_skeleton.png"


static func get_item_icon_path(item_id: String) -> String:
	return "res://assets/icons/item_%s.png" % item_id


static func get_weapon_sprite_path(weapon_id: String) -> String:
	return "res://assets/sprites/weapon_%s.png" % weapon_id
