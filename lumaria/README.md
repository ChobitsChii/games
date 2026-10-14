# 💎 Lumaria: The Prismatic Odyssey

Modernes 2D-Action-Adventure (Top-Down-RPG) mit Godot 4.7 (GDScript) für Linux, Windows und Web.
Vollkommen eigenständige Welt und Lore – modern, hochauflösend und **ohne Pixel-Art** mit lebendigen 4-Wege-Bewegungsanimationen.

## Status
* **Version:** `v1.0.0` (Vollständig spielbar, alle Meilensteine M0–M8 abgeschlossen: Grundgerüst, 4-Wege-Bewegungsanimationen, Schwertkombo & 360°-Wirbelattacke, Aegis-Schildblock & Timing-Parry, Oakhaven mit 3 NPCs & zweisprachigem Dialogsystem, 3 Standard-Gegner mit KI, Gadget 1: Prisma-Bumerang, Dungeon 1: Wurzel-Schrein & Boss Floragorg, Oberwelt: Flüsternde Untiefen, Gadget 2: Kinetisches Fangseil, Dungeon 2: Klingen-Krypta & Boss Carapax, Oberwelt: Donnerplateau, Gadget 3: Schall-Bomben mit Kettenreaktionen & Felssprengung, Dungeon 3: Sturm-Bastion mit Wind-Turbinen & Boss Zephyros, Showdown: Turm des Ewigen Prismas mit Multitool-Prüfungen & 3-Phasen-Endboss Malakor, Sieges-Bildschirm mit Epilog & Heldenstatistiken, atmosphärische Musik-Soundtracks & SFX, vollständige Exporte für Linux, Windows und Web)
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
