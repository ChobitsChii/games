# Block Stack

Modernes Puzzle-Spiel im Tetris-Guideline-Stil (SRS, 7-Bag, Hold, Ghost Piece) mit Marathon-, Sprint-, Ultra- und Duell-Modus gegen die CPU. Godot 4.7 (GDScript), Linux, Windows und Web.

## Steuerung
| Aktion | Tastatur | Gamepad |
|---|---|---|
| Links / Rechts | `←` / `→` oder `A` / `D` | D-Pad Links / Rechts, Stick |
| Soft Drop | `↓` oder `S` | D-Pad Unten, Stick Runter |
| Hard Drop | Leertaste | D-Pad Oben, `Y` |
| Drehen im Uhrzeigersinn | `↑` oder `X` | `A`, `B` |
| Drehen gegen Uhrzeigersinn | `Z` oder `Strg` | `X` |
| Hold (Tauschen) | `C` oder `Umschalt` | `LB`, `RB` |
| Pause | `Esc` oder `P` | `Start` |
| Vollbild umschalten | `F11` oder `Alt+Enter` | – |

## Entwickeln
Alle Befehle im Repo-Wurzelverzeichnis:

```bash
tools/sync_shared.sh                      # shared/ nach addons/shared/ kopieren
godot --path block_stack                  # Spiel starten
godot --path block_stack -- --seed=42     # mit festem Zufalls-Seed
tools/run_tests.sh                        # Tests (Logik + Smoke-Test)
tools/build_all.sh block_stack            # Exporte nach build/
```

Der Seed steht beim Start in der Konsole. Bitte bei Fehlermeldungen angeben.

Siehe [Plan](../plans/04_block_stack.md).
