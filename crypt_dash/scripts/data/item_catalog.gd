class_name ItemCatalog
extends RefCounted
## Katalog aller 15 Items für Crypt Dash.

static func get_all_items() -> Array[ItemData]:
	var list: Array[ItemData] = []
	list.append(ItemData.create(
		"spread", "ITEM_SPREAD_NAME", "ITEM_SPREAD_DESC",
		{}, {}, "spread"
	))
	list.append(ItemData.create(
		"pierce", "ITEM_PIERCE_NAME", "ITEM_PIERCE_DESC",
		{}, {}, "pierce"
	))
	list.append(ItemData.create(
		"vamp", "ITEM_VAMP_NAME", "ITEM_VAMP_DESC",
		{}, {}, "vamp"
	))
	list.append(ItemData.create(
		"shield", "ITEM_SHIELD_NAME", "ITEM_SHIELD_DESC",
		{"shield_stacks": 1.0}, {}, "shield"
	))
	list.append(ItemData.create(
		"lightning", "ITEM_LIGHTNING_NAME", "ITEM_LIGHTNING_DESC",
		{}, {}, "lightning"
	))
	list.append(ItemData.create(
		"dash_extra", "ITEM_DASH_EXTRA_NAME", "ITEM_DASH_EXTRA_DESC",
		{"dash_charges": 1.0}, {}
	))
	list.append(ItemData.create(
		"magnet", "ITEM_MAGNET_NAME", "ITEM_MAGNET_DESC",
		{"magnet_range": 160.0}, {}
	))
	list.append(ItemData.create(
		"boots", "ITEM_BOOTS_NAME", "ITEM_BOOTS_DESC",
		{}, {"speed": 1.25}
	))
	list.append(ItemData.create(
		"heavy", "ITEM_HEAVY_NAME", "ITEM_HEAVY_DESC",
		{}, {"damage": 1.5, "attack_rate": 0.85}
	))
	list.append(ItemData.create(
		"haste", "ITEM_HASTE_NAME", "ITEM_HASTE_DESC",
		{}, {"attack_rate": 1.4}
	))
	list.append(ItemData.create(
		"heart_container", "ITEM_HEART_CONTAINER_NAME", "ITEM_HEART_CONTAINER_DESC",
		{"max_hp": 4.0}, {}, "heal_full"
	))
	list.append(ItemData.create(
		"flame_aura", "ITEM_BOMB_AURA_NAME", "ITEM_BOMB_AURA_DESC",
		{}, {}, "flame_aura"
	))
	list.append(ItemData.create(
		"berserk", "ITEM_BERSERK_NAME", "ITEM_BERSERK_DESC",
		{}, {}, "berserk"
	))
	list.append(ItemData.create(
		"frost", "ITEM_FROST_NAME", "ITEM_FROST_DESC",
		{}, {}, "freeze"
	))
	list.append(ItemData.create(
		"crit", "ITEM_CRIT_NAME", "ITEM_CRIT_DESC",
		{"crit_chance": 0.3}, {}
	))
	return list


static func get_random_selection(rng: RandomNumberGenerator, count: int = 3, exclude_ids: Array = []) -> Array[ItemData]:
	var available: Array[ItemData] = []
	for it in get_all_items():
		if not exclude_ids.has(it.id):
			available.append(it)
	
	if available.size() <= count:
		return available

	var result: Array[ItemData] = []
	var pool := available.duplicate()
	for i in range(count):
		if pool.is_empty():
			break
		var idx := rng.randi_range(0, pool.size() - 1)
		result.append(pool[idx])
		pool.remove_at(idx)
	return result
