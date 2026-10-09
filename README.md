# Mini-Games

Kleine, modern gestaltete Spiele mit Godot 4.7 (GDScript) für Linux, Windows und Web (HTML5).
Sprachen: Deutsch und Englisch (erweiterbar).

Arbeitsanweisungen (auch für KI-Agenten): [AGENTS.md](AGENTS.md)

Pläne und Entscheidungen: [plans/](plans/00_README_Engine_und_Uebersicht.md)

🌐 **Web-Portal / Im Browser spielen:** [https://chobitschii.github.io/games/](https://chobitschii.github.io/games/)

## Spiele
| Spiel | Version | Stand | Web (Browser) | Downloads / Releases |
|---|---|---|---|---|
| [Block Stack](block_stack/README.md) | `v1.0.0` | Vollständig spielbar (Marathon, Sprint, Ultra, CPU-Duell), M0–M7 fertig | [▶ Spielen](https://chobitschii.github.io/games/block_stack/) | [Release & Downloads](../../releases/tag/block_stack-latest) |
| [Lane Defenders](lane_defenders/README.md) | `v1.1.0` | Vollständig spielbar (10 Level, 2 Welten, Bosskampf), M0–M7 fertig | [▶ Spielen](https://chobitschii.github.io/games/lane_defenders/) | [Release & Downloads](../../releases/tag/lane_defenders-latest) |
| [Connect Four Deluxe](vier_gewinnt/README.md) | `v1.1.1` | Vollständig spielbar (vs. KI Leicht/Mittel/Schwer, Hotseat, Bitboard-Engine), M0–M6 fertig | [▶ Spielen](https://chobitschii.github.io/games/vier_gewinnt/) | [Release & Downloads](../../releases/tag/vier_gewinnt-latest) |
| [Neon Breakout](neon_breakout/README.md) | `v0.1.0` | Prototyp: M0 (Setup) und M1 (Spielkern) fertig, Optik noch Platzhalter | [▶ Spielen](https://chobitschii.github.io/games/neon_breakout/) | [Release & Downloads](../../releases/tag/neon_breakout-latest) |

## Werkzeuge
```bash
tools/sync_shared.sh                  # shared/ in alle Spiele kopieren
tools/run_tests.sh                    # Tests aller Spiele
tools/build_all.sh [spiel]            # Linux-, Windows- und Web-Export nach build/
tools/serve_web.sh <spiel> [port]     # Web-Build lokal testen
tools/build_web_portal.sh [ziel]      # GitHub Pages Web-Portal lokal bauen
tools/package_release.sh <spiel> <v>  # Release-ZIPs (Linux, Windows, Web) packen
```

Voraussetzung: Godot 4.7.2 mit Export-Templates (Linux, Windows, Web).
