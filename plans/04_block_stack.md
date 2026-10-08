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

## Hinweise zur Umsetzung
Formen, Drehungen und Kicks folgen der **Tetris Guideline (SRS)**. Die Tabellen unten sind mit y nach oben angegeben. In Godot (y nach unten) muss das y-Vorzeichen umgekehrt werden. **Vor dem Festschreiben gegen eine offizielle SRS-Quelle prüfen** (z. B. Tetris Wiki "SRS") und per Test absichern.

**Wall Kicks J, L, S, T, Z** (Test 1 ist immer (0,0)):
```
0>R: (0,0) (-1,0) (-1,1) (0,-2) (-1,-2)      R>0: (0,0) (1,0) (1,-1) (0,2) (1,2)
R>2: (0,0) (1,0) (1,-1) (0,2) (1,2)          2>R: (0,0) (-1,0) (-1,1) (0,-2) (-1,-2)
2>L: (0,0) (1,0) (1,1) (0,-2) (1,-2)         L>2: (0,0) (-1,0) (-1,-1) (0,2) (-1,2)
L>0: (0,0) (-1,0) (-1,-1) (0,2) (-1,2)       0>L: (0,0) (1,0) (1,1) (0,-2) (1,-2)
```
**Wall Kicks I:**
```
0>R: (0,0) (-2,0) (1,0) (-2,-1) (1,2)        R>0: (0,0) (2,0) (-1,0) (2,1) (-1,-2)
R>2: (0,0) (-1,0) (2,0) (-1,2) (2,-1)        2>R: (0,0) (1,0) (-2,0) (1,-2) (-2,1)
2>L: (0,0) (2,0) (-1,0) (2,1) (-1,-2)        L>2: (0,0) (-2,0) (1,0) (-2,-1) (1,2)
L>0: (0,0) (1,0) (-2,0) (1,-2) (-2,1)        0>L: (0,0) (-1,0) (2,0) (-1,2) (2,-1)
```
Der O-Block hat keine Kicks.

**Zeiten:** Schwerkraft in Sekunden pro Reihe `(0.8 − (level − 1) · 0.007)^(level − 1)`. Soft Drop 20× schneller. Lock Delay 0,5 s, höchstens 15 Zurücksetzungen pro Block. DAS 170 ms, ARR 50 ms (einstellbar).

**Punkte (mal Level):** Single 100, Double 300, Triple 500, Quad 800, T-Spin Single 800, T-Spin Double 1200. Back-to-Back (Quad oder T-Spin nacheinander) mal 1,5. Combo `50 × Combo`. Soft Drop 1 pro Feld, Hard Drop 2 pro Feld.

**Müllreihen im Duell:** Single 0, Double 1, Triple 2, Quad 4, T-Spin Double 4, Back-to-Back +1, Combo-Bonus ab Combo 2 (+1, ab 4 +2, ab 7 +3). Eingehender Müll wird erst nach dem nächsten Block eingefügt und kann durch eigene Angriffe verrechnet werden. Das Loch liegt in aufeinanderfolgenden Müllreihen derselben Wertung in derselben Spalte (Spalte per Seed).

**CPU-Bewertung** (bekannte Gewichte für dieses Verfahren, danach tunen):
```
score = -0.51 * aggregate_height + 0.76 * cleared_lines - 0.36 * holes - 0.18 * bumpiness
```
Die CPU testet alle Positionen und Drehungen (und optional Hold), nimmt den besten Wert und führt die Züge mit einer Verzögerung aus. Schwierigkeit über Denkpause (200–800 ms), Fehlerquote (z. B. 10 % zufälliger zweitbester Zug) und Hold-Nutzung.

### Abnahmekriterien
- [ ] Alle 7 Formen × 4 Drehungen × Kick-Tabellen per Test geprüft
- [ ] 7-Bag, Hold, Ghost, Lock Delay, Hard/Soft Drop funktionieren
- [ ] Marathon, Sprint, Ultra und Duell gegen CPU spielbar
- [ ] CPU schlägt einen Zufallsspieler deutlich, ohne zu hängen
- [ ] DAS/ARR einstellbar und gespeichert
- [ ] Eingabe fühlt sich auch im Web direkt an

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
