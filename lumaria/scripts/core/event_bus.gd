extends Node
## Globaler Event-Bus für Lumaria: The Prismatic Odyssey.
## Entkoppelt Spiel-Entities, HUD, Quest-Log und Dungeons.

signal player_damaged(current_quarters: int, max_quarters: int)
signal player_healed(current_quarters: int, max_quarters: int)
signal player_died()

signal lumen_collected(amount: int)
signal vitality_collected(quarters: int)
signal lumen_changed(total_lumen: int, delta: int)
signal key_count_changed(keys: int, has_boss_key: bool)

signal gadget_unlocked(gadget_id: String)
signal gadget_equipped(slot_index: int, gadget_id: String)

signal interaction_requested(target: Node2D)
signal dialogue_started(speaker_name_key: String, text_key: String, portrait_id: String)
signal dialogue_ended()

signal chest_opened(chest_id: String, loot_type: String)
signal switch_toggled(switch_id: String, state: bool)
signal room_transition_requested(target_room: String, entrance_marker: String)

signal prism_collected(prism_id: String)
signal boss_defeated(boss_id: String)
signal show_toast_requested(message: String)
signal victory()
