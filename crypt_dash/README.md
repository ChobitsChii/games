# Crypt Dash

**Genre:** Top-Down-Roguelite (Action)  
**Engine:** Godot 4.7 (GDScript, GL Compatibility)  
**Plattformen:** Linux, Windows, Web (HTML5/WASM), Android (Signiertes APK, 16:9 Querformat)

## Beschreibung
In einer prozedural erzeugten Gruft kämpft man sich durch Räume voller Skelette, Bogenschützen, Geister und Schleime, sammelt mächtige Items und besiegt Bosse mit wechselnden Angriffsphasen. Zwischen den Runs können gesammelte Seelen für permanente Upgrades investiert werden.

## Steuerung
- **Laufen:** W, A, S, D / Pfeiltasten / Gamepad linker Stick / Touch-Linker-Stick (Android)
- **Dash (Ausweichen):** Leertaste / Gamepad Taste A / Touch-Dash-Button (Android)
- **Angriff / Schuss:** Linke Maustaste / Taste J / Gamepad rechter Trigger / Touch-Rechter-Stick (Android, inkl. Auto-Aim-Fallback)
- **Zielen:** Mauszeiger / Gamepad rechter Stick / Touch-Rechter-Stick (Android)
- **Pause:** Escape / P / Gamepad Start
- **Vollbild:** F11 / Alt + Enter

## Entwicklung & Tests
```bash
# Tests ausführen
tools/run_tests.sh

# Spiel direkt starten
godot --path crypt_dash
```
