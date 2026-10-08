# Mini-Games

Kleine, modern gestaltete Spiele mit Godot 4.7 (GDScript) für Linux, Windows und Web (HTML5).
Sprachen: Deutsch und Englisch (erweiterbar).

Arbeitsanweisungen (auch für KI-Agenten): [AGENTS.md](AGENTS.md)

Pläne und Entscheidungen: [plans/](plans/00_README_Engine_und_Uebersicht.md)

## Spiele
| Spiel | Stand |
|---|---|
| [Neon Breakout](neon_breakout/README.md) | M0 (Setup) und M1 (Spielkern) fertig, Optik noch Platzhalter |
| [Block Stack](block_stack/README.md) | Vollständig spielbar (Marathon, Sprint, Ultra, CPU-Duell), M0–M7 fertig |
| [Lane Defenders](lane_defenders/README.md) | Vollständig spielbar (10 Level, 2 Welten, Bosskampf), M0–M7 fertig |

## Werkzeuge
```bash
tools/sync_shared.sh            # shared/ in alle Spiele kopieren
tools/run_tests.sh              # Tests aller Spiele
tools/build_all.sh [spiel]      # Linux-, Windows- und Web-Export nach build/
tools/serve_web.sh <spiel>      # Web-Build lokal testen
```

Voraussetzung: Godot 4.7.2 mit Export-Templates (Linux, Windows, Web).
