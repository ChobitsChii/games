# Connect Four Deluxe (Vier gewinnt)

Modernes, strategisches Vier gewinnt mit stimmungsvoller 3D/2.5D-Präsentation, fallenden Spielsteinen, Sound-Effekten und mehrstufiger KI (Leicht, Mittel, Schwer) mit Bitboard-Engine und Alpha-Beta-Suche. Godot 4.7 (GDScript), Linux, Windows und Web.

## Steuerung
| Aktion | Tastatur | Gamepad | Maus |
|---|---|---|---|
| Spalte wählen | `←` / `→` oder `A` / `D` | D-Pad / Analogstick | Über Spalte bewegen |
| Stein einwerfen | `Leertaste`, `Enter`, `↓` oder `S` | Taste `A`, D-Pad Unten | Spalte anklicken |
| Zug rückgängig | `U` oder `Z` | Taste `X` | Undo-Button |
| Zug-Tipp (Hinweis) | `H` oder `T` | Taste `Y` | Tipp-Button |
| Neustart | `R` | – | Neustart-Button |
| Pause | `Esc` oder `P` | `Start` | Pause-Button |
| Vollbild umschalten | `F11` oder `Alt+Enter` | – | Vollbild-Button |

## Entwickeln
Alle Befehle im Repo-Wurzelverzeichnis:

```bash
tools/sync_shared.sh                      # shared/ nach addons/shared/ kopieren
godot --path vier_gewinnt                  # Spiel starten
godot --path vier_gewinnt -- --seed=42     # mit festem Zufalls-Seed
tools/run_tests.sh                        # Tests (Logik + Smoke-Test)
tools/build_all.sh vier_gewinnt           # Exporte nach build/
```

Der Seed steht beim Start in der Konsole. Bitte bei Fehlermeldungen angeben.

Siehe [Plan](../plans/03_vier_gewinnt.md).
