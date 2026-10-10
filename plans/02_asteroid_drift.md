# ☄️ Plan 2 – Asteroid Drift

**Genre:** Arcade-Shooter (Asteroids-Like) · **Modus:** Single Player · **Aufwand:** ⭐⭐

## Idee
Ein Raumschiff mit Trägheitsphysik schwebt durch ein Asteroidenfeld. Das Spiel erweitert das klassische Konzept um ein **Upgrade-System zwischen den Wellen** und **Gegner-UFOs** mit einfacher KI.

## Kernmechanik
- Schiff drehen und Schub geben (Trägheit, leichte Dämpfung)
- Schießen mit begrenzter Feuerrate, Projektile haben Lebensdauer
- Der Bildschirmrand wickelt um (Wrap-around)
- Asteroiden zerfallen in kleinere (groß → mittel → klein)
- Wellenbasiert: Pro Welle mehr und schnellere Asteroiden
- **Hyperspace:** zufälliger Teleport mit Risiko
- **Schild:** lädt sich langsam auf, fängt einen Treffer ab

## Gegner
| Gegner | Verhalten |
|---|---|
| Kleines UFO | schießt gezielt auf den Spieler, schnell, wenig HP |
| Großes UFO | schießt zufällig, langsam |
| Mine (ab Welle 5) | folgt dem Spieler langsam, explodiert in der Nähe |

## Upgrade-System (nach jeder 3. Welle: Wahl aus 3 zufälligen Karten)
Doppelschuss · Streuschuss · Schnellere Feuerrate · Stärkerer Schild · Magnet (zieht Drops an) · Explosive Schüsse

## Technischer Entwurf
- **Schiff:** `RigidBody2D` oder `CharacterBody2D` mit eigener Geschwindigkeit. Eigene Integration ist besser kontrollierbar.
- **Wrap-around:** zentraler Helfer `wrap_position(pos, rect)`
- **Asteroiden:** prozedural generierte Polygone (`Polygon2D` + `CollisionPolygon2D`), Seed pro Asteroid
- **Objekt-Pooling** für Projektile und Partikel (wichtig für Web-Performance)
- **Spawner:** `WaveDirector` mit Wellen als Ressourcen (`WaveData.tres`)
- **Vektor-Optik:** `Line2D` mit Glow, passend zum Neon-Stil

```
scenes/  ship.tscn  asteroid.tscn  bullet.tscn  ufo.tscn  wave_director.tscn  upgrade_picker.tscn
scripts/ ship.gd  asteroid.gd  ufo.gd  wave_director.gd  upgrades.gd  screen_wrap.gd
```

## Optik & Assets
**Stil:** Modernes Sci-Fi im flachen Vektor-Look mit Glow und Tiefe, **ohne Pixel-Art**. Mehrschichtiger Weltraumhintergrund mit Parallax (Sterne, Nebel per Shader). Asteroiden mit weichen Verläufen und Licht von einer Seite.

- **Palette:** Tiefes Blau/Schwarz, Orange und Cyan für Triebwerke und Schüsse, Rot für Gefahr
- **Grafik:** Raumschiffe und UFOs als Vektor- oder Flat-Sprites (z. B. aus Kenney-Weltraumpaketen im Flat-Stil, Stil beim Aussuchen prüfen), alternativ eigene Polygone mit Glow
- **Effekte:** Triebwerks-Partikel, Explosionen mit Funken und Schockwelle, Schildblase mit Shader, Kamera-Shake, Hit-Stop bei großen Treffern, Bildschirmrand-Warnung bei Gefahr
- **Font:** Technischer Sans-Font mit Umlauten (OFL)
- **Audio:** Kenney Sci-Fi-Sounds (CC0), räumliche Explosionen, dynamische Musik, die mit der Welle intensiver wird

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
1. ✅ **M0:** Setup aus Vorlage (`shared/`: Menü, Theme, `LocaleService` mit DE/EN-CSV, `DisplayService`/Vollbild, Credits) und Splash/Menü-Optik
2. ✅ **M1:** Schiff mit Trägheit, Schießen, Wrap-around
3. ✅ **M2:** Asteroiden (Generierung, Zerfall, Kollisionen), Punkte, Leben
4. ✅ **M3:** Wellen-Director und Schwierigkeitskurve
5. ✅ **M4:** UFOs und Minen
6. ✅ **M5:** Upgrade-Karten
7. ✅ **M6:** Juice (Explosionen, Triebwerks-Partikel, Shake, Musik/Sound)
8. ✅ **M7:** Menüs, Highscore, Export

## Hinweise zur Umsetzung
Richtwerte, die beim Spieltest angepasst werden dürfen. Sie gehören in eine Konstantendatei, nicht verstreut in den Code.

**Schiff** (Bewegung selbst integrieren, in `_physics_process`):
```
velocity += Vector2.UP.rotated(rotation) * thrust * delta     # thrust 600 px/s², nur bei gedrücktem Schub
velocity *= pow(0.6, delta)                                   # leichte Dämpfung
velocity = velocity.limit_length(700.0)
rotation += turn_input * 4.0 * delta                          # 4 rad/s
```
Schuss: Geschwindigkeit 900 px/s (plus Schiffsgeschwindigkeit), Lebensdauer 1,0 s, Feuerrate 0,25 s. Nach dem Tod 2 s Unverwundbarkeit (Blinken). Respawn in der Mitte erst, wenn dort kein Asteroid im Umkreis von 200 px ist.

**Asteroiden:**
| Größe | Radius | Punkte | Zerfall |
|---|---|---|---|
| groß | 80 | 20 | 2 mittlere |
| mittel | 45 | 50 | 2 kleine |
| klein | 22 | 100 | – |

Teilstücke fliegen in ±(20–60)° zur ursprünglichen Richtung, mit 1,3-facher Geschwindigkeit. Die Form entsteht aus 10–14 Eckpunkten: Winkel `i · 2π / n`, Radius `r · randf(0.75, 1.15)`. **Kollision immer als Kreis** (`CircleShape2D`, Radius `r · 0.85`), niemals konkave Polygone.

**Wellen:** Anzahl Großasteroiden = `min(3 + welle, 12)`, Geschwindigkeitsfaktor `1 + 0.05 · welle`. Spawn am Bildschirmrand, mindestens 300 px vom Schiff entfernt. UFOs: großes ab Welle 2, kleines ab Welle 3, Minen ab Welle 5. Wellen werden als `WaveData`-Ressource (`asteroid_count`, `speed_factor`, `ufo_spawns`) definiert.

**Wrap-around:** `wrap_position(pos, rect)` mit `posmod`, getestet an allen vier Rändern und Ecken.

**Upgrades:** `UpgradeData`-Ressource mit `id`, `name_key`, `desc_key`, `max_stacks` und einem Wörterbuch von Spielerwerten (`fire_rate_mul`, `bullet_count`, `shield_max`, …). Der Endwert eines Werts ist Basiswert plus Summe der Zuschläge, multipliziert mit dem Produkt der Faktoren. Alle Namen und Beschreibungen laufen über Übersetzungsschlüssel.

### Abnahmekriterien
- [x] Schiff fühlt sich flüssig an (Trägheit, Wrap-around ohne Ruckeln)
- [x] Asteroiden zerfallen wie in der Tabelle, Punkte stimmen
- [x] Mindestens 10 Wellen spielbar, Schwierigkeit steigt spürbar
- [x] UFOs, Minen und Upgrade-Auswahl funktionieren
- [x] 60 FPS im Web-Build bei vollem Bildschirm (Pooling aktiv)
- [x] Tests und Smoke-Test (Autopilot) grün

## Tests
- `wrap_position` (Randfälle)
- Asteroid-Zerfall: Anzahl und Größen der Teilstücke
- Wellen-Schwierigkeit steigt monoton
- Smoke-Test: 1000 Frames Autopilot ohne Fehler

## Risiken
- Prozedurale Kollisionspolygone können konkav sein → konvexe Polygone erzeugen oder Kreiskollision verwenden
- Zu viele Objekte im Web → Pooling und Limits

## Erweiterungsideen
Zweiter Spielmodus "Survival", Bosse, lokaler Highscore-Ghost, Gamepad-Vibration
