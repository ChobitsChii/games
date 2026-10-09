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
- **7 Einheiten:** Generator, Schütze, Doppelschütze, Frostturm, Mauer, Mine, Flächenwerfer mit detaillierten Info-Tooltips (Kosten, Cooldown, Flächenschaden über 3 Lanes etc.)
- **6 Gegnertypen:** Läufer, Schneller Läufer, Panzer, Springer, Schild-Träger, Giga-Boss
- **20 Level in 4 Welten mit einzigartigen Schlachtfeld-Hintergründen:**
  - Welt 1: Grüne Wiese (inkl. Bosskampf in 1-5)
  - Welt 2: Dunkler Pfad (nächtliche Pilzlichtung mit Bosskampf in 2-5)
  - Welt 3: Frostiger Winterwald (verschneiter Nadelwald mit Eisblöcken und Bosskampf in 3-5)
  - Welt 4: Magma-Ödland (vulkanische Basaltlandschaft mit glühender Lava und Bosskampf in 4-5)
- **Interaktives Lexikon / Almanach:** Jederzeit über das Hauptmenü und während der Partie (Pausemenü & Top-Bar) aufrufbar, mit allen Werten, Rollen und Fähigkeiten von Verteidigern und Kobolden
- **Speicherstand & Autosave:** Freigeschaltete Level und Sterne (1–3 pro Level) werden automatisch nach jedem gemeisterten Level gesichert. "Speichern & Beenden" im Pause- und Endmenü.
- **Sieg-Screenshots & Ordner-Schnellzugriff:** Nach Levelabschluss sowie im Pause-Menü kann ein Spielfeld-Screenshot gespeichert und der Zielordner direkt geöffnet werden.

Siehe [Plan](../plans/05_lane_defenders.md).

