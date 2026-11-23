class_name SharedSplashScreen
extends Control
## Einheitlicher, lokalisierter Start-Splash-Screen für alle Spiele.
## Zeigt das Spiel-Splash-Logo (ohne fest eingebrannten Prompt-Text),
## einen pulsierenden Start-Hinweis in Systemsprache (DE/EN) sowie
## ein dynamisch konfigurierbares "Powered by Chii Arcade"-Eck-Badge.

signal proceed_requested(next_scene: String)

const DEFAULT_BRAND_NAME := "Chii Arcade"
const BRAND_SETTING_KEY := "branding/brand_name"
const BRAND_LOGO_PATH := "res://addons/shared/branding/chii_arcade_logo.png"
const READY_DELAY := 0.18
const FADE_IN_DURATION := 0.35
const FADE_OUT_DURATION := 0.22

@export var splash_texture: Texture2D
@export var next_scene_path: String = "res://scenes/main_menu.tscn"
@export var brand_name_override: String = ""

var _bg_rect: TextureRect
var _prompt_panel: PanelContainer
var _prompt_label: Label
var _brand_panel: PanelContainer
var _brand_logo: TextureRect
var _brand_label: Label

var _elapsed: float = 0.0
var _fade_out_elapsed: float = 0.0
var _can_continue: bool = false
var _transitioning: bool = false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_build_ui()
	_refresh_texts()

	if LocaleService != null and not LocaleService.language_changed.is_connected(_on_language_changed):
		LocaleService.language_changed.connect(_on_language_changed)


func _exit_tree() -> void:
	if LocaleService != null and LocaleService.language_changed.is_connected(_on_language_changed):
		LocaleService.language_changed.disconnect(_on_language_changed)


func _build_ui() -> void:
	# Vorhandene Legacy-Nodes aus älteren Szenen ausblenden, falls vorhanden
	if has_node("CenterContainer"):
		(get_node("CenterContainer") as Control).visible = false

	if has_node("BackgroundTexture") and get_node("BackgroundTexture") is TextureRect:
		_bg_rect = get_node("BackgroundTexture") as TextureRect
	else:
		_bg_rect = TextureRect.new()
		_bg_rect.name = "BackgroundTexture"
		add_child(_bg_rect)
		move_child(_bg_rect, 0)

	_bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_bg_rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_bg_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var resolved_tex := _resolve_splash_texture()
	if resolved_tex != null:
		_bg_rect.texture = resolved_tex

	# 1. Zentrierter Start-Hinweis unten ("Bitte Taste drücken oder klicken / tippen...")
	var prompt_center := CenterContainer.new()
	prompt_center.name = "PromptCenter"
	prompt_center.anchor_left = 0.0
	prompt_center.anchor_right = 1.0
	prompt_center.anchor_top = 1.0
	prompt_center.anchor_bottom = 1.0
	prompt_center.offset_top = -148.0
	prompt_center.offset_bottom = -64.0
	prompt_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(prompt_center)

	_prompt_panel = PanelContainer.new()
	_prompt_panel.name = "PromptPanel"
	_prompt_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prompt_style := StyleBoxFlat.new()
	prompt_style.bg_color = Color(0.03, 0.05, 0.11, 0.84)
	prompt_style.border_color = Color(0.32, 0.84, 1.0, 0.72)
	prompt_style.set_border_width_all(2)
	prompt_style.set_corner_radius_all(999)
	prompt_style.shadow_color = Color(0.0, 0.0, 0.0, 0.55)
	prompt_style.shadow_size = 12
	_prompt_panel.add_theme_stylebox_override("panel", prompt_style)
	prompt_center.add_child(_prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prompt_margin.add_theme_constant_override("margin_left", 34)
	prompt_margin.add_theme_constant_override("margin_right", 34)
	prompt_margin.add_theme_constant_override("margin_top", 12)
	prompt_margin.add_theme_constant_override("margin_bottom", 12)
	_prompt_panel.add_child(prompt_margin)

	_prompt_label = Label.new()
	_prompt_label.name = "PromptLabel"
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_font_size_override("font_size", 27)
	_prompt_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	prompt_margin.add_child(_prompt_label)

	# 2. Dezentes "Präsentiert von / Powered by Chii Arcade"-Badge unten rechts
	_brand_panel = PanelContainer.new()
	_brand_panel.name = "ChiiArcadeBadge"
	_brand_panel.anchor_left = 1.0
	_brand_panel.anchor_right = 1.0
	_brand_panel.anchor_top = 1.0
	_brand_panel.anchor_bottom = 1.0
	_brand_panel.offset_left = -360.0
	_brand_panel.offset_top = -78.0
	_brand_panel.offset_right = -24.0
	_brand_panel.offset_bottom = -22.0
	_brand_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_brand_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_brand_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var brand_style := StyleBoxFlat.new()
	brand_style.bg_color = Color(0.05, 0.04, 0.12, 0.80)
	brand_style.border_color = Color(0.68, 0.46, 0.98, 0.50)
	brand_style.set_border_width_all(1)
	brand_style.set_corner_radius_all(14)
	brand_style.shadow_color = Color(0.0, 0.0, 0.0, 0.45)
	brand_style.shadow_size = 8
	_brand_panel.add_theme_stylebox_override("panel", brand_style)
	add_child(_brand_panel)

	var brand_margin := MarginContainer.new()
	brand_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_margin.add_theme_constant_override("margin_left", 14)
	brand_margin.add_theme_constant_override("margin_right", 16)
	brand_margin.add_theme_constant_override("margin_top", 8)
	brand_margin.add_theme_constant_override("margin_bottom", 8)
	_brand_panel.add_child(brand_margin)

	var brand_row := HBoxContainer.new()
	brand_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	brand_row.alignment = BoxContainer.ALIGNMENT_CENTER
	brand_row.add_theme_constant_override("separation", 10)
	brand_margin.add_child(brand_row)

	_brand_logo = TextureRect.new()
	_brand_logo.name = "BrandLogo"
	_brand_logo.custom_minimum_size = Vector2(36, 36)
	_brand_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_brand_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_brand_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_brand_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(BRAND_LOGO_PATH):
		_brand_logo.texture = load(BRAND_LOGO_PATH) as Texture2D
	brand_row.add_child(_brand_logo)

	_brand_label = Label.new()
	_brand_label.name = "BrandLabel"
	_brand_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_brand_label.add_theme_font_size_override("font_size", 18)
	_brand_label.add_theme_color_override("font_color", Color(0.90, 0.87, 0.98, 0.94))
	brand_row.add_child(_brand_label)


func _resolve_splash_texture() -> Texture2D:
	if splash_texture != null:
		return splash_texture
	if _bg_rect != null and _bg_rect.texture != null:
		return _bg_rect.texture
	for candidate: String in ["res://assets/splash.png", "res://assets/graphics/splash.png"]:
		if ResourceLoader.exists(candidate):
			return load(candidate) as Texture2D
	return null


func get_brand_name() -> String:
	if brand_name_override.strip_edges() != "":
		return brand_name_override.strip_edges()
	var configured := str(ProjectSettings.get_setting(BRAND_SETTING_KEY, DEFAULT_BRAND_NAME)).strip_edges()
	return configured if configured != "" else DEFAULT_BRAND_NAME


func set_brand_name_override(new_brand_name: String) -> void:
	brand_name_override = new_brand_name
	_refresh_texts()


func get_prompt_text() -> String:
	return tr("COMMON_SPLASH_PROMPT")


func get_brand_text() -> String:
	return tr("COMMON_POWERED_BY") % get_brand_name()


func _refresh_texts() -> void:
	if _prompt_label != null:
		_prompt_label.text = get_prompt_text()
	if _brand_label != null:
		_brand_label.text = get_brand_text()


func _on_language_changed(_code: String) -> void:
	_refresh_texts()


func _process(delta: float) -> void:
	if _transitioning:
		_fade_out_elapsed += delta
		var t := clampf(_fade_out_elapsed / FADE_OUT_DURATION, 0.0, 1.0)
		modulate.a = 1.0 - t
		if t >= 1.0:
			set_process(false)
			if is_inside_tree() and next_scene_path != "":
				get_tree().change_scene_to_file(next_scene_path)
		return

	_elapsed += delta
	if _elapsed >= READY_DELAY:
		_can_continue = true

	var fade_in := clampf(_elapsed / FADE_IN_DURATION, 0.0, 1.0)
	if _bg_rect != null:
		_bg_rect.modulate.a = fade_in
	if _brand_panel != null:
		_brand_panel.modulate.a = fade_in
	if _prompt_panel != null:
		var pulse := 0.72 + 0.28 * (0.5 + 0.5 * sin(_elapsed * 3.4))
		_prompt_panel.modulate.a = fade_in * pulse


func _gui_input(event: InputEvent) -> void:
	_check_input(event)


func _unhandled_input(event: InputEvent) -> void:
	_check_input(event)


func _check_input(event: InputEvent) -> void:
	if not _can_continue or _transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		proceed()
	elif event is InputEventMouseButton and event.pressed:
		proceed()
	elif event is InputEventScreenTouch and event.pressed:
		proceed()
	elif event is InputEventJoypadButton and event.pressed:
		proceed()


func proceed() -> void:
	if _transitioning:
		return
	_transitioning = true
	_can_continue = false
	_fade_out_elapsed = 0.0
	proceed_requested.emit(next_scene_path)
