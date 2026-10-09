# 🛡️ Lane Defenders

Mini-Tower-Defense (Lane-basiert) mit modernem Flat-Cartoon-Look. Godot 4.7 (GDScript), für Linux, Windows und Web.

## Steuerung
| Aktion | Eingabe |
|---|---|
| Einheit wählen (Slots 1–7) | Zifferntasten `1`–`7` oder Klick auf Karte |
| Platzieren | Linksklick auf Zelle oder `Leertaste`/`Enter`/Gamepad `A` auf Cursor |
| Mehrfach-Platzieren | `Shift` gedrückt halten beim Platzieren |
| Schaufel / Einheit entfernen | `X`, Gamepad `Y` oder Klick auf Schaufel-Button |
| Energie einsammeln | Linksklick auf fallende/erzeugte Sonnen |
| Auswahl abbrechen | Rechtsklick, `Esc` oder Gamepad `B` |
| Spielfeld-Cursor | Pfeiltasten, `WASD` oder Gamepad D-Pad/Stick |
| Pause | `Esc`, `P` oder Gamepad `Start` |
| Vollbild umschalten | `F11` oder `Alt+Enter` |

## Entwickeln
Alle Befehle im Repo-Wurzelverzeichnis:

```bash
tools/sync_shared.sh                       # shared/ nach addons/shared/ kopieren
godot --path lane_defenders                # Spiel starten
godot --path lane_defenders -- --seed=42   # mit festem Zufalls-Seed
tools/run_tests.sh                         # Tests aller Spiele (Logik + Smoke-Test)
tools/build_all.sh lane_defenders          # Exporte nach build/
```

Der Seed steht beim Start in der Konsole. Bitte bei Fehlermeldungen angeben.

## Spielinhalte
- **7 Einheiten:** Generator, Schütze, Doppelschütze, Frostturm, Mauer, Mine, Flächenwerfer
- **6 Gegnertypen:** Läufer, Schneller Läufer, Panzer, Springer, Schild-Träger, Giga-Boss
- **10 Level in 2 Welten:** Welt 1 (Wiese mit Bosskampf) und Welt 2 (Dunkler Pfad)
- **Speicherstand:** Freigeschaltete Level und Sterne (1–3 pro Level) werden in `user://` gesichert.

Siehe [Plan](../plans/05_lane_defenders.md).
