class_name WeaponCatalog
extends RefCounted
## Katalog freischaltbarer Startwaffen für Crypt Dash (kauf- und ausrüstbar am Altar der Seelen).
## Reine Modellklasse ohne Nodes, unit-testbar.

const WEAPONS: Array[Dictionary] = [
	{
		"id": "daggers",
		"cost": 0,
		"damage_mul": 1.0,
		"rate_mul": 1.0,
		"speed": 650.0,
		"pierce": false,
		"radius_scale": 1.0,
		"color": Color("22d3ee"),
		"name_key": "UPGRADE_WEAPON_DAGGERS",
	},
	{
		"id": "twin_fangs",
		"cost": 12,
		"damage_mul": 0.8,
		"rate_mul": 1.5,
		"speed": 820.0,
		"pierce": false,
		"radius_scale": 0.85,
		"color": Color("38bdf8"),
		"name_key": "UPGRADE_WEAPON_TWINS",
	},
	{
		"id": "arcane_staff",
		"cost": 20,
		"damage_mul": 1.85,
		"rate_mul": 0.65,
		"speed": 540.0,
		"pierce": true,
		"radius_scale": 1.35,
		"color": Color("c084fc"),
		"name_key": "UPGRADE_WEAPON_STAFF",
	},
]


static func get_all() -> Array[Dictionary]:
	return WEAPONS


static func get_weapon(weapon_id: String) -> Dictionary:
	for w in WEAPONS:
		if str(w["id"]) == weapon_id:
			return w
	return WEAPONS[0]


static func get_unlocked_ids() -> Array[String]:
	var raw: Variant = SaveService.get_value("crypt_dash", "weapons_unlocked", ["daggers"])
	var res: Array[String] = ["daggers"]
	if raw is Array:
		for item in raw:
			var s := str(item)
			if not res.has(s) and _exists(s):
				res.append(s)
	return res


static func _exists(weapon_id: String) -> bool:
	for w in WEAPONS:
		if str(w["id"]) == weapon_id:
			return true
	return false


static func is_unlocked(weapon_id: String) -> bool:
	if weapon_id == "daggers":
		return true
	return get_unlocked_ids().has(weapon_id)


static func get_equipped_id() -> String:
	var eq := str(SaveService.get_value("crypt_dash", "weapon_equipped", "daggers"))
	if is_unlocked(eq):
		return eq
	return "daggers"


static func try_buy_or_equip(weapon_id: String) -> bool:
	if not _exists(weapon_id):
		return false
	if is_unlocked(weapon_id):
		SaveService.set_value("crypt_dash", "weapon_equipped", weapon_id)
		return true

	var w := get_weapon(weapon_id)
	var cost: int = int(w["cost"])
	var souls: int = int(SaveService.get_value("crypt_dash", "souls", 0))
	if souls < cost:
		return false

	SaveService.set_value("crypt_dash", "souls", souls - cost, false)
	var unlocked := get_unlocked_ids()
	if not unlocked.has(weapon_id):
		unlocked.append(weapon_id)
	SaveService.set_value("crypt_dash", "weapons_unlocked", unlocked, false)
	SaveService.set_value("crypt_dash", "weapon_equipped", weapon_id, true)
	return true


static func apply_weapon_to_stats(base_stats: Dictionary, weapon_id: String) -> Dictionary:
	var result := base_stats.duplicate()
	var w := get_weapon(weapon_id)
	result["damage"] = maxf(0.5, float(result.get("damage", 1.0)) * float(w["damage_mul"]))
	result["attack_rate"] = maxf(0.5, float(result.get("attack_rate", 3.33)) * float(w["rate_mul"]))
	return result
