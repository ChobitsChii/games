# 🎮 Mini-Games Projekt – Übersicht & Engine-Entscheidung

Sammlung kleiner Spiele (Single Player oder gegen den Computer), die **nativ unter Linux und Windows** laufen und zusätzlich als **HTML5-Version im Browser** spielbar sind. Sie sollen **modern und hochwertig aussehen**, **zweisprachig (Deutsch/Englisch)** sein und weitere Sprachen ohne Code-Änderung unterstützen.

> [!NOTE]
> Arbeitsanweisungen für KI-Agenten und Mitwirkende (Ablauf, Regeln, Befehle, Stolperfallen) stehen in [AGENTS.md](../AGENTS.md).

## 1. Engine-Entscheidung: **Godot 4.7** (GDScript)

| Kriterium | Godot 4.7 | Unity 6 | Unreal 5 | Phaser 3 + Wrapper | Bevy (Rust) |
|---|---|---|---|---|---|
| Native Linux + Windows | ✅ direkt exportierbar | ✅ | ✅ | ⚠️ nur über Electron/Tauri | ✅ |
| HTML5/Web-Export | ✅ eingebaut | ✅ WebGL/WebGPU | ❌ nur Pixel Streaming | ✅ nativ | ⚠️ WASM, aufwendig |
| Szenen/Assets als Text (KI-editierbar) | ✅ `.gd`, `.tscn`, `.tres` | ⚠️ YAML + viele `.meta`-Dateien, Editor-lastig | ❌ binär (`.uasset`, `.umap`) | ✅ | ✅ |
| Headless Test/Export per CLI | ✅ `godot --headless` | ⚠️ aufwendiger | ⚠️ | ✅ npm | ✅ cargo |
| Linux-Editor | ✅ nativ (Arch vorhanden) | ⚠️ offiziell nur Ubuntu | ⚠️ | – | – |
| Lizenz | MIT, frei | Personal frei bis 200 k USD Umsatz | Royalty-Modell | frei | frei |
| Fehlerbehebung durch mich | ✅ sehr gut | ⚠️ | ❌ | ✅ | ⚠️ |

**Begründung:**
- Auf dem System ist bereits **Godot 4.7.2** samt passenden **Export-Templates** installiert (`/usr/bin/godot`).
- Szenen, Skripte und Ressourcen sind reiner Text, deshalb kann ich sie direkt lesen, ändern und per Diff nachvollziehen.
- Ich kann Spiele per CLI starten, prüfen und exportieren, ohne den Editor zu öffnen. So kann ich Fehler reproduzieren und beheben, wenn ein Mensch einen meldet.
- Ein Projekt ergibt drei Ziele: **Linux**, **Windows (`.exe`)** und **Web (HTML5/WASM)**.
- Die Optik hängt bei kleinen Spielen von Art Direction und Effekten ab, nicht von der Engine (siehe Abschnitt 3).

> [!NOTE]
> **Proton ist nicht nötig.** Godot exportiert eine echte Windows-`.exe`, die sich von Linux aus erzeugen lässt. Proton oder Wine braucht man nur optional, um den Windows-Build auf dem Linux-Rechner zu testen.

## 2. Technische Leitplanken (für alle Spiele)

- **Renderer:** `gl_compatibility`. Der Web-Export unterstützt in Godot 4 nur diesen Renderer. Alle Effekte müssen darin funktionieren (Glow, Partikel, `PointLight2D`, eigene Shader).
- **Sprache:** GDScript mit statischer Typisierung (`var x: int`).
- **Web-Export:** Single-Threaded (Standard seit 4.3). Es braucht keine COOP/COEP-Header und läuft auf itch.io, GitHub Pages usw.
- **Auflösung:** Basis 1920×1080 (Vektor- und Hochauflösungs-Assets, kein Pixel-Look), Stretch-Mode `canvas_items`, Aspect `keep`.
- **Eingabe:** Alles über die Input Map (Tastatur + Gamepad). Bei Web zusätzlich Maus/Touch, wo sinnvoll.
- **Speicherstand/Highscore:** `user://` (im Browser landet das in IndexedDB).
- **Audio:** Im Web startet Audio erst nach der ersten Nutzer-Interaktion. Jedes Spiel hat deshalb einen "Start"-Screen.

### 2.1 Lokalisierung (Deutsch + Englisch, erweiterbar)

- **Von Anfang an:** Kein Text steht fest im Code oder in Szenen. Alles läuft über Schlüssel (`tr("MENU_PLAY")`). Control-Nodes übersetzen ihre Texte automatisch, wenn dort ein Schlüssel steht.
- **Format:** Eine CSV pro Spiel und eine für gemeinsame Texte (`shared/i18n/common.csv`) mit den Spalten `keys,de,en`. Godot importiert sie automatisch zu `.translation`-Dateien. Eine neue Sprache ist eine neue Spalte.
- **Sprachwahl:** Beim ersten Start wird die Systemsprache genommen (`OS.get_locale_language()`), mit Fallback `en`. Im Optionsmenü kann man sie ändern, die Wahl wird gespeichert.
- **Platzhalter:** `tr("SCORE_FMT") % score` mit `%d` im Text. Pluralformen über eigene Schlüssel.
- **Schriftarten:** Müssen Umlaute und `ß` sowie später weitere Zeichensätze abdecken. Wir nehmen Fonts mit breitem Unicode-Umfang (z. B. Noto Sans) als Fallback.
- **Layout:** Alle UI-Elemente müssen längere Texte vertragen (Deutsch ist oft ~30 % länger). Deshalb Container und Autowrap statt fester Größen.
- **Test:** Ein Test prüft, dass jeder Schlüssel in allen Sprachen einen Eintrag hat und keine Schlüssel ungenutzt oder fehlend sind. Ein Pseudo-Sprachtest zeigt hartkodierte Texte.

### 2.2 Vollbild und Darstellung

- Optionen: **Fenster** (Standard beim ersten Start), **rahmenloses Vollbild** und **exklusives Vollbild** (im Browser nur Fenster/Vollbild). Umschalten mit `F11` und `Alt+Enter` sowie im Optionsmenü. Die Wahl wird gespeichert.
- Auflösungsunabhängig dank Stretch-Mode `canvas_items`, bei anderem Seitenverhältnis erscheinen Balken oder erweiterte Ränder (Hintergrund wird dafür über den sichtbaren Bereich hinaus gezeichnet).
- Optional einstellbar: VSync, FPS-Limit, Effekt-Qualität (Glow an/aus, Partikeldichte), Bildschirmschütteln an/aus.
- **Web:** Vollbild funktioniert nur nach einer Nutzer-Aktion (Browser-Regel). Ein Button "Vollbild" im Spiel löst das aus.

## 3. Optik & Assets

### 3.1 Stilvorgaben
- ❌ **Kein Pixel-Art.** Wir nutzen keine Pixel-Assets, keine Pixel-Fonts und keine ganzzahlige Pixel-Skalierung.
- ✅ **Modern, sauber, hochauflösend:** Flat/Vektor-Optik, weiche Verläufe, Glow, Schatten, abgerundete Formen, sanfte Animationen.
- ✅ **Pro Spiel eine feste Farbpalette** (max. ~6 Hauptfarben) und ein eigenes UI-Theme statt des Godot-Standard-Themes.
- ✅ **Texturfilter:** `Linear` mit Mipmaps (nicht `Nearest`).
- ✅ **Wo es passt, 3D-Low-Poly oder 3D-Optik in 2.5D** (z. B. Brettspiele). Auch das läuft im Compatibility-Renderer.

### 3.2 Was "schön" in Godot ausmacht (Checkliste je Spiel)
- Glow/Bloom, Vignette, leichte Farbkorrektur über `WorldEnvironment` oder eigene Shader (Compatibility-tauglich)
- `PointLight2D`/`DirectionalLight2D` und weiche Schatten dort, wo sie wirken
- Partikel (`GPUParticles2D`, im Web sparsam nutzen oder `CPUParticles2D`) für Treffer, Explosionen und Staub
- Tweens für Squash-and-Stretch, Easing, Pop-in/-out bei Menüs und Zahlen
- Screen-Shake, Hit-Stop, Kamera-Zoom-Impulse
- Hintergründe mit Parallax und Shadern (bewegte Verläufe, Rauschen)
- Hochwertiger Font, konsistente Icons, weiche Übergänge zwischen Szenen
- Sound-Design: jedes wichtige Ereignis hat einen passenden, leicht variierten Ton

### 3.3 Asset-Quellen (nur frei nutzbare)

| Quelle | Inhalt | Lizenz |
|---|---|---|
| [Kenney.nl](https://kenney.nl) | Sprites (viele Pakete im flachen Vektor-Stil), UI, Icons, Partikel, Sounds, Fonts, 3D-Kits | CC0 |
| [Quaternius](https://quaternius.com) | 3D-Modelle (Low-Poly) | CC0 |
| [OpenGameArt.org](https://opengameart.org) | Grafik, Musik, SFX | gemischt, nur CC0/CC-BY übernehmen |
| [Freesound](https://freesound.org) | Sounds | gemischt, nur CC0/CC-BY übernehmen |
| [Google Fonts](https://fonts.google.com) | Schriften | OFL |
| Incompetech, Pixabay Music u. ä. | Musik | CC-BY bzw. Pixabay-Lizenz, jeweils einzeln prüfen |
| **Eigene Assets** | Shader, Vektorgrafik (SVG), Partikel, generierte Bilder (Hintergründe, Icons, Konzeptbilder) | eigene |

**Auswahlregeln:**
1. Stil prüfen: kein Pixel-Art, passt zur Palette des Spiels.
2. Lizenz prüfen: bevorzugt **CC0**, dann **CC-BY**. **Keine** CC-BY-SA-, GPL-, NC- oder ND-Assets.
3. Jedes Asset sofort in `CREDITS.md` eintragen, bevor es ins Spiel kommt.
4. Quelle und Lizenztext als Datei neben die Assets legen (`assets/<paket>/LICENSE.txt`).
5. Konkrete Pakete werden erst bei der Umsetzung ausgewählt und angesehen. Die Namen in den Plänen sind Vorschläge.

### 3.4 Credits
- **`CREDITS.md`** im Repo-Wurzelverzeichnis und je Spiel. Tabelle mit: Asset, Autor, Quelle (URL), Lizenz, verwendet in.
- **Credits-Bildschirm** im Spiel (übersetzbar), der die Datei zur Build-Zeit einliest.
- Für generierte Bilder vermerken wir "selbst generiert" und das verwendete Werkzeug.

## 4. Projektstruktur

```
games/                      # Repo-Wurzel (lokal: ~/development/games, GitHub: games)
├── plans/                  # diese Pläne
├── shared/                 # Quelle der gemeinsamen Bausteine (Menü, Audio, Save, i18n, Theme)
├── tools/                  # build_all.sh, run_tests.sh, serve_web.sh, sync_shared.sh
├── neon_breakout/          # je Spiel ein eigenes Godot-Projekt direkt in der Wurzel
│   ├── project.godot
│   ├── scenes/  scripts/  assets/  i18n/  tests/
│   ├── addons/shared/      # eingecheckte Kopie von shared/ (per tools/sync_shared.sh)
│   ├── CREDITS.md
│   └── export_presets.cfg
├── connect_four/  asteroid_drift/  block_stack/  lane_defenders/  crypt_dash/  ...
├── build/                  # Export-Ausgabe (gitignored)
├── CREDITS.md              # Sammel-Credits
├── .gitignore  .gitattributes
└── README.md
```

> [!NOTE]
> **Gemeinsamer Code:** Ein Godot-Projekt kann nur Dateien unterhalb seines eigenen Ordners per `res://` laden. `shared/` liegt aber außerhalb der Spiel-Projekte. Deshalb kopiert `tools/sync_shared.sh` den Inhalt von `shared/` in `<spiel>/addons/shared/`. Die Kopie wird eingecheckt. Das funktioniert unter Linux und Windows und braucht keine Symlinks. Änderungen macht man nur in `shared/` und synchronisiert danach.

### Standard-Kommandos

```bash
# Alle Befehle im Repo-Wurzelverzeichnis (games/) ausführen
# Projekt importieren (einmalig/nach Asset-Änderungen)
godot --headless --path <spiel> --import

# Skripte auf Syntaxfehler prüfen
godot --headless --path <spiel> --check-only --quit

# Spiel starten / kurz headless laufen lassen (Smoke-Test)
godot --path <spiel>
godot --headless --path <spiel> --quit-after 300

# Exporte
godot --headless --path <spiel> --export-release "Linux"   build/<spiel>/linux/<spiel>.x86_64
godot --headless --path <spiel> --export-release "Windows" build/<spiel>/windows/<spiel>.exe
godot --headless --path <spiel> --export-release "Web"     build/<spiel>/web/index.html

# Web-Build lokal testen
python -m http.server 8080 --directory build/<spiel>/web
```

## 5. Git & Backup

- **Lokales Git-Repo** im Verzeichnis `games/`, ein Repo für alle Spiele.
- **Branching:** `main` bleibt immer lauffähig. Größere Arbeiten laufen auf Branches (`feature/<spiel>-<thema>`), Merge nach Meilenstein.
- **Commits:** kleine, sprechende Commits (Conventional Commits wie `feat(breakout): ...`, `fix(connect4): ...`), mindestens einer pro Meilenstein.
- **Tags:** pro veröffentlichtem Stand, z. B. `breakout-v0.1.0`.
- **`.gitignore`:** `.godot/`, `build/`, `*.import` nicht ignorieren (Godot empfiehlt, `.import`-Dateien einzuchecken), Editor- und Betriebssystem-Dateien.
- **Große Dateien:** Binäre Assets (Audio, große Texturen) über **Git LFS**, falls das Repo wächst.
- **Privates GitHub-Repo** als Spiegel/Backup (`git remote add origin ...`, regelmäßiges `git push`). Wird erst nach deiner Bestätigung eingerichtet.
- **Lizenzen:** Eigener Code vorerst ohne Lizenz-Datei (privat). Vor einer Veröffentlichung wählen wir eine Lizenz aus.

## 6. Qualitätssicherung / Fehlerbehebung

- **Unit-Tests:** Für Spiellogik wie KI, Punktezählung und Kollisionsregeln. Die Logik wird bewusst von der Darstellung getrennt. Aktuell nutzen wir einen kleinen eigenen Runner (`tests/run_tests.gd`, ohne Fremdabhängigkeit). Bei Bedarf wechseln wir später auf [gdUnit4](https://github.com/MikeSchulze/gdUnit4).
- **Smoke-Test:** Jedes Spiel läuft headless mit einem Autopiloten (`tests/smoke.tscn`, mit `--fixed-fps 480` schneller als in Echtzeit) ohne Fehler im Log. `tools/run_tests.sh` führt alles aus.
- **Lokalisierungstest:** Alle Schlüssel in allen Sprachen vorhanden.
- **Debug-Overlay** (F3): FPS, Entity-Zahl, Seed, aktueller Zustand.
- **Reproduzierbarkeit:** Zufall läuft über einen `RandomNumberGenerator` mit sichtbarem Seed. Ein Bug-Report kann den Seed nennen.
- **Fehlerworkflow:** Bug melden → Seed/Schritte nennen → ich reproduziere per Test oder headless → Fix → Test ergänzen → Neu-Export.
- **Screenshots:** Für optische Fehler kann ich Screenshots aus einem Lauf erzeugen und prüfen.

## 7. Spieleübersicht

| # | Spiel | Genre | Modus | Aufwand | Optik | Plan |
|---|---|---|---|---|---|---|
| 1 | **Neon Breakout** | Arcade / Breakout | Single Player | ⭐ | Neon, Glow, Vektor | [01_neon_breakout.md](01_neon_breakout.md) |
| 2 | **Asteroid Drift** | Arcade-Shooter | Single Player | ⭐⭐ | Sci-Fi, Glow, Flat | [02_asteroid_drift.md](02_asteroid_drift.md) |
| 3 | **Connect Four Deluxe** | Brettspiel | vs. Computer | ⭐⭐ | 3D/2.5D, Holz oder Glas | [03_vier_gewinnt.md](03_vier_gewinnt.md) |
| 4 | **Block Stack** | Puzzle / Tetris-Like | Single Player (+ CPU-Duell) | ⭐⭐ | Glas, Gradients, Glow | [04_block_stack.md](04_block_stack.md) |
| 5 | **Lane Defenders** | Mini-Tower-Defense | Single Player | ⭐⭐⭐ | Flat-Cartoon, Vektor | [05_lane_defenders.md](05_lane_defenders.md) |
| 6 | **Crypt Dash** | Top-Down Roguelite | Single Player | ⭐⭐⭐ | Stilisiert, Licht und Schatten | [06_crypt_dash.md](06_crypt_dash.md) |

### Empfohlene Reihenfolge

0. **Repo & Grundgerüst:** Git, Struktur, `shared/` mit Theme, i18n, Optionen und Vollbild.
1. **Neon Breakout:** kleinstes Spiel, richtet Export-Pipeline und Menü-Grundgerüst ein und enthält den **Optik-Vertical-Slice**.
2. **Connect Four Deluxe:** Spiellogik und KI, gut testbar.
3. **Asteroid Drift:** Physik, Partikel, Juice.
4. **Block Stack:** Zustandsautomaten, Timing, optional KI-Gegner.
5. **Lane Defenders:** Wellen, Balancing, Daten per Ressourcen.
6. **Crypt Dash:** prozedurale Level, Gegner-KI, Items.

## 8. Gemeinsame Bausteine (in `shared/`)

- Hauptmenü, Pause-Menü, Optionen (Lautstärke, Anzeigemodus/Vollbild, Sprache, Effekt-Qualität)
- `SaveService` (Highscore und Einstellungen als `ConfigFile`)
- `AudioService` (Bus-Layout, SFX-Pool, Musik)
- `LocaleService` (Spracherkennung, Wechsel, Speichern)
- `DisplayService` (Fenster/Vollbild, F11, VSync)
- Gemeinsames UI-Theme-Gerüst (pro Spiel mit eigener Palette überschreibbar)
- Screen-Shake, Partikel-Presets, Tween-Helfer, Szenenübergänge
- Gamepad-Glyphen, Fokus-Navigation in Menüs
- Credits-Bildschirm

## 9. Definition of Done (pro Spiel)

- [ ] Spielbar von Menü bis Game Over und Neustart
- [ ] Läuft nativ unter Linux **und** als Windows-Export (mindestens Wine/Proton-Test)
- [ ] Web-Export läuft in Chromium und Firefox
- [ ] **Alle Texte übersetzt (DE/EN)**, Lokalisierungstest grün, Layout hält längere Texte aus
- [ ] **Vollbild/Fenster-Umschaltung** funktioniert, Auswahl wird gespeichert
- [ ] **Optik:** Checkliste aus 3.2 abgearbeitet, kein Pixel-Look
- [ ] **`CREDITS.md`** vollständig, Lizenzen geprüft, Credits-Bildschirm vorhanden
- [ ] Highscore oder Fortschritt bleibt gespeichert
- [ ] Keine Fehler/Warnungen im Log bei Smoke-Test
- [ ] Tests für die Kernlogik grün
- [ ] Kurzes README pro Spiel (Steuerung, Build-Anleitung)
- [ ] Alles committed, Tag gesetzt

## 10. Entscheidungen (Stand: Abstimmung mit Jennifer)

| Thema | Entscheidung |
|---|---|
| Engine | Godot 4.7 (GDScript) |
| Grafikstil | Modern, hochauflösend, **kein Pixel-Art** |
| Assets | Frei nutzbar (bevorzugt CC0/CC-BY) mit `CREDITS.md` |
| Sprachen | Deutsch und Englisch, erweiterbar über CSV |
| Vollbild | In jedem Spiel, speicherbar |
| Veröffentlichung | Erst lokal mit Git, privates GitHub-Repo als Backup (Einrichtung nach Bestätigung) |
| Musik | Kurze CC0/CC-BY-Loops oder einfache generierte Musik |
