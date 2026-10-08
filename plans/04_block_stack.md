# 🟦 Plan 4 – Block Stack

**Genre:** Puzzle (Tetris-Like) · **Modus:** Single Player, optional Duell gegen CPU · **Aufwand:** ⭐⭐

> [!NOTE]
> Tetris ist eine geschützte Marke. Das Spiel heißt daher anders, verwendet eigene Optik und eigene Namen. Das Spielprinzip selbst ist nicht geschützt.

## Idee
Fallende Blöcke aus je vier Quadraten (Tetrominos) stapeln und Reihen vervollständigen. Die Besonderheit ist ein **CPU-Duell**: Reihen-Clears schicken "Müllreihen" zum Gegner.

## Kernmechanik (moderner Guideline-Stil)
- Feld 10×20 (+ 2 unsichtbare Reihen oben)
- 7 Formen, Zufall per **7-Bag** (faire Verteilung)
- Bewegen, Drehen (SRS mit Wall Kicks), Soft Drop, Hard Drop
- **Hold-Funktion** und Vorschau der nächsten 5 Blöcke
- **Ghost Piece** (Schatten der Landeposition)
- Lock Delay (kurze Zeit zum Verschieben nach der Landung)
- DAS/ARR: einstellbare Wiederholrate bei gedrückter Taste
- Punkte: Single/Double/Triple/Quad, T-Spin, Back-to-Back, Combo
- Level steigt alle 10 Reihen, die Fallgeschwindigkeit steigt

## Spielmodi
| Modus | Beschreibung |
|---|---|
| Marathon | bis Level 15 oder Game Over |
| Sprint | 40 Reihen so schnell wie möglich |
| Ultra | 2 Minuten, maximale Punkte |
| **Duell vs. CPU** | Angriffe senden Müllreihen, wer zuerst oben ansteht, verliert |

## CPU-Gegner (Duell)
- Bewertungsfunktion nach Art des Dellacherie-Verfahrens: Höhe, Löcher, Unebenheit, Reihen-Clears
- Probiert alle Positionen und Drehungen des aktuellen (und optional des nächsten) Blocks durch
- **Schwierigkeit:** Denkzeit zwischen Zügen, Fehlerquote, ob Hold genutzt wird
- Läuft headless-fähig: Die Spiellogik hat keine UI-Abhängigkeiten

## Technischer Entwurf
```
scripts/core/piece.gd          # Formen, SRS-Rotationstabellen, Wall Kicks
scripts/core/matrix.gd         # Spielfeld, Kollision, Reihen löschen, Garbage
scripts/core/game_logic.gd     # Zustandsautomat: SPAWN → FALL → LOCK → CLEAR
scripts/core/bag.gd            # 7-Bag mit Seed
scripts/ai/cpu_player.gd       # Bewertung und Zugsuche
scripts/ui/board_view.gd       # reine Darstellung (_draw oder TileMapLayer)
```
- Zwei Instanzen von `game_logic.gd` im Duell: links der Spieler, rechts die CPU
- Darstellung mit `TileMapLayer` oder `_draw()` (Letzteres ist im Web schnell genug)
- Eingabe mit eigener Wiederholungslogik (DAS/ARR) statt `ui_*`-Echo

## Optik & Assets
**Stil:** Moderne "Glas"-Optik mit halbtransparenten, leuchtenden Blöcken, weichen Verläufen und sanften Reflexen. **Kein Pixel-Art**, keine harten Kanten. Hintergrund wechselt langsam mit dem Level (Farbverläufe, Schatten).

- **Palette:** 7 klar unterscheidbare Farben für die Formen, dunkler ruhiger Hintergrund. Farbenblindheitsmodus mit Symbolen.
- **Grafik:** Blöcke als abgerundete Quadrate mit Shader (Verlauf, Glanz, Glow), selbst erzeugt. Rahmen und UI im gleichen Glas-Stil.
- **Effekte:** Reihen lösen sich mit Partikeln und Leuchtwelle auf, Hard Drop mit Spur und Aufprall, Schwingung des Spielfelds bei Quad und T-Spin, Level-Aufstieg mit Farbwechsel
- **Font:** Klarer, gut lesbarer Font für Zahlen (tabellarische Ziffern) mit Umlauten
- **Audio:** Dezentes, präzises Sound-Design (Kenney Interface Sounds, CC0), Musik, deren Tempo mit dem Level steigt (CC0/CC-BY)

### Lokalisierung, Vollbild, Credits
- Alle Texte über Schlüssel in `i18n/<spiel>.csv` (`keys,de,en`), keine festen Texte in Szenen oder Code
- Vollbild/Fenster über den gemeinsamen `DisplayService` (F11, Optionsmenü, gespeichert)
- Verwendete Assets mit Lizenz in `CREDITS.md`, Credits-Bildschirm im Spiel

## Meilensteine
1. **M0:** Setup aus Vorlage (`shared/`: Menü, Theme, `LocaleService` mit DE/EN-CSV, `DisplayService`/Vollbild, Credits) und Platzhalter-Optik
2. **M1:** Logik: Formen, Rotation, Kollision, Reihen löschen mit Unit-Tests
3. **M2:** Darstellung und Steuerung, Marathon-Modus
4. **M3:** Hold, Ghost, Vorschau, Lock Delay, Hard/Soft Drop
5. **M4:** Wertung (T-Spin, B2B, Combo) und Level-Kurve
6. **M5:** Sprint und Ultra, Highscores
7. **M6:** CPU-Spieler, Duell-Modus mit Müllreihen
8. **M7:** Juice (Partikel beim Clear, Sound, Musik), Menüs, Optionen (DAS/ARR), Export

## Tests
- Alle 7 Formen × 4 Rotationen × Wall Kicks (Tabellentest)
- 7-Bag liefert in jedem 7er-Block jede Form genau einmal
- Reihen-Clear (1–4 Reihen) und Gravitation
- Müllreihen-Berechnung (Angriffstabelle)
- CPU spielt 1000 Züge ohne Absturz, schlägt Zufallsspieler deutlich

## Risiken
- SRS-Kick-Tabellen sind fehleranfällig → exakt aus der Spezifikation übernehmen und per Test absichern
- Eingabe-Latenz im Web → Eingaben pro Frame direkt auswerten

## Erweiterungsideen
Replays (Seed + Eingabeprotokoll), Themes, Zen-Modus, Puzzle-Modus
