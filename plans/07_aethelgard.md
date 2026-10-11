# 🗡️ Plan 7 – Aethelgard: Echoes of the Forgotten Isle

**Genre:** Action-Adventure / Top-Down-RPG · **Modus:** Single Player · **Aufwand:** ⭐⭐⭐⭐  
**Inspiration:** Klassische 2D-Zelda-Titel (*A Link to the Past*, *Minish Cap*, *Link's Awakening*), *CrossCode*, *Death's Door* – jedoch mit **vollständig eigenständiger Lore, eigener Welt und modernen, hochauflösenden Grafiken mit flüssigen Bewegungsanimationen (kein Pixel-Art)**.

---

## 1. Idee & Spielvision

Der Spieler schlüpft in die Rolle von **Kaelen** (oder wählbar **Lyra**), einer jungen Relikt-Sucherin und Kartografin auf dem mystischen Archipel von **Aethelgard**. Einst hielten vier uralte Archon-Wächter und deren kristallene **Prismer-Siegel** das Reich im Gleichgewicht. Nach einem verheerenden Äther-Beben sind die Siegel in versunkenen Schreinen verloren gegangen, uralte Golem-Konstrukte laufen Amok und eine dunkle Korruption breitet sich aus.

Das Spiel fängt die Essenz großer 2D-Action-Adventures ein:
1. Eine handgebaute, zusammenhängende Oberwelt mit Geheimnissen, Höhlen und NPCs.
2. Mehrere thematische Dungeons voller Rätsel, Schalter und verschlossener Türen.
3. Neue Werkzeuge und Gadgets (Bumerang, Greifhaken, Schallbomben), die sowohl im Kampf als auch zur Erschließung neuer Weltbereiche unverzichtbar sind (Metroidvania-Fortschritt).
4. Reaktiver, flotter Echtzeit-Schwertkampf mit Schild-Parry, Ausweichrolle und Gadget-Combos.
5. Herausfordernde Bosskämpfe mit klaren Angriffsphasen und Telegraphen.

---

## 2. Rechtliche Eigenständigkeit (Nintendo-Safe & Original IP)

Um Marken-, Urheber- und Designschutzkonflikte mit Nintendo strikt auszuschließen, sind alle Namen, Figuren, Symbole und Spielobjekte von Grund auf eigenständig gestaltet:

| Element | Klassisches Zelda-Trope | Aethelgard (Unser Original-Design) |
|---|---|---|
| **Schauplatz** | Hyrule / Königreich | **Das Archipel von Aethelgard** (mystische Inselwelt mit schwebenden Riff-Inseln und versunkenen Ruinen) |
| **Held/Protagonist** | Link (grüne Tunika, Zipfelmütze, blonde Elfenohren) | **Kaelen / Lyra**: Junger Relikt-Kundschafter im wetterfesten Reise-Abenteurer-Look (braune Lederweste, bronzener Schulterschutz, dunkelblauer Reisemantel/Schal, Messing-Schnallen und ein mechanischer Äther-Armreif; menschliche Silhouette) |
| **Zentrales Artefakt** | Triforce (drei goldene Dreiecke) | **Die 4 Prismer-Siegel (Prismatic Sigils)**: Vier facettierte, farbige Kristall-Orbs (Sonne/Gold, Flut/Cyan, Sturm/Smaragd, Erde/Violett), die in uralte Sockel eingesetzt werden |
| **Hauptwaffe** | Master-Schwert (blau-violetter Flügel-Griff) | **Die Äther-Klinge (Aether Blade)**: Eine aus Sternenbronze geschmiedete Runenklinge mit leuchtenden Adern, die magische Resonanzstöße abfeuern und aufgeladen werden kann |
| **Währung** | Rubine (grüne/rote/blaue Diamanten) | **Aether-Scherben / Kristalle**: Geometrische, leuchtende Äther-Kristalle in Blau (1), Amber-Gold (5) und Purpur (20) |
| **Lebensanzeige** | Rote Herzen / Herzteile | **Vitalitäts-Sphären (Vitality Orbs)**: Geteilte magische Amulette (4 Viertel pro Sphäre). 4 gefundene Sphären-Fragmente erweitern die maximale Lebenskraft |
| **Schild** | Hylia-Schild (blau mit rotem Vogel) | **Wächterschild (Aegis of the Spire)**: Runder Bronzeschild mit blauem Kristallkern. Ermöglicht **Parry** (reflektiert Schüsse) und normales Blocken |
| **Gefäß-Zerstörung** | Töpfe / Krüge zerschlagen | **Antike Tonkrüge, Holzkisten, Kristallgeoden und dichtes Rankengestrüpp** |
| **Antagonist** | Ganon / Ganondorf | **Malakor, der Rissfürst**: Ein korrumpierter Ur-Archon aus zerborstenem Stein und instabiler violetter Äther-Energie |

---

## 3. Optik, Assets & Animations-Pipeline

### 3.1 Grafikstil: Modern, Hochauflösend, Kein Pixel-Art
- **Basisauflösung:** 1920 × 1080 (`canvas_items`, `keep`), Linear-Filtering (`texture_filter = LINEAR`).
- **Look:** Malerisch-illustrierter, moderner Comic-/Fantasy-Stil (vergleichbar mit hochwertigen handgezeichneten 2D-Titeln wie *Hollow Knight*, *Ori*, *CrossCode* oder den Artworks in *Lane Defenders*). Klare Silhouetten, weiche Farbverläufe, dezente Normal- und Glanz-Highlights, kein einziger Pixel-Art-Block.
- **Atmosphäre & Licht:** Warme Sonnenstrahlen im Wald, schimmernde Wasser-Reflexionen an den Küsten, mystisches Fackellicht und leuchtende Runen in den Dungeons (`PointLight2D` und CanvasItem-Materialien im `gl_compatibility`-Renderer).

### 3.2 Die Animations-Pipeline: Lebendige Figuren statt statischer Bilder
Wie vom Nutzer gewünscht, dürfen Figuren **keine statischen Schiebe-Bilder** sein. Jede Spielfigur (Spieler, Gegner, NPCs, Bosse) verfügt über echte Bewegungszyklen:

1. **High-Resolution 4-Wege-Spritesheets (`AnimatedSprite2D` / `AnimationPlayer`):**
   - Jede Richtung (Runter/Front, Rauf/Rücken, Links, Rechts) besitzt eigene Frames in hoher Auflösung (z. B. 256×256 oder 384×384 px pro Frame).
   - **Animationen pro Figur:**
     - `idle` (4 Frames): Sanftes Atmen, Wippen der Knie, Wehen des Umhangs.
     - `walk` (6–8 Frames): Vollständiger Schrittzyklus mit sichtbarer Beinarbeit, Armschwung und Fußaufsetzen.
     - `attack_slash` (4 Frames): Dynamischer Hieb mit Lichtbogen-Trail und Gewichtsverlagerung.
     - `roll / dash` (4–6 Frames): Geschmeidige Ausweichrolle über den Boden mit Bewegungsunschärfe / After-Image-Ghosting.
     - `hurt` (2 Frames): Rückstoß mit Schreck-Pose und weißem Flash.
     - `lift / throw` (3 Frames): Heben von Krügen oder Felsen über den Kopf und kraftvolles Werfen.
2. **Dynamische Schritt-Synchronisation (Anti-Foot-Sliding):**
   - Die Abspielgeschwindigkeit der `walk`-Animation passt sich stufenlos an die tatsächliche Bewegungsgeschwindigkeit an (`animation_player.speed_scale = current_speed / base_speed`).
   - Dadurch entsteht niemals der Eindruck, die Figur würde über das Eis gleiten.
3. **Prozedurale Sekundär-Animationen (Godot-Juice):**
   - **Körper-Neigung (Tilt):** Leichte Drehung des Sprites um 3–6 Grad in Laufrichtung beim Beschleunigen.
   - **Squash & Stretch:** Minimales vertikales Stauchen (0.95y, 1.05x) beim Fußauftritt und Strecken (1.05y, 0.95x) beim Rollen-Absprung.
   - **Dynamischer Bodenschatten:** Runder, weicher Drop-Shadow unter der Figur, der sich bei Sprüngen/Rollen realistisch verkleinert.
   - **Partikel:** Kleine Staubwölkchen (`GPUParticles2D`) an den Füßen beim Wenden und Rollen, Grashalme beim Durchqueren von Wiesen.

---

## 4. Kernmechaniken & Gameplay

### 4.1 Steuerung & Bewegung
- **Laufen:** 8-Wege-Bewegung mit Analogstick oder WASD / Pfeiltasten (weiche Beschleunigung und Stoppen).
- **Ausweichrolle (Dash):** Kurzer, schneller Satz nach vorne mit Unverwundbarkeits-Frames (i-frames). Verbraucht einen kleinen Teil des Ausdauerbalkens (Stamina).
- **Interaktion:** Taste E / Gamepad-A (Sprechen mit NPCs, Lesen von Schildern, Öffnen von Truhen, Aufheben von Krügen/Steinen).

### 4.2 Kampfsystem
- **Schwertkampf:**
  - 1er-, 2er-, 3er-Schlag-Kombo (Schräghieb, Rückhand, kräftiger Vorstoß).
  - **Wirbelattacke (Spin Attack):** Angriffstaste gedrückt halten, um die Äther-Klinge aufzuladen. Beim Loslassen trifft ein 360°-Rundumschlag alle umstehenden Gegner.
  - **Resonanzstoß:** Bei voller Lebensenergie schießt jeder normale Schwerthieb eine kleine magische Schockwelle nach vorne.
- **Wächterschild (Block & Parry):**
  - Taste halten: Reduziert Schaden von vorne um 80 % und blockt Standard-Pfeile ab.
  - **Präzises Parieren (Just-Defend):** Schild im Moment des Treffers heben reflektiert Projektile direkt zurück zum Schützen und betäubt Nahkampf-Gegner für 1,5 Sekunden!

### 4.3 Gadgets & Werkzeuge (Metroidvania-Ausrüstung)
Zwei frei belegbare Schnellzugriff-Slots (Q/E auf Tastatur, X/Y auf Gamepad):

| Gadget | Fundort | Funktion im Kampf | Funktion bei Rätseln / Erkundung |
|---|---|---|---|
| **Äther-Bumerang** | Wurzel-Schrein (Dungeon 1) | Betäubt Feinde auf Distanz, fängt fliegende Insekten | Aktiviert Schalter über Abgründen, holt schwimmende Kristalle heran |
| **Fangseil (Kinetic Tether)** | Klingen-Krypta (Dungeon 2) | Zieht leichte Gegner heran, entreißt gepanzerten Feinden den Schild | Zieht den Spieler zu Holzpfählen und Kletterringen über tiefe Klüfte |
| **Schall-Bomben** | Sturm-Bastion (Dungeon 3) | Hoher Flächenschaden, wirft schwere Golems um | Sprengt rissige Felswände frei, öffnet geheime Höhlen und Schalter |
| **Prisma-Bogen** | Oberwelt-Quest (Jägerin) | Zielsicherer Fernkampf mit aufladbaren Pfeilen | Entzündet Feuerschalen durch Flammen hindurch, trifft ferne Zielscheiben |
| **Titanen-Armreif** | Versunkene Mine | Erlaubt Werfen schwerer Projektile auf Gegner | Hebt massive Steinblöcke, um geheime Eingänge freizulegen |

---

## 5. Spielwelt & Dungeons

### 5.1 Die Oberwelt von Aethelgard
Eine verbundene, handgebaute Welt mit Zonenübergängen und Raumkameras (flüssige Begrenzung per `Camera2D` mit Raum-Bounds):

1. **Oakhaven (Dorf Eichenhafen):**
   - Friedliche Ausgangsbasis mit Marktplatz, Brunnen und Windmühle.
   - **Waffenschmied:** Schärft die Klinge (mehr Schaden) gegen gesammelte Erze und Kristalle.
   - **Alchemieladen:** Verkauft Heiltränke und Elixiere für leere Relikt-Fläschchen.
   - **Kartografen-Gilde:** Verkauft Regionskarten und markiert Geheimnis-Gerüchte.
2. **Smaragdhain (Verdant Grove):**
   - Sonniger Wald mit Wildschweinen, Schlingpflanzen, Bächen und ersten Geheimhöhlen.
3. **Flüsternde Klippen & Untiefen (Sunken Shallows):**
   - Salzige Küstenlinie, Sandstrände, Gezeitentümpel, Schiffswracks und Höhlensysteme.
4. **Donnerplateau (Echoing Crags):**
   - Windzerzauste Höhen, antike Brücken, Golem-Wächter und tiefe Schluchten.

### 5.2 Die Dungeons
Jeder Dungeon hat eine einzigartige Identität, einen eigenen Soundtrack, ein zentrales Schlüssel-Item und einen Boss:

| Dungeon | Thema / Element | Zentrales Gadget | Rätsel-Mechaniken | Boss |
|---|---|---|---|---|
| **1. Wurzel-Schrein** | Überwucherte Natur & Wasser | **Äther-Bumerang** | Schalter hinter Gittern, Flut-Tore öffnen, Ranken durchtrennen | **Floragorg, Urwald-Koloss** (Greift mit Tentakeln an; Bumerang betäubt Schwachpunkt) |
| **2. Klingen-Krypta** | Versunkene Festung & Tiefe | **Fangseil (Greifhaken)** | Pfahl-Sprünge über Stachelfallen, Schalter im Takt, Schilde entreißen | **Carapax, Kristall-Panzerkrabbler** (Unverwundbar von vorn; Fangseil zieht ihn um) |
| **3. Sturm-Bastion** | Wind, Mechanik & Höhe | **Schall-Bomben** | Windtunnel-Timing, rotierende Plattformen, brüchige Wände | **Zephyros, die Sturmkrone** (Fliegender Raubvogel-Golem; Bomben brechen Windschild) |
| **4. Der Äther-Turm (Finale)** | Äther-Kristalle & Leere | Alle Gadgets vereint | Anspruchsvolle Multitool-Rätsel, Raum-für-Raum-Prüfungen | **Malakor, der Rissfürst** (3 Phasen: Schwertduell → Kristallform → Äther-Koloss) |

---

## 6. Gegner-Design & KI

Alle Gegner basieren auf einem modularen Zustandsautomaten (`IDLE → PATROL → ALERT → CHASE → ATTACK → STUNNED → DEAD`):

| Gegner | Verhalten & Angriff | Besonderheit / Schwäche |
|---|---|---|
| **Moos-Scout (Kobold)** | Patrouilliert mit Dolch, rennt auf Spieler zu | Kann mit Schild geblockt werden; 3 Schläge |
| **Dornen-Spucker** | Stationäre Fleischfresser-Pflanze, spuckt Säurekugeln | Schüsse können mit Schild reflektiert werden |
| **Knochen-Krieger** | Trägt Holzschild, blockt Frontalangriffe | Mit Ausweichrolle umrunden oder Schild mit Bumerang/Fangseil wegziehen |
| **Fledermaus-Konstrukt** | Flattert im Zickzack, greift aus der Luft an | Empfindlich gegen Bumerang und Bogenschüsse |
| **Äther-Golem** | Schwerer Felsen-Gegner, stampft auf den Boden (Schockwelle) | Langsam, Schwachpunkt am Rücken, anfällig für Schall-Bomben |

---

## 7. Technischer Entwurf & Software-Architektur

### 7.1 Trennung von Logik (`RefCounted`) und Darstellung (`Nodes`)
Damit Spiellogik wie in allen Projekten dieses Repositories **vollständig unit-testbar** bleibt (ohne Szenenbaum), wird die Engine strikt nach MVC/Komponenten getrennt:

- `scripts/core/combat_calculator.gd` (`RefCounted`):
  - Berechnet Schaden, Kritische Treffer, Schadensreduktion durch Schilde, Resonanz-Multiplikatoren und Knockback-Vektoren.
- `scripts/core/inventory_model.gd` (`RefCounted`):
  - Verwaltet Kristalle, Schlüssel (normale Schlüssel verfallen im Dungeon, Generalschlüssel), gefundene Herzteile, Tränke und ausgerüstete Gadgets.
- `scripts/core/quest_manager.gd` (`RefCounted`):
  - Verwaltet Quest-IDs, Zustände (`UNSTARTED, ACTIVE, COMPLETED`), Quest-Ziele und Belohnungen.
- `scripts/core/dungeon_state.gd` (`RefCounted`):
  - Hält fest, welche Truhen geöffnet, welche Türen aufgeschlossen und welche Schalter dauerhaft umgelegt wurden.

### 7.2 Szenen & Knoten-Hierarchie
```
aethelgard/
├── project.godot
├── scenes/
│   ├── main_menu.tscn, pause_menu.tscn, credits.tscn, game_over.tscn
│   ├── world/
│   │   ├── overworld.tscn, camera_bounds.tscn, transition_trigger.tscn
│   │   ├── oakhaven.tscn, verdant_grove.tscn, sunken_shallows.tscn
│   │   └── dungeons/ (shrine_roots.tscn, sunken_vault.tscn, gale_bastion.tscn, aether_spire.tscn)
│   ├── entities/
│   │   ├── player/ (player.tscn, sword_slash.tscn, shield.tscn)
│   │   ├── enemies/ (goblin.tscn, spitter.tscn, skeleton.tscn, bat.tscn, golem.tscn)
│   │   ├── bosses/ (boss_floragorg.tscn, boss_carapax.tscn, boss_zephyros.tscn, boss_malakor.tscn)
│   │   └── npcs/ (blacksmith.tscn, elder.tscn, merchant.tscn, hunter.tscn)
│   ├── objects/
│   │   ├── chest.tscn, destructible_pot.tscn, pushable_block.tscn, door.tscn, switch_crystal.tscn
│   │   └── collectibles/ (crystal_drop.tscn, heart_drop.tscn, key_drop.tscn)
│   └── ui/
│       ├── hud.tscn (Vitalitäts-Sphären, Kristalle, Ausdauer, Slot Q & E)
│       ├── dialogue_box.tscn (Porträt, Text, Auswahl)
│       └── inventory_screen.tscn (Kartenansicht, Questlog, Ausrüstungs-Auswahl)
├── scripts/
│   ├── core/ (combat_calculator.gd, inventory_model.gd, quest_manager.gd, dungeon_state.gd)
│   ├── components/ (health_component.gd, hitbox_component.gd, hurtbox_component.gd, interaction_component.gd)
│   ├── entities/ (player.gd, enemy_base.gd, npc_base.gd, boss_base.gd)
│   └── ui/ (hud.gd, dialogue_box.gd, inventory_screen.gd)
├── assets/
│   ├── characters/ (player/, enemies/, bosses/, npcs/ – jeweils animierte Spritesheets)
│   ├── environments/ (tilesets/, props/, background_layers/)
│   ├── portraits/ (high-res Porträts mit Emotionen)
│   ├── ui/ (icons/, frames/, cursors/)
│   └── audio/ (sfx/, music/ mit CC0/CC-BY Lizenzen)
├── i18n/
│   └── aethelgard.csv (keys,de,en)
└── tests/
    ├── run_tests.gd, test_case.gd, smoke.tscn
    ├── test_combat.gd, test_inventory.gd, test_quests.gd, test_dungeon_state.gd, test_i18n.gd
```

### 7.3 Speichersystem & Checkpoints (`SaveService`)
- Das Spiel speichert nahtlos im `user://savegame.cfg` über den gemeinsamen `SaveService`.
- 3 unabhängige Spielstände (Slot 1, 2, 3) wählbar im Hauptmenü.
- **Gespeicherte Daten:**
  - Spieler: Max. HP, aktuelle HP, gesammelte Sphären-Fragmente, Kristalle.
  - Ausrüstung: Freigeschaltete Gadgets, Schwert-Stufe, Tränke.
  - Welt-Zustand: Dictionary aller geöffneten Truhen-IDs (`chest_101: true`), besiegter Bosse und aktivierter Schnellreise-Stelen.
  - Quests: Aktueller Fortschritt aller Haupt- und Nebenquests.

---

## 8. Lokalisierung, Vollbild & Barrierefreiheit

- **Keine festen Texte:** Sämtliche Dialogzeilen, Item-Beschreibungen, Menü-Einträge und HUD-Labels liegen in `i18n/aethelgard.csv` (`keys,de,en`).
- **Längere Texte:** Textboxen und Container unterstützen automatischen Zeilenumbruch (`autowrap_mode = WORD_SMART`) und passen sich dynamisch an, da deutsche Texte erfahrungsgemäß 20–30 % länger als englische sind.
- **Display & Audio:** Nutzung von `DisplayService` (F11, echtes Vollbild/Fenstermodus, Skalierungsfilter) und `AudioService` (getrennte Regler für Master, Musik, Soundeffekte).
- **Steuerung:** Voller Support für Gamepad (Xbox, PlayStation, Switch-Layouts mit dynamischen Glyphen) und Tastatur + Maus.

---

## 9. Meilensteine

1. **M0 – Grundgerüst & Setup:**
   - Projektverzeichnis `aethelgard/` mit Vorlagen aus `shared/` (`project.godot`, Autoloads `DisplayService`, `LocaleService`, `SaveService`, Theme, Input-Map, Export-Presets).
   - Test-Runner und Smoke-Test-Grundlage.
2. **M1 – Spieler-Controller & Bewegungsanimationen:**
   - 8-Wege-Bewegung mit Analog-Stick und WASD.
   - Hochauflösende Richtungs-Animationen (`idle`, `walk` in 4 Richtungen, `roll/dash`).
   - Schritt-Synchronisation, Neigungs-Tilt und Staubpartikel.
3. **M2 – Kampf-Grundlagen & Treffer-Feedback:**
   - Äther-Klinge: 3er-Schlag-Kombo, aufladbarer Rundumschlag, Waffen-Trail.
   - Wächterschild: Blocken und Parry-Fenster.
   - Trefferfeedback: Sprite-Flash, Hit-Stop (Micro-Pause), Screen-Shake, Rückstoß (Knockback).
4. **M3 – Erste Spielwelt (Oakhaven) & Dialogsystem:**
   - Dorf Oakhaven mit Wegen, Häusern, Bäumen und dekorativen Objekten.
   - Raumkamera mit weichen Begrenzungen (`Camera2D`).
   - Dialogbox mit High-Res-NPC-Porträts, Schreibmaschinen-Effekt, Audio-Blips und Auswahlfragen.
   - Zerstörbare Krüge und Gras mit zufälligen Kristall-/Herz-Drops.
5. **M4 – Gegner-KI & Erstes Gadget:**
   - 3 Standard-Gegner (Moos-Scout, Dornen-Spucker, Knochen-Krieger) mit vollen 4-Wege-Animationen.
   - Fund des **Äther-Bumerangs**: Wurfphysik, Rückkehrkurve, Betäubung von Gegnern und Schalteraktivierung.
   - Inventar- und Ausrüstungs-Menü.
6. **M5 – Dungeon 1: Der Wurzel-Schrein & Boss 1:**
   - Vollständiger Dungeon mit 8 Räumen, verschlossenen Türen, Schaltern, Wasser-Schleusen und Kisten-Rätseln.
   - Kleiner Schlüssel und Boss-Schlüssel.
   - Bosskampf gegen **Floragorg, den Urwald-Koloss** (Zwei Phasen, Bodenranken, Schwachpunkt-Mechanik).
   - Belohnung: Erstes Prismer-Siegel (Sonnensiegel) & Vitalitäts-Sphäre.
7. **M6 – Gadget 2 (Fangseil) & Dungeon 2 (Klingen-Krypta):**
   - Erweiterung der Oberwelt um die *Flüsternden Untiefen*.
   - Fund des **Fangseils**: Überqueren von Abgründen, Heranziehen von Schildfeinden.
   - Dungeon 2 mit Stachelfallen und Pfahl-Klettereien.
   - Bosskampf gegen **Carapax, den Kristall-Panzerkrabbler**.
8. **M7 – Gadget 3 (Bomben), Dungeon 3 & Das Finale:**
   - Fund der **Schall-Bomben**, Freisprengung geheimer Höhlen auf der Oberwelt.
   - Dungeon 3 (Sturm-Bastion) mit Windrätseln und Boss **Zephyros**.
   - Der finale **Äther-Turm** mit Multitool-Prüfungen.
   - Showdown gegen **Malakor, den Rissfürst** (3 epische Phasen mit Raumveränderungen).
   - Abspann, Sieges-Bildschirm, Post-Game-Erkundung.
9. **M8 – Polish, Audio, Balancing & Release:**
   - Soundeffekte für alle Aktionen, atmosphärische Musik-Tracks.
   - Balancing der Gegner-HP, Schadenswerte und Kristallkosten.
   - Autopilot-Smoke-Test (Bot läuft durchs Dorf, öffnet Truhen, besiegt Gegner).
   - Export für Linux, Windows und Web. Release `v1.0.0`.

---

## 10. Hinweise zur Umsetzung & Balancing-Tabellen

### 10.1 Spieler-Werte
- **Start-Lebensenergie:** 3 Vitalitäts-Sphären (12 Viertel).
- **Laufgeschwindigkeit:** 240 px/s (Basis), Dash: 520 px/s über 0,25 Sekunden.
- **Ausdauer (Stamina):** 100 Punkte (Dash kostet 25 Punkte, regeneriert sich in 1,2 s voll auf).
- **Schwertschaden:** Stufe 1 = 20 HP, Stufe 2 = 35 HP, Stufe 3 = 55 HP.
- **Unverwundbarkeit nach Treffer (i-frames):** 0,65 Sekunden mit sichtbarem Blinken (Modulate Alpha 0.4).

### 10.2 Gegner-Werte
| Gegner | HP | Tempo | Schaden | Angriff | Besonderheit |
|---|---|---|---|---|---|
| **Moos-Scout** | 40 | 160 px/s | 1 Viertel | Dolchstich (1,0 s Telegraf) | Kann taumeln |
| **Dornen-Spucker** | 30 | 0 px/s | 1 Viertel | Säureprojektil (alle 2,2 s) | Reflektierbar mit Parry |
| **Knochen-Krieger** | 80 | 120 px/s | 2 Viertel | Schwertschwung | Frontal immun bei gehobenem Schild |
| **Fledermaus** | 20 | 200 px/s | 1 Viertel | Sturzflug-Attacke | Weicht im Zickzack aus |
| **Äther-Golem** | 180 | 90 px/s | 3 Viertel | Bodenschlag (Flächen-Schockwelle) | Rüstung bricht durch Bomben |
| **Boss 1: Floragorg** | 600 | 60 px/s | 2 Viertel | Rankenpeitsche, Samenbomben | Bumerang öffnet Kern für 3 s |
| **Boss 2: Carapax** | 900 | 80 px/s | 2 Viertel | Scherenstich, Wasserstrahl | Fangseil wirft ihn auf den Rücken |
| **Boss 3: Zephyros** | 1200 | 210 px/s | 2 Viertel | Windsturm, Federklingen | Bomben bringen ihn zum Absturz |
| **Endboss: Malakor** | 2000 | 180 px/s | 3 Viertel | Äther-Schwert, Rissblitze, Meteor | 3 distinkte Phasen |

### 10.3 Raum- und Kachelgrößen
- **Kachelgröße:** 64 × 64 px (bzw. Props in 128×128 / 256×256 px hochauflösend).
- **Bildschirmbereich:** 1920 × 1080 px (entspricht 30 × 17 Kacheln).
- **Dungeon-Räume:** Standardräume sind 1–2 Bildschirme groß (30×17 oder 60×34 Kacheln) mit klaren Tor- und Wandgrenzen.

---

## 11. Abnahmekriterien (Definition of Done)

- [ ] Vollständige Handlung spielbar: Von Oakhaven über die 3 Elementar-Schreine bis zum Äther-Turm und Abspann.
- [ ] Alle Spielfiguren und Gegner besitzen saubere, hochauflösende 4-Wege-Bewegungsanimationen ohne Gleiten.
- [ ] Kein einziges Pixel-Art-Asset; alle Grafiken modern, hochauflösend und mit linearem Texturfilter.
- [ ] Strikt Nintendo-safe: Keine geschützten Namen, Symbole oder 1:1-Formen.
- [ ] Echtes Metroidvania-Gameplay: 3 funktionierende Gadgets (Bumerang, Fangseil, Schall-Bomben), die neue Wege öffnen.
- [ ] Schildblock und reaktives Parieren funktionieren präzise.
- [ ] Dialogsystem mit Porträts, Schreibmaschinen-Animation und funktionierendem Quest-Log.
- [ ] 3 speicherbare Spielstände via `SaveService`, Checkpoints und Truhen-Persistenz.
- [ ] 100 % zweisprachig (DE / EN) über `i18n/aethelgard.csv`, alle Tests in `tests/test_i18n.gd` grün.
- [ ] Stabile 60 FPS im Web-Build (`gl_compatibility`), kein Ruckeln bei Dutzenden Partikeln oder Gegnern.
- [ ] Smoke-Test (`tests/smoke.tscn`) läuft headless fehlerfrei durch.

---

## 12. Tests

- **`test_combat.gd`:** Schadensberechnung, Waffenupgrades, Schildblock-Reduktion, Parry-Reflexion, Resonanz-Schockwelle.
- **`test_inventory.gd`:** Item-Aufnahme, Höchstgrenzen (Bomben/Pfeile), Ausrüsten von Gadget-Slots Q/E, Sphären-Fragment-Zusammensetzung (4 Fragmente = +1 Max HP).
- **`test_quests.gd`:** Fortschreiten von Questphasen, Belohnungsausschüttung, Sperren unerlaubter Sequenzen.
- **`test_dungeon_state.gd`:** Schlüsselverwendung, Öffnen von Truhen (kein doppelter Loot nach Neuladen), Schalterzustände.
- **`test_i18n.gd`:** Vollständigkeit aller Sprachschlüssel in Deutsch und Englisch, keine fest verdrahteten Strings in `.tscn`.
- **`tests/smoke.tscn`:** Autopilot läuft durch Räume, interagiert mit NPCs, schwingt das Schwert und betritt Dungeons ohne Abstürze.

---

## 13. Risiken & Gegenmaßnahmen

1. **Großer Umfang (RPG-Feature-Creep):**
   - *Gegenmaßnahme:* Strenge vertikale Scheibe! Zuerst M0 bis M5 komplett fertigstellen (Dorf + 1 Dungeon + Bumerang + 1 Boss). Erst wenn dieser Slice absolut rund, flüssig und perfekt poliert ist, werden die restlichen Dungeons hinzugefügt.
2. **Animationen ohne Pixel-Art erfordern viele Frames:**
   - *Gegenmaßnahme:* Sauberes Spritesheet-Layout mit 4-Wege-Frames (Down, Up, Side mit H-Flip für Left/Right); Ergänzung durch prozedurales Wippen, Neigen und dynamische Schatten, um maximale Geschmeidigkeit bei überschaubarer Framezahl zu garantieren.
3. **Web-Performance bei großen Tilemaps:**
   - *Gegenmaßnahme:* `TileMapLayer` nutzen, Zonen in handliche Einzelszenen unterteilen (Szenenwechsel beim Betreten von Dungeons und Häusern) statt einer riesigen monolithischen Welt.

---

## 14. Erweiterungsideen (Post-Launch)

- New Game+ mit gespiegelter Welt, höherem Gegnerschaden und alternativen Rätsellösungen.
- Boss-Rush-Arena im Dorf Oakhaven.
- Angeln als Minispiel an den Küsten der Flüsternden Untiefen.
- Versteckte Relikt-Schreine mit speziellen Kosmetika (alternative Mäntel und Klingen-Skins).
