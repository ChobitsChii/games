# Neon Breakout

Modernes Breakout mit Neon-Optik. Godot 4.7 (GDScript), Linux, Windows und Web.

## Steuerung
| Aktion | Eingabe |
|---|---|
| Schläger bewegen | Maus, `←`/`→`, `A`/`D`, Gamepad-Stick oder D-Pad |
| Ball starten / weiter, klebenden Ball lösen, Laser feuern | Leertaste, Linksklick, Gamepad `A` |
| Pause | `Esc`, `P`, Gamepad `Start` |
| Vollbild umschalten | `F11` oder `Alt+Enter` |

## Entwickeln
Alle Befehle im Repo-Wurzelverzeichnis:

```bash
tools/sync_shared.sh                       # shared/ nach addons/shared/ kopieren
godot --path neon_breakout                 # Spiel starten
godot --path neon_breakout -- --seed=42    # mit festem Zufalls-Seed
tools/run_tests.sh                         # Tests (Logik + Smoke-Test)
tools/build_all.sh neon_breakout           # Exporte nach build/
```

Der Seed steht beim Start in der Konsole. Bitte bei Fehlermeldungen angeben.

## Optik und Effekte (M2)
- Animierter Hintergrund (Shader: Farbverlauf, wandernde Farbwolken, Gitter, Sterne, Vignette)
- Leuchteffekt (Glow) über `WorldEnvironment`, Ball, Schläger und Funken leuchten besonders
- Ball-Schweif, Funken bei Treffern, aufpoppende Blöcke, Schläger-Impuls, Punkte-Pop, roter Blitz bei Lebensverlust
- Bildschirmwackeln und Zeitlupe beim letzten Block
- Synthetisierte Soundeffekte (Töne werden bei Serien höher), keine Audiodateien nötig
- Schrift Rajdhani (OFL), eigenes UI-Theme
- Im Hauptmenü einstellbar: **Effekte** (Hoch/Niedrig, Niedrig schaltet Glow aus und reduziert Funken) und **Bildschirmwackeln** (An/Aus)

## Power-Ups und Combo
Jeder zerstörte Block lässt mit 12 % Wahrscheinlichkeit ein Item fallen. Der Schläger sammelt es ein, am unteren Rand verschwindet es.

| Item | Wirkung |
|---|---|
| Breiter Schläger | 50 % breiter für 15 s |
| Multiball | Ball teilt sich in 3 (±20°), höchstens 8 Bälle. Ein Leben geht erst verloren, wenn der letzte Ball unten ist. |
| Laser | 10 Schüsse aus beiden Enden des Schlägers, feuert bei gedrückter Starttaste |
| Klebrig | Ball bleibt am Schläger kleben, bis man die Starttaste drückt (15 s) |
| Langsam | Bälle 30 % langsamer für 10 s |
| Extraleben | selten, höchstens 9 Leben |

- Erneut eingesammelte Effekte verlängern die Zeit (höchstens auf das Doppelte). Beim Verlust eines Lebens und beim Levelwechsel enden alle Effekte.
- **Combo:** Zerstörte Blöcke seit dem letzten Schlägerkontakt. Der erste zählt einfach, danach +0,25 je Block bis zum Vierfachen. Die Anzeige steht rechts neben dem Spielfeld, aktive Power-Ups links.
- Die Item-Drops folgen dem Seed (`-- --seed=N`) und lassen sich damit reproduzieren.

## Level
- 10 Level als Textdateien in `data/levels/level_01.txt` bis `level_10.txt`, danach beginnt die Reihe von vorn (die Ballgeschwindigkeit steigt weiter).
- Zeichen: `1`-`3` = Block mit so vielen Trefferpunkten, `X` = unzerstörbar, `.` = leer. Je Zeile 10 Zeichen, höchstens 12 Zeilen. Zeilen mit `#` sind Kommentare.
- Neues Level: Datei mit der nächsten Nummer anlegen (lückenlos nummerieren), die Tests prüfen Format und Zählung. Dateien müssen in `export_presets.cfg` über `include_filter="data/levels/*.txt"` mitexportiert werden (ist eingetragen).
- Punkte, Leben und Rekord bleiben zwischen den Leveln erhalten.

## Stand
- M0 (Setup), M1 (Spielkern), M2 (Optik), M3 (Level) und M4 (Power-Ups, Combo) M5 (Juice, Musik) und M6 (Menüs, Optionen, Credits) fertig.
- Nächster Schritt: M7 (Politur und Export).
- Musik und Soundeffekte werden im Code synthetisiert.

Siehe [Plan](../plans/01_neon_breakout.md).
