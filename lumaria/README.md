# 💎 Lumaria: The Prismatic Odyssey

Modernes 2D-Action-Adventure (Top-Down-RPG) mit Godot 4.7 (GDScript) für Linux, Windows und Web.
Vollkommen eigenständige Welt und Lore – modern, hochauflösend und **ohne Pixel-Art** mit lebendigen 4-Wege-Bewegungsanimationen.

## Status
* **Version:** `v0.1.0` (M0: Grundgerüst, Services, Test-Suite und Prototyp)
* **Plan:** [plans/07_lumaria.md](../plans/07_lumaria.md)

## Steuerung
* **Bewegen:** WASD oder Pfeiltasten / Gamepad linker Stick
* **Schwertangriff:** Leertaste / J / Linksklick (Halten für 360°-Wirbelattacke)
* **Ausweichrolle / Dash:** Linke Umschalttaste (Shift) / K / Gamepad A
* **Schild heben / Timing-Parry:** Rechtsklick / L / Gamepad linker Schulterknopf
* **Interagieren / Sprechen:** E oder F / Gamepad Y
* **Gadgets:** Q / R (Slots 1 & 2)
* **Vollbild:** F11 oder Alt+Enter
* **Pause:** Escape oder P

## Tests ausführen
```bash
# Im Projekt-Wurzelverzeichnis
godot --headless --path lumaria -s res://tests/run_tests.gd
godot --headless --fixed-fps 480 --path lumaria res://tests/smoke.tscn
```
