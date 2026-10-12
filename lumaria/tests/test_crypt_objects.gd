extends TestCase
## Testet die interaktiven Objekte der Klingen-Krypta und die Boss-Mechanik von Carapax.

const TETHER_POST_SCENE := preload("res://scenes/objects/tether_post.tscn")
const SPIKE_TRAP_SCENE := preload("res://scenes/objects/spike_trap.tscn")
const CARAPAX_SCENE := preload("res://scenes/entities/bosses/boss_carapax.tscn")


func test_tether_post_anchor_properties() -> void:
	var post: TetherPost = TETHER_POST_SCENE.instantiate()
	post.global_position = Vector2(400, 300)
	assert_true(post.is_in_group("tether_posts"), "In Gruppe tether_posts")
	var anchor := post.get_anchor_position()
	assert_eq(anchor, Vector2(400, 288), "Anker-Offset korrekt")
	post.free()


func test_spike_trap_cycle_and_damage_state() -> void:
	var trap: SpikeTrap = SPIKE_TRAP_SCENE.instantiate()
	assert_eq(trap.state, SpikeTrap.State.LOWERED, "Startet im LOWERED")
	assert_eq(trap.damage_quarters, 1, "Standard-Schaden ist 1 Viertel")

	# Nach 1.8s -> TELEGRAPH
	trap._physics_process(1.85)
	assert_eq(trap.state, SpikeTrap.State.TELEGRAPH, "Wechselt zu TELEGRAPH")

	# Nach weiteren 0.4s -> RAISED
	trap._physics_process(0.45)
	assert_eq(trap.state, SpikeTrap.State.RAISED, "Wechselt zu RAISED")

	# Nach weiteren 1.2s -> wieder LOWERED
	trap._physics_process(1.25)
	assert_eq(trap.state, SpikeTrap.State.LOWERED, "Wechselt zurück zu LOWERED")
	trap.free()


func test_boss_carapax_frontal_defense_and_tether_vulnerability() -> void:
	var boss: BossCarapax = CARAPAX_SCENE.instantiate()
	assert_eq(boss.max_health, 250, "Max HP ist 250")
	assert_eq(boss.current_health, 250, "Start-HP ist 250")
	assert_false(boss.is_overturned, "Initial aufrecht")

	# 1. Frontalangriff ohne Fangseil: 85% Schadensreduktion (15% verbleiben)
	# 40 Schaden * 0.15 = 6 Schaden
	boss.take_damage(40)
	assert_eq(boss.current_health, 244, "Frontaler Panzer blockiert 85% Schaden")

	# 2. Fangseil-Schwachpunkt-Treffer: Wirft Carapax auf den Rücken!
	boss.is_invulnerable = false
	boss.tether_hook_hit()
	assert_true(boss.is_overturned, "Carapax liegt auf dem Rücken")
	assert_eq(boss.boss_state, BossCarapax.BossState.OVERTURNED_STUN, "Status OVERTURNED_STUN")

	# 3. Angriff im betäubten Zustand: Voller Schaden!
	boss.is_invulnerable = false
	boss.take_damage(50)
	assert_eq(boss.current_health, 194, "Voller Schaden im Stun")

	# 4. Phase 2 bei <= 125 HP
	boss.is_invulnerable = false
	boss.take_damage(70) # 194 - 70 = 124 HP <= 125 HP
	boss._process_ai(0.01)
	assert_true(boss.is_phase_2, "Phase 2 aktiviert")
	boss.free()
