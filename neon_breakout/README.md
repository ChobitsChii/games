# Neon Breakout

Modernes Breakout mit Neon-Optik. Godot 4.7 (GDScript), Linux, Windows und Web.

## Steuerung
| Aktion | Eingabe |
|---|---|
| Schläger bewegen | Maus, `←`/`→`, `A`/`D`, Gamepad-Stick oder D-Pad |
| Ball starten / weiter | Leertaste, Linksklick, Gamepad `A` |
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

## Stand
- M0 (Setup), M1 (Spielkern) und M2 (Optik-Vertical-Slice) fertig.
- M2 wartet auf die Freigabe durch Jennifer, bevor M3 (Level) beginnt.
- Musik folgt in M5.

Siehe [Plan](../plans/01_neon_breakout.md).
