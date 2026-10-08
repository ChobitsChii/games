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

## Stand
- M0 (Setup) und M1 (Spielkern) fertig, die Optik ist noch Platzhalter.
- Nächster Schritt: M2, Optik-Vertical-Slice.

Siehe [Plan](../plans/01_neon_breakout.md).
