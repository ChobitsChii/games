class_name UpgradeSystem
extends RefCounted
## Verwaltung der Spieler-Upgrades, Modifikatoren und Kartenauswahl.

const UPGRADES: Array[Dictionary] = [
	{
		"id": "double_shot",
		"name_key": "GAME_UPGRADE_DOUBLE_SHOT",
		"desc_key": "GAME_UPGRADE_DOUBLE_SHOT_DESC",
		"max_stacks": 1,
		"stat_mods": {"double_shot": 1.0}
	},
	{
		"id": "spread_shot",
		"name_key": "GAME_UPGRADE_SPREAD_SHOT",
		"desc_key": "GAME_UPGRADE_SPREAD_SHOT_DESC",
		"max_stacks": 2,
		"stat_mods": {"spread_shot_count": 1.0}
	},
	{
		"id": "rapid_fire",
		"name_key": "GAME_UPGRADE_RAPID_FIRE",
		"desc_key": "GAME_UPGRADE_RAPID_FIRE_DESC",
		"max_stacks": 3,
		"stat_mods": {"fire_rate_mul": 0.8} # 20% schneller
	},
	{
		"id": "shield_boost",
		"name_key": "GAME_UPGRADE_SHIELD_BOOST",
		"desc_key": "GAME_UPGRADE_SHIELD_BOOST_DESC",
		"max_stacks": 2,
		"stat_mods": {"shield_max_add": 1.0, "shield_recharge_mul": 1.25}
	},
	{
		"id": "magnet",
		"name_key": "GAME_UPGRADE_MAGNET",
		"desc_key": "GAME_UPGRADE_MAGNET_DESC",
		"max_stacks": 2,
		"stat_mods": {"magnet_radius_add": 200.0}
	},
	{
		"id": "explosive_ammo",
		"name_key": "GAME_UPGRADE_EXPLOSIVE_AMMO",
		"desc_key": "GAME_UPGRADE_EXPLOSIVE_AMMO_DESC",
		"max_stacks": 1,
		"stat_mods": {"explosive_bullets": 1.0}
	}
]


static func get_upgrade_by_id(id: String) -> Dictionary:
	for u in UPGRADES:
		if u["id"] == id:
			return u
	return {}


static func get_available_upgrades(acquired_counts: Dictionary) -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	for u in UPGRADES:
		var current_count: int = int(acquired_counts.get(u["id"], 0))
		if current_count < int(u["max_stacks"]):
			available.append(u)
	return available


static func roll_random_upgrades(
		acquired_counts: Dictionary,
		count: int,
		rng: RandomNumberGenerator) -> Array[Dictionary]:
	var pool := get_available_upgrades(acquired_counts)
	if pool.is_empty():
		return []

	pool.shuffle()
	# Da pool.shuffle() den Engine-RNG nimmt, permutieren wir zusätzlich mit dem übergebenen RNG
	var chosen: Array[Dictionary] = []
	var pool_copy := pool.duplicate()
	while not pool_copy.is_empty() and chosen.size() < count:
		var idx := rng.randi_range(0, pool_copy.size() - 1)
		chosen.append(pool_copy[idx])
		pool_copy.remove_at(idx)

	return chosen


static func calculate_effective_stat(
		base_value: float,
		adds: Array[float],
		muls: Array[float]) -> float:
	var total_add := 0.0
	for a in adds:
		total_add += a

	var total_mul := 1.0
	for m in muls:
		total_mul *= m

	return (base_value + total_add) * total_mul
