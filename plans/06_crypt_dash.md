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
