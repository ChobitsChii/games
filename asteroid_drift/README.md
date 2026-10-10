# Asteroid Drift

Modernes Sci-Fi Arcade-Shooter-Spiel (Asteroids-Like) mit Trägheitsphysik, prozedural generierten Asteroiden, Upgrade-Karten nach jeder 3. Welle, UFO-Gegnern und Annäherungsminen. Entwickelt mit Godot 4.7 (GDScript) für Linux, Windows und Web (HTML5).

## Steuerung
| Aktion | Tastatur | Gamepad / Maus |
|---|---|---|
| Drehen links / rechts | `←` / `→` oder `A` / `D` | D-Pad Links / Rechts, Stick |
| Schub | `↑` oder `W` | D-Pad Oben, Stick Hoch |
| Feuern | Leertaste oder `J` | Linke Maustaste, `A`, `RB` |
| Hyperspace-Sprung | `H` oder `Umschalt` | `B`, `Y` |
| Pause | `Esc` oder `P` | `Start` |
| Vollbild umschalten | `F11` oder `Alt+Enter` | – |

## Features
- **Trägheitsphysik & Wrap-Around:** Flüssige Raumschiff-Steuerung mit feiner Geschwindigkeits- und Rotationsdämpfung.
- **Prozedurale Asteroiden:** Dynamische Vektor-Polygone mit weichem Glow, die in kleinere Fragmente zerfallen.
- **Wellen-Director:** Monoton steigende Schwierigkeitsgrade mit feindlichen UFOs (gezielt und streuend) sowie zielsuchenden Minen.
- **Upgrade-System:** Nach jeder 3. Welle Auswahl aus 3 zufälligen Tech-Upgrades (Doppelschuss, Streuschuss, Feuerrate, Schild-Boost, Magnet, Explosivmunition).
- **Audio & Präsentation:** Vollständige Soundkulisse (CC0 Kenney), moderner animierter Splash Screen beim Start, stilvoller Menü-Hintergrund und Responsive HUD.

## Entwickeln
Alle Befehle im Repo-Wurzelverzeichnis:

```bash
tools/sync_shared.sh                        # shared/ nach addons/shared/ kopieren
godot --path asteroid_drift                 # Spiel starten
godot --path asteroid_drift -- --seed=42    # mit festem Zufalls-Seed
tools/run_tests.sh                          # Tests (Logik + Smoke-Test)
tools/build_all.sh asteroid_drift           # Exporte nach build/
```

Der Seed steht beim Start in der Konsole. Bitte bei Fehlermeldungen angeben.

Siehe [Plan](../plans/02_asteroid_drift.md).
