# 🔴🟡 Plan 3 – Connect Four Deluxe (Vier gewinnt)

**Genre:** Brettspiel / Strategie · **Modus:** gegen Computer (Hot-Seat optional) · **Aufwand:** ⭐⭐

## Idee
Vier gewinnt mit stimmungsvoller Präsentation (fallende Steine mit Physik-Feeling, Sound) und einer **KI mit mehreren Stufen**. Das Spiel eignet sich gut, um Spiellogik sauber von der Darstellung zu trennen und zu testen.

## Kernmechanik
- Brett 7×6 (später Varianten wie 8×7 oder 5 in einer Reihe)
- Spieler und KI werfen abwechselnd Steine ein
- Gewinn bei 4 in einer Reihe (waagerecht, senkrecht, diagonal), sonst Unentschieden
- Steuerung per Maus (Spalte anklicken), Tastatur (←/→/Enter) oder Gamepad
- Wer beginnt: wählbar oder zufällig
- Zusätzlich: Undo (nur gegen leichte KI), Hinweis-Funktion ("Tipp")

## KI-Stufen
| Stufe | Verfahren |
|---|---|
| Leicht | zufällig, blockiert nur direkte Gewinnzüge |
| Mittel | Minimax, Tiefe 4, einfache Bewertung |
| Schwer | Negamax mit Alpha-Beta, Tiefe 8–10, Zugsortierung (Mitte zuerst), Bitboards |
| Unmöglich (optional) | Iterative Deepening mit Zeitlimit und Transposition-Table |

> Das Spiel ist gelöst, der Anziehende gewinnt bei perfektem Spiel. Die schwere KI soll daher möglichst nah an perfektem Spiel liegen, ohne das Web-Frontend zu blockieren. Dazu läuft die Suche in einem **Thread** (nativ) bzw. **zeitgeteilt über mehrere Frames** (Web, single-threaded).

## Technischer Entwurf
```
scripts/core/board.gd        # Bitboard-Repräsentation, legal moves, win check (UI-frei!)
scripts/core/ai.gd           # Negamax/Alpha-Beta, Bewertung, Transposition-Table
scripts/game/game_controller.gd   # Zugfluss, Zustandsautomat
scenes/ board_view.tscn  disc.tscn  hud.tscn  menu.tscn
```
- **Zustände:** `MENU → PLAYER_TURN → DROPPING → AI_THINKING → GAME_OVER`
- **Zeitgeteilte KI im Web:** Suche als Coroutine, die alle ~8 ms ein `await get_tree().process_frame` macht
- Disc-Animation mit `Tween` (Fall + Bounce), Gewinnreihe blinkt

## Optik & Assets
**Stil:** Hochwertiges **3D/2.5D-Brett** (Low-Poly oder glatte Geometrie) mit weichem Licht, Schatten und Materialien wie Holz, Glas oder Acryl. **Kein Pixel-Art.** Kamera mit leichter Schräglage und sanftem Schwenk.

- **Palette:** Warm (Holz, Creme) oder kühl (Blau, Glas). Steine in kräftigem Rot und Gelb, Farbblindheitsmodus mit Mustern auf den Steinen.
- **Grafik:** Brett und Steine als einfache 3D-Meshes, selbst erzeugt (Godot-Primitives mit Materialien) oder aus CC0-3D-Paketen (Kenney Board Game Kit, Quaternius). Hintergrund mit Tiefenunschärfe oder Verlauf.
- **Renderer:** läuft im Compatibility-Renderer (WebGL 2). Schatten und Beleuchtung sind dort begrenzt, deshalb werden weiche Schatten teils als Textur vorgebacken.
- **Effekte:** Steine fallen mit Physik-Gefühl (Tween mit Bounce), Aufprall-Staub und Klang, Gewinnreihe leuchtet mit Puls, Konfetti beim Sieg
- **Font:** Eleganter Sans-Font mit Umlauten (OFL)
- **Audio:** Holz- und Klick-Sounds (Kenney Impact Sounds, CC0), ruhige Lounge-Musik (CC0/CC-BY)

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
1. **M0:** Setup aus Vorlage (`shared/`: Menü, Theme, `LocaleService` mit DE/EN-CSV, `DisplayService`/Vollbild, Credits) und Platzhalter-Optik
2. **M1:** `board.gd` mit Bitboards und vollständigen Unit-Tests
3. **M2:** Darstellung und Maus-Eingabe, Hot-Seat-Modus
4. **M3:** KI leicht und mittel
5. **M4:** KI schwer (Alpha-Beta, Zugsortierung), Zeitlimit
6. **M5:** Animationen, Sound, Gewinn-Effekt, Statistik (Siege/Niederlagen pro Stufe)
7. **M6:** Menüs, Optionen, Export

## Tests (besonders wichtig)
- Gewinnerkennung für alle Richtungen und Randfälle
- Volle Spalte, volles Brett (Unentschieden)
- KI findet Gewinn in 1 Zug und blockiert Gegner-Gewinn in 1 Zug
- KI-Stärke: schwer schlägt mittel in ≥ 90 % von 50 simulierten Partien
- Performance: schwere KI antwortet nativ < 1 s und im Web < 2 s

## Erweiterungsideen
Brettvarianten, "Pop Out", Themen für Steine, Online-Highscore, Tutorial
