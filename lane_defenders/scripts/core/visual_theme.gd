class_name LaneDefendersTheme
extends RefCounted
## Verwaltet die zwei auswählbaren Grafik-Designs für Lane Defenders:
## "towers" (Default: Fantasy-Burg-Türme) und "heroes" (Option 2: Chibi-Burghelden).

const THEME_TOWERS := "towers"
const THEME_HEROES := "heroes"
const THEMES: Array[String] = [THEME_TOWERS, THEME_HEROES]
const SAVE_SECTION := "lane_defenders"
const SAVE_KEY := "visual_theme"


static func normalize(theme_id: String) -> String:
	var cleaned := theme_id.strip_edges().to_lower()
	if cleaned in THEMES:
		return cleaned
	return THEME_TOWERS


static func get_current() -> String:
	var raw: Variant = SaveService.get_value(SAVE_SECTION, SAVE_KEY, THEME_TOWERS)
	return normalize(str(raw) if raw != null else THEME_TOWERS)


static func set_current(theme_id: String, persist: bool = true) -> String:
	var normalized := normalize(theme_id)
	SaveService.set_value(SAVE_SECTION, SAVE_KEY, normalized)
	if persist:
		SaveService.save()
	return normalized


static func cycle(persist: bool = true) -> String:
	var current := get_current()
	var idx := THEMES.find(current)
	var next_theme := THEMES[(idx + 1) % THEMES.size()]
	return set_current(next_theme, persist)


static func get_label_key(theme_id: String = "") -> String:
	var t := get_current() if theme_id == "" else normalize(theme_id)
	return "SETTINGS_THEME_HEROES" if t == THEME_HEROES else "SETTINGS_THEME_TOWERS"


static func get_unit_texture_path(unit_id: String, theme_id: String = "") -> String:
	var t := get_current() if theme_id == "" else normalize(theme_id)
	return "res://assets/units/%s/%s.png" % [t, unit_id]


static func get_unit_name_key(unit_id: String, theme_id: String = "") -> String:
	var t := get_current() if theme_id == "" else normalize(theme_id)
	return "UNIT_%s_%s" % [t.to_upper(), unit_id.to_upper()]


static func get_menu_bg_path(theme_id: String = "") -> String:
	var t := get_current() if theme_id == "" else normalize(theme_id)
	return "res://assets/main_menu_bg_heroes.png" if t == THEME_HEROES else "res://assets/main_menu_bg.png"


static func get_projectile_texture_path(is_slow: bool, is_area: bool, theme_id: String = "") -> String:
	if is_slow:
		return "res://assets/projectiles/ice_shard.png"
	if is_area:
		return ""
	var t := get_current() if theme_id == "" else normalize(theme_id)
	return "res://assets/projectiles/arrow_bolt.png" if t == THEME_HEROES else "res://assets/projectiles/arcane_bolt.png"


static func get_energy_texture_path() -> String:
	return "res://assets/ui/mana_crystal.png"
