# 💎 Lumaria: The Prismatic Odyssey

Modernes 2D-Action-Adventure (Top-Down-RPG) mit Godot 4.7 (GDScript) für Linux, Windows und Web.
Vollkommen eigenständige Welt und Lore – modern, hochauflösend und **ohne Pixel-Art** mit lebendigen 4-Wege-Bewegungsanimationen.

## Status
* **Version:** `v0.6.0` (M0, M1, M2, M3, M4, M5 & M6 abgeschlossen: Grundgerüst, 4-Wege-Bewegungsanimationen, 3-Treffer-Kombo, aufladbarer Rundumschlag, Waffen-Trail, Schildblock & Timing-Parry, zerstörbare Krüge/Gras, Drops, Screen-Shake, Oakhaven-Kollisionen, 3 Dorf-NPCs & zweisprachiges Dialogsystem, 3 Standard-Gegner mit KI, Projektil-Reflektion, Prisma-Bumerang-Gadget, Ausrüstungs- und Inventarmenü, Dungeon 1: Wurzel-Schrein & Boss 1: Floragorg mit Sonnen-Prisma, Oberwelt-Erweiterung: Flüsternde Untiefen, Gadget 2: Kinetisches Fangseil [Hookshot] mit Pfahl-Grappling, Item-Heranziehen & Schild-Entreißen, Dungeon 2: Klingen-Krypta mit Schlucht-Überquerungen, Stachelfallen & Schalterrätseln, Boss 2: Carapax [Kristall-Panzerkrabbler] mit Panzerungs-Mechanik & Gezeiten-Prisma)
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
