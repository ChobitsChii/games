# AGENTS.md – Arbeitsanweisungen für KI-Agenten und Mitwirkende

Dieses Repo enthält kleine, modern gestaltete Spiele mit **Godot 4.7 (GDScript)** für Linux, Windows und Web.
Gilt für jedes Modell und jeden Menschen. Bitte vor der Arbeit lesen.

## 1. Zuerst lesen
1. [plans/00_README_Engine_und_Uebersicht.md](plans/00_README_Engine_und_Uebersicht.md): Entscheidungen, Struktur, Definition of Done
2. Den Plan des Spiels, an dem gearbeitet wird (`plans/0N_*.md`), und den Stand in dessen `README.md`
3. Die Meilensteine im Plan der Reihe nach abarbeiten. Abgeschlossene mit ✅ markieren.

## 2. Arbeitsablauf
1. Kleine Schritte, nach **jeder** Änderung `tools/run_tests.sh` ausführen. Es muss grün sein.
2. Neue Logik bekommt Tests in `<spiel>/tests/test_*.gd` (Methoden `test_*`, Basisklasse `TestCase`).
3. Spielbares prüfen: Autopilot-Smoke-Test, bei optischen Änderungen zusätzlich ein Screenshot (siehe 5.).
4. Commit pro Meilenstein oder sinnvoller Einheit (Conventional Commits, z. B. `feat(breakout): ...`, `fix(...)`), dann `git push`.
5. **Releases & Versionierung:** Nach Meilensteinen oder relevanten Änderungen (neue Features, Bugfixes, Assets) ein Release erstellen mit `tools/release_game.sh <spiel> [patch|minor|major]` (z. B. `tools/release_game.sh lane_defenders minor`). Das Skript testet, baut, schnürt ZIPs, erstellt das GitHub-Release, aktualisiert `<spiel>-latest`, pflegt die `README.md` und stößt den Pages-Deploy an.
6. Bei Fehlern von Spielern: Seed und Schritte erfragen, per Test oder Autopilot reproduzieren, beheben, Test ergänzen.
7. Pläne, `README.md` des Spiels und `CREDITS.md` aktuell halten.

## 3. Verbindliche Regeln
- **Kein Pixel-Art.** Modern, hochauflösend, Linear-Filter. Basis-Auflösung 1920×1080 (`canvas_items`, `keep`).
- **Keine festen Texte** in Code oder Szenen. Alles über Schlüssel (`tr("KEY")`, in Szenen `text = "KEY"`) in `<spiel>/i18n/<spiel>.csv` oder `shared/i18n/common.csv` mit den Spalten `keys,de,en`. Neue Sprache = neue Spalte plus Eintrag in `LocaleService.SUPPORTED` und `LANGUAGE_NAMES`. Schlüssel-Präfixe, die der Test erkennt, stehen in `tests/test_i18n.gd`.
- **Assets:** nur frei nutzbare (bevorzugt CC0, dann CC-BY). Nie CC-BY-SA, GPL, NC oder ND. **Vor** dem Einbinden in `CREDITS.md` des Spiels eintragen (Asset, Autor, URL, Lizenz, Verwendung), Lizenztext neben die Dateien legen.
- **Renderer:** `gl_compatibility` (Web-Pflicht). Keine Features, die nur Forward+ kann. Kein `msaa_2d` setzen (nicht unterstützt, erzeugt Warnung).
- **Vollbild/Sprache/Speichern** nur über die Services aus `shared/` (`DisplayService`, `LocaleService`, `SaveService`).
- **Logik getrennt von Darstellung:** Spielregeln, KI und Berechnungen in Klassen ohne Nodes (`class_name … extends RefCounted`), damit sie testbar sind.
- **Reproduzierbarkeit:** Zufall über einen `RandomNumberGenerator` mit ausgegebenem und per `-- --seed=N` setzbarem Seed.
- **Statische Typen** in GDScript (`var x: int`, Rückgabetypen).
- **Versionierung:** Semantic Versioning (`v<Major>.<Minor>.<Patch>`). Vollständig spielbare Spiele (M0–M7) starten mit `v1.0.0`, frühe Prototypen mit `v0.1.0`. Features = Minor-Bump (`v1.1.0`), Fixes = Patch-Bump (`v1.0.1`). Nach jedem Release den Floating Tag `<spiel>-latest` aktualisieren (erledigt `tools/release_game.sh` automatisch).
- Bestehende Kommentare und Doku, die nichts mit der Änderung zu tun haben, bleiben erhalten.

## 4. Projektstruktur und gemeinsamer Code
```
plans/  shared/  tools/  build/(ignoriert)  <spiel>/(Godot-Projekt)
```
- `shared/` ist die **einzige Quelle** für gemeinsamen Code. Nie direkt in `<spiel>/addons/shared/` ändern.
- Nach Änderungen an `shared/` immer `tools/sync_shared.sh` ausführen (`run_tests.sh` und `build_all.sh` tun das automatisch). Die Kopie wird eingecheckt.
- Neues Spiel: Ordner `<spiel>/` mit `project.godot` anlegen (Vorlage: `neon_breakout/project.godot`, Autoloads `SaveService`, `LocaleService`, `DisplayService`), `tools/gen_input_map.gd` für die Input Map nutzen, `export_presets.cfg` (Linux, Windows, Web, `exclude_filter="tests/*"`) und `tests/` (`run_tests.gd`, `test_case.gd`, `smoke.tscn`) aus `neon_breakout` übernehmen.

## 5. Befehle
Alle im Repo-Wurzelverzeichnis:
```bash
tools/sync_shared.sh                         # shared/ in alle Spiele kopieren
tools/run_tests.sh                           # Logik-Tests und Smoke-Test aller Spiele
tools/build_all.sh [spiel]                   # Exporte nach build/<spiel>/{linux,windows,web}
tools/serve_web.sh <spiel> [port]            # Web-Build lokal ansehen
tools/build_web_portal.sh [ziel]             # Web-Portal für GitHub Pages bauen
tools/package_release.sh <spiel> <version>   # Release-ZIPs (Linux, Windows, Web) packen
tools/release_game.sh <spiel> [art]          # Komplettes Release erstellen, taggen, hochladen & README updaten
godot --path <spiel>                         # Spiel starten
godot --path <spiel> -- --seed=42            # mit festem Seed
godot --headless --path <spiel> --import     # nach neuen Skripten, class_name, Assets, CSV
godot --headless --path <spiel> -s ../tools/gen_input_map.gd   # Input Map neu schreiben
```
**Screenshot** (braucht ein echtes Fenster, geht nicht mit `--headless`): temporäre Szene, die nach ein paar Frames `get_viewport().get_texture().get_image().save_png("/tmp/x.png")` ausführt, mit `godot --path <spiel> res://tests/<tmp>.tscn` starten, ansehen, danach die temporären Dateien wieder löschen.

## 6. Bekannte Stolperfallen
- **Nach neuen Skripten mit `class_name`, neuen Autoloads, Assets oder CSV-Änderungen** `--import` ausführen, sonst fehlen Klassen bzw. `.translation`-Dateien. Die Übersetzungsdateien müssen unter `[internationalization]` in `project.godot` eingetragen sein.
- **`AnimatableBody2D`, das im Skript selbst bewegt wird:** `sync_to_physics = false` setzen, sonst überschreibt die Physik die Position (Schläger stand bei y = 0).
- **Eingabesperren und Timer in Spielzeit (`delta`) zählen**, nicht mit `Time.get_ticks_msec()`. Tests laufen schneller als Echtzeit.
- **Schnelle Tests:** `godot --headless --fixed-fps 480 --path <spiel> res://tests/smoke.tscn`. Nicht `Engine.time_scale` verwenden, das lässt die Physik tunneln.
- **Input Map:** Ereignisse mit `device = -1` ("alle Geräte") speichern. Der Generator `tools/gen_input_map.gd` macht das richtig.
- **Ball-/Projektilbewegung** mit `move_and_collide` und eigener Abprallberechnung statt Physik-Impuls (kein Tunneln, genau steuerbar).
- **Kommandozeilen-Argumente fürs Spiel** stehen hinter `--` und werden mit `OS.get_cmdline_user_args()` gelesen.
- **Web:** Audio und Vollbild starten erst nach einer Nutzeraktion. Kein exklusives Vollbild, kein "Beenden"-Button. Single-Threaded-Export (Standard). Große Mengen `GPUParticles2D` sparsam einsetzen. Web-Export-Templates liegen in `~/.local/share/godot/export_templates/4.7.2.stable/` (Dateien `web_*.zip`).
- **Layouts** müssen längere deutsche Texte vertragen (Container und Autowrap statt fester Größen).

## 7. Fertig heißt
Siehe „Definition of Done“ in [plans/00_README_Engine_und_Uebersicht.md](plans/00_README_Engine_und_Uebersicht.md) und die Abnahmekriterien im jeweiligen Plan.
