# 🧱 Plan 1 – Neon Breakout

**Genre:** Arcade (Breakout/Arkanoid) · **Modus:** Single Player · **Aufwand:** ⭐ (1–2 Sessions)

## Idee
Ein Ball, ein Schläger, viele leuchtende Blöcke. Der Reiz liegt im "Juice": Partikel, Screen-Shake, Glow und ein pulsierender Soundtrack. Dieses Spiel richtet zugleich die gesamte Projekt- und Export-Pipeline ein.

## Kernmechanik
- Schläger per Maus, Tastatur (←/→, A/D) oder Gamepad-Stick steuern
- Ball prallt ab. Der Abprallwinkel hängt davon ab, wo er den Schläger trifft.
- Blöcke haben 1–3 Trefferpunkte und unterschiedliche Farben
- 3 Leben, Punkte mit Combo-Multiplikator (Treffer ohne Schlägerkontakt)
- Level-Ende, wenn alle zerstörbaren Blöcke weg sind

## Power-Ups (fallen aus Blöcken)
| Item | Effekt |
|---|---|
| Breiter Schläger | +50 % Breite für 15 s |
| Multiball | Ball teilt sich in 3 |
| Laser | Schläger schießt 10 Schüsse |
| Klebrig | Ball bleibt am Schläger, bis man startet |
| Slow | Ball 30 % langsamer für 10 s |
| Extraleben | selten |

## Technischer Entwurf
```
scenes/  main_menu.tscn  game.tscn  paddle.tscn  ball.tscn  brick.tscn  powerup.tscn  hud.tscn
scripts/ paddle.gd  ball.gd  brick.gd  level_loader.gd  powerup.gd  game_state.gd
data/levels/level_01.txt ...   # ASCII-Level: Zeichen = Blocktyp
```
- **Ball:** `CharacterBody2D` mit `move_and_collide` (kein Tunneln, genau steuerbarer Abprall)
- **Paddle:** `AnimatableBody2D` oder `CharacterBody2D`
- **Bricks:** `StaticBody2D` mit Signal `destroyed(points, pos)`
- **Level:** Textdateien, damit sie leicht zu schreiben und zu ändern sind (`#`=1 HP, `=`=2 HP, `X`=unzerstörbar, `.`=leer)
- **Zustände:** `READY → PLAYING → LEVEL_CLEAR → GAME_OVER`
- **Glow:** `WorldEnvironment` mit 2D-Glow (funktioniert in Compatibility); alternativ Shader-Fallback fürs Web

## Optik & Assets
**Stil:** Modernes Neon/Synthwave, rein vektorbasiert, **ohne Pixel-Art**. Tiefer dunkler Hintergrund mit sanftem Verlauf und Parallax-Sternen oder Gitter. Blöcke sind abgerundet, leicht transparent und leuchten. Der Ball hat einen Schweif.

- **Palette:** Dunkelblau/Violett als Basis, Cyan, Magenta und Gelb als Akzente
- **Grafik:** größtenteils selbst erzeugt (Godot-Formen, Shader, `Line2D`, SVG). Optional ergänzen Kenney-Pakete (UI, Partikel).
- **Effekte:** Glow über `WorldEnvironment`, Partikelexplosion pro Block, Schweif per `Line2D`, Shake beim Verlust, Zeitlupe beim letzten Block, sanfte Hintergrundbewegung per Shader
- **Font:** moderner, runder Font mit Umlauten (z. B. aus Google Fonts, Lizenz OFL)
- **Audio:** Kenney-Soundpakete (CC0) oder synthetisch erzeugt. Tonhöhe steigt mit der Combo. Musik als ruhiger Elektro-Loop (CC0/CC-BY).

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
0. **M0 Setup:** Git-Repo, Projekt anlegen, Compatibility-Renderer, Input Map, `export_presets.cfg` (Linux, Windows, Web), `tools/build_all.sh`, `shared/` mit `LocaleService` (DE/EN-CSV), `DisplayService` (Vollbild/F11) und Theme-Gerüst, `CREDITS.md`
1. **M1 Spielkern:** Schläger, Ball, Wände, Blöcke, Leben, Punkte (mit Platzhalter-Optik)
2. **M2 Optik-Vertical-Slice:** Ein Level in **finaler Optik** (Glow, Partikel, Ball-Schweif, Hintergrund-Shader, eigenes UI-Theme, Shake, Sound). Dient als Optik-Check mit Jennifer, bevor wir weiterbauen.
3. **M3 Level:** ASCII-Level-Loader, 10 Level, Fortschritt zwischen Leveln
4. **M4 Power-Ups** und Combo-System
5. **M5 Juice:** Feinschliff von Effekten, Sound und Musik
6. **M6 Menüs:** Hauptmenü, Pause, Highscore (`user://`), Optionen (Sprache, Anzeigemodus, Lautstärke, Effektqualität), Credits-Bildschirm
7. **M7 Politur & Export:** Balancing, Tests (inkl. Lokalisierung), Builds für alle 3 Plattformen, README

## Tests
- Abprallwinkel-Funktion (Unit-Test)
- Level-Loader: gültige und ungültige Dateien
- Smoke-Test headless: Spiel läuft 600 Frames ohne Fehler

## Risiken
- Ball-Physik fühlt sich "falsch" an → Abprall selbst berechnen, nicht der Physik-Engine überlassen
- Glow im Web ist teuer → Option zum Abschalten

## Erweiterungsideen
Boss-Level, Level-Editor, tägliches Seed-Level, Themen-Skins
