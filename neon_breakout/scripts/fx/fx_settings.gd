extends Node
## Effekt-Einstellungen von Neon Breakout (Qualität, Bildschirmwackeln).
## Autoload "FxSettings". Wird in den Optionen geändert und gespeichert.

signal changed

enum Quality { LOW, HIGH }

const QUALITY_KEYS := {
	Quality.LOW: "FX_LOW",
	Quality.HIGH: "FX_HIGH",
}

var quality: int = Quality.HIGH
var shake_enabled := true

var _glow_texture: Texture2D


func _ready() -> void:
	quality = SaveService.get_value("settings", "fx_quality", Quality.HIGH)
	if quality not in QUALITY_KEYS:
		quality = Quality.HIGH
	shake_enabled = SaveService.get_value("settings", "fx_shake", true)


func set_quality(value: int, persist: bool = true) -> void:
	quality = value
	if persist:
		SaveService.set_value("settings", "fx_quality", quality)
	changed.emit()


func cycle_quality() -> void:
	set_quality(Quality.LOW if quality == Quality.HIGH else Quality.HIGH)


func set_shake_enabled(value: bool, persist: bool = true) -> void:
	shake_enabled = value
	if persist:
		SaveService.set_value("settings", "fx_shake", shake_enabled)
	changed.emit()


func toggle_shake() -> void:
	set_shake_enabled(not shake_enabled)


func glow_enabled() -> bool:
	return quality == Quality.HIGH


func particle_scale() -> float:
	return 1.0 if quality == Quality.HIGH else 0.35


## Passt eine Partikelanzahl an die Qualität an (mindestens 1).
func scaled(amount: int) -> int:
	return maxi(int(round(amount * particle_scale())), 1)


func shake_scale() -> float:
	return 1.0 if shake_enabled else 0.0


## Geteilte Textur für Funken (wird beim ersten Gebrauch erzeugt).
func get_glow_texture() -> Texture2D:
	if _glow_texture == null:
		_glow_texture = Burst.make_glow_texture()
	return _glow_texture
