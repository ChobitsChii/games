# 🗝️ Plan 6 – Crypt Dash

**Genre:** Top-Down-Roguelite (Action) · **Modus:** Single Player · **Aufwand:** ⭐⭐⭐

## Idee
In einer prozedural erzeugten Gruft kämpft man sich durch Räume, sammelt Items und besiegt am Ende einen Boss. Jeder Durchlauf ist anders. Kurze Runs (10–15 Min.) passen gut zu einem kleinen Spiel.

## Kernmechanik
- Steuerung: WASD/Gamepad zum Laufen, Maus oder rechter Stick zum Zielen, Klick zum Schießen oder Zuschlagen, Leertaste zum **Dash** (kurze Unverwundbarkeit)
- Räume sind verbunden und verschlossen, bis alle Gegner besiegt sind
- Nach jedem Raum gibt es eine Belohnung: Herzen, Münzen oder eine Item-Wahl aus 3
- 3 Etagen mit je einem Boss, danach ein Sieg-Bildschirm
- Permadeath. Gesammelte "Seelen" schalten zwischen den Runs permanente Upgrades und neue Startwaffen frei.

## Gegner
| Gegner | Verhalten |
|---|---|
| Skelett | läuft auf den Spieler zu, Nahkampf |
| Bogenschütze | hält Abstand, schießt |
| Geist | schwebt durch Wände |
| Schleim | teilt sich beim Tod |
| Beschwörer | ruft kleine Gegner |
| Boss je Etage | eigene Angriffsmuster mit 2–3 Phasen |

## Items und Waffen (Beispiele)
Streuschuss · Piercing-Pfeile · Rückstoß-Schwert · Vampir-Biss (Lebensraub) · Schild-Aura · Kettenblitz · Mehr-Dash-Aufladungen · Magnet für Münzen

Items sind **datengetrieben** (`ItemData.tres` mit Modifikatoren auf Spielerwerte). Dadurch entstehen leicht Kombinationen.

## Technischer Entwurf
- **Level-Generierung:** Raster aus Räumen (zufälliger Walk oder BSP), jeder Raum aus handgebauten Layout-Vorlagen mit Gegner-Spawnpunkten
- **Seed:** Jeder Run hat einen sichtbaren Seed (wichtig zur Fehlerreproduktion)
- **Steuerung/Gegner:** `CharacterBody2D`, einfache Zustandsautomaten (`IDLE, CHASE, ATTACK, STUNNED`)
- **Navigation:** `NavigationAgent2D` (oder einfaches Steering, wo es reicht)
- **Räume:** `TileMapLayer` mit Terrain-Autotiles
- **Beleuchtung:** `PointLight2D` (funktioniert im Compatibility-Renderer) für Fackeln
- **Komponenten:** `HealthComponent`, `HitboxComponent`, `HurtboxComponent`
- **Event-Bus** (Autoload) für lose Kopplung: `enemy_died`, `room_cleared`, `item_picked`

```
scripts/gen/dungeon_generator.gd  scripts/gen/room_templates/*.tscn
scripts/entities/player.gd  enemies/*.gd  bosses/*.gd
scripts/data/item_data.gd  data/items/*.tres
autoload/ event_bus.gd  run_state.gd  save_service.gd
```

## Optik & Assets
**Stil:** Stilisierte, moderne Optik mit starkem Fokus auf **Licht und Schatten** in dunkler Gruft-Atmosphäre. **Kein Pixel-Art.** Handgemalt oder Flat-Vektor, kräftige Silhouetten, farbige Lichter und Nebel.

- **Palette:** Dunkles Violett und Blaugrün als Basis, warmes Orange für Fackeln, kräftige Akzentfarben für Gegner und Treffer
- **Grafik:** Hochauflösende Flat-Sprites oder gerenderte 3D-Modelle im Low-Poly-Stil (Kenney, Quaternius), die als 2D dargestellt oder in einer festen 3/4-Ansicht gerendert werden. Stil und Lizenz pro Paket prüfen. Ergänzend generierte Texturen für Böden und Wände.
- **Licht:** `PointLight2D` für Fackeln und Spieler, `LightOccluder2D` für Schatten, Nebel per Shader, Vignette
- **Effekte:** Schlag-Impact mit Hit-Stop, Dash-Nachbilder, Blutstaub/Seelenpartikel, Kamera-Shake, Boss-Intro mit Zeitlupe
- **Font:** Charakterstarker Display-Font für Titel, gut lesbarer Font für Text, beide mit Umlauten (OFL)
- **Audio:** Atmosphärische Musik (CC0/CC-BY), räumliche Effekte (Kenney, Freesound CC0)

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
1. **M0:** Setup aus Vorlage (`shared/`: Menü, Theme, `LocaleService` mit DE/EN-CSV, `DisplayService`/Vollbild, Credits) und Platzhalter-Optik
2. **M1:** Spielerbewegung, Dash, Schießen, ein Testraum
3. **M2:** Gegner-Grundlage mit 2 Typen, Schaden, Tod, Drops
4. **M3:** Dungeon-Generator mit Raumverbindungen, Türen und Minimap
5. **M4:** Item-System (10 Items) und Belohnungsräume
6. **M5:** Restliche Gegner und Boss 1
7. **M6:** Etagen 2 und 3, Bosse 2 und 3
8. **M7:** Meta-Fortschritt (Seelen und Freischaltungen) und Speichern
9. **M8:** Juice, Sound, Musik, Balancing, Export

## Hinweise zur Umsetzung
**Raumgröße:** 20 × 11 Kacheln à 64 px (1280 × 704 px), Türen in der Mitte jeder Seite. Der Spielbereich ist kleiner als der Bildschirm, die Kamera zeigt zusätzlich Dekoration außen.

**Dungeon-Generator (pro Etage, mit eigenem RNG `seed + etage * 1000`):**
1. Raster 7 × 7, Startraum in der Mitte.
2. Raumanzahl `7 + etage * 2`: wiederholt einen zufälligen vorhandenen Raum wählen und ein zufälliges freies Nachbarfeld nehmen, das höchstens einen belegten Nachbarn hat (vermeidet Klumpen).
3. Bossraum = per Breitensuche entferntester Raum, Schatzraum = ein Sackgassen-Raum (nur eine Tür), alle anderen sind Kampfräume.
4. Türen entstehen zwischen benachbarten belegten Räumen. Jeder Kampfraum nimmt eine zufällige Vorlage aus `room_templates/` mit Spawnpunkten.
5. Test: Breitensuche über 1000 Seeds muss alle Räume erreichen, gleicher Seed ergibt gleiches Layout.

**Spieler:** 6 Herzen (12 halbe), Geschwindigkeit 420 px/s, Dash 0,18 s mit 1400 px/s und Unverwundbarkeit, Abklingzeit 0,8 s, Schussrate 0,3 s, Schaden 1.

**Item-Modifikatoren:** `ItemData` hat `stat_adds` und `stat_muls` (Dictionary von Wertname auf Zahl). Endwert = `(Basis + Summe der Zuschläge) × Produkt der Faktoren`. Die Berechnung liegt in einer eigenen Klasse ohne Nodes und wird getestet (Stapeln, Reihenfolge, Obergrenzen).

**Gegner:** Zustandsautomat `IDLE → CHASE → ATTACK → STUNNED → DEAD` in einer gemeinsamen Basisklasse, Unterklassen überschreiben nur das Verhalten. Einfaches Steering (direkt zum Spieler, Wände meiden) reicht. `NavigationAgent2D` nur, wenn Gegner an Hindernissen hängen.

**Bosse:** Jeder Boss hat 2–3 Phasen mit eigenen Angriffsmustern. Die Muster sind Listen von Schritten (`{aktion, dauer}`), damit sie sich testen lassen. Ein Test lässt jeden Boss alle Phasen durchlaufen.

**Meta-Fortschritt:** Seelen (aus Gegnern) werden am Ende des Runs gespeichert und schalten Upgrades und Startwaffen frei (`SaveService`, Abschnitt `meta`).

**Umfang begrenzen:** Erst eine spielbare Etage mit 2 Gegnertypen, 5 Items und Boss 1 (M1–M5). Danach erst Etagen 2 und 3 und die restlichen Inhalte.

### Abnahmekriterien
- [ ] Ein kompletter Run (3 Etagen, 3 Bosse) ist spielbar und gewinnbar
- [ ] Generator-Tests für 1000 Seeds grün, Seed im Spiel sichtbar
- [ ] Mindestens 15 Items, 6 Gegnertypen, 3 Bosse
- [ ] Meta-Fortschritt bleibt nach Neustart erhalten
- [ ] Licht und Schatten sehen auch im Web-Build gut aus, 60 FPS
- [ ] Smoke-Test: Bot läuft durch Etagen ohne Fehler

## Tests
- Generator: Alle Räume sind erreichbar (Graph-Test über 1000 Seeds)
- Gleicher Seed ergibt exakt dasselbe Layout
- Item-Modifikatoren stapeln korrekt
- Boss-Zustandsautomat durchläuft alle Phasen
- Smoke-Test: Bot läuft zufällig durch 3 Etagen ohne Fehler

## Risiken
- Umfang wächst schnell → Feature-Freeze nach M6, erst eine spielbare Vertikale, dann Inhalt
- Navigation und Kollision im Web → früh im Web-Build testen

## Erweiterungsideen
Mehr Klassen mit eigenen Fähigkeiten, Daily Seed, Händler-Raum, Fallen und Geheimräume, Co-op (später)
