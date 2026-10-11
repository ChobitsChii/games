class_name ItemData
extends Resource
## Datengetriebenes Item für Crypt Dash.
## Verändert Spieler-Attribute über additive und multiplikative Boni.

@export var id: String = ""
@export var name_key: String = ""
@export var desc_key: String = ""
@export var stat_adds: Dictionary = {} # z.B. {"max_hp": 2.0, "dash_charges": 1.0}
@export var stat_muls: Dictionary = {} # z.B. {"damage": 1.2, "speed": 1.15}
@export var special_tag: String = ""   # z.B. "spread", "pierce", "vamp", "lightning", "flame_aura", "freeze"


static func create(
	p_id: String,
	p_name_key: String,
	p_desc_key: String,
	p_adds: Dictionary = {},
	p_muls: Dictionary = {},
	p_tag: String = ""
) -> ItemData:
	var item := ItemData.new()
	item.id = p_id
	item.name_key = p_name_key
	item.desc_key = p_desc_key
	item.stat_adds = p_adds
	item.stat_muls = p_muls
	item.special_tag = p_tag
	return item
