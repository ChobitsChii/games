extends Node
## Lautstärken (Gesamt, Musik, Effekte) als Werte von 0 bis 1. Wird in den Optionen
## geändert, gespeichert und auf die Audio-Busse angewendet. Autoload "AudioSettings".

signal changed

const MASTER := &"master"
const MUSIC := &"music"
const SFX := &"sfx"
const KINDS: Array[StringName] = [MASTER, MUSIC, SFX]
const DEFAULT_VOLUME := 1.0
const SFX_BUS := "Sfx"
const MUSIC_BUS := "Music"
const MASTER_BUS := "Master"
const MIN_DB := -80.0

var _volumes: Dictionary = {MASTER: DEFAULT_VOLUME, MUSIC: DEFAULT_VOLUME, SFX: DEFAULT_VOLUME}


## Umrechnung von Lautstärke (0..1) in Dezibel. 0 ist stumm.
static func volume_to_db(volume: float) -> float:
	var v := clampf(volume, 0.0, 1.0)
	if v <= 0.0:
		return MIN_DB
	return maxf(linear_to_db(v), MIN_DB)


static func bus_for(kind: StringName) -> String:
	match kind:
		MUSIC:
			return MUSIC_BUS
		SFX:
			return SFX_BUS
	return MASTER_BUS


func _ready() -> void:
	ensure_sfx_bus()
	for kind in KINDS:
		_volumes[kind] = clampf(float(SaveService.get_value("settings", "volume_" + String(kind), DEFAULT_VOLUME)), 0.0, 1.0)
	apply()


func get_volume(kind: StringName) -> float:
	return _volumes.get(kind, DEFAULT_VOLUME)


func set_volume(kind: StringName, value: float, persist: bool = true) -> void:
	if kind not in KINDS:
		return
	_volumes[kind] = clampf(value, 0.0, 1.0)
	if persist:
		SaveService.set_value("settings", "volume_" + String(kind), _volumes[kind])
	apply()
	changed.emit()


## Setzt die Bus-Lautstärken. Busse, die noch nicht existieren (z. B. Musik), werden übersprungen.
func apply() -> void:
	for kind in KINDS:
		var index := AudioServer.get_bus_index(bus_for(kind))
		if index != -1:
			AudioServer.set_bus_volume_db(index, volume_to_db(_volumes[kind]))


## Legt den Effekt-Bus an, falls er fehlt.
func ensure_sfx_bus() -> void:
	if AudioServer.get_bus_index(SFX_BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, SFX_BUS)
	AudioServer.set_bus_send(index, MASTER_BUS)
