# 💎 Lumaria: The Prismatic Odyssey

Modernes 2D-Action-Adventure (Top-Down-RPG) mit Godot 4.7 (GDScript) für Linux, Windows und Web.
Vollkommen eigenständige Welt und Lore – modern, hochauflösend und **ohne Pixel-Art** mit lebendigen 4-Wege-Bewegungsanimationen.

## Status
* **Version:** `v1.1.0` (Vollständig spielbar, M0–M8 + umfassendes HD-Grafik- & Gameplay-Update: sauber freigestellte 4-Wege-Kaelen-Sprites inkl. Rückenansicht, ganzfigurige HD-NPCs für Morwen, Thalon & Lyra, neu gestaltete HD-Gegner & alle 4 Bosse mit weichen Bodenschatten, 6 überarbeitete 1920×1080-Gebiets-Hintergründe, Leucht-Kristallsphären-HUD, lokalisierte `[Q]`/`[R]`-Gadget-Anzeige, begehbare Oakhaven-Wege mit abgestimmten Wegweisern & Kollidern, korrigierte Portal-Spawns, echtes Schadensmodell/Parry-System, Y-Sorting sowie Pausen-/Game-Over-Overlays in allen 7 Weltszenen)
* **Plan:** [plans/07_lumaria.md](../plans/07_lumaria.md)

## Steuerung
* **Bewegen:** WASD oder Pfeiltasten / Gamepad linker Stick
* **Schwertangriff:** Leertaste / J / Linksklick (Halten für 360°-Wirbelattacke)
* **Ausweichrolle / Dash:** Linke Umschalttaste (Shift) / K / Gamepad A
* **Schild heben / Timing-Parry:** Rechtsklick / L / Gamepad linker Schulterknopf
* **Interagieren / Sprechen:** E oder F / Gamepad Y
* **Gadgets:** Q / R (Slots 1 & 2)
* **Inventar & Ausrüstung:** Tab oder I / Gamepad Select
* **Vollbild:** F11 oder Alt+Enter
* **Pause:** Escape oder P

## Tests ausführen
```bash
# Im Projekt-Wurzelverzeichnis
godot --headless --path lumaria -s res://tests/run_tests.gd
godot --headless --fixed-fps 480 --path lumaria res://tests/smoke.tscn
```
