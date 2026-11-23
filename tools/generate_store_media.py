#!/usr/bin/env python3
"""Erzeugt Chii Arcade Store-Medien (cover.webp 1280x720 + 4 echte Gameplay-Screenshots je Spiel).

Für jedes der 7 Spiele werden:
  1. store-media/cover.webp aus dem 1920x1080-Boot-Logo (splash.png) in 1280x720 (WebP) erzeugt.
  2. Temporäre Testszenen (_tmp_capture.tscn/.gd) unter xvfb-run + OpenGL3/X11 gestartet,
     um 4 echte In-Game-Screenshots als PNG aufzunehmen, in 1280x720 WebP umzuwandeln
     und danach alle temporären Dateien wieder restlos zu entfernen.
"""
from __future__ import annotations

import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
from PIL import Image, ImageStat

ROOT = Path(__file__).resolve().parent.parent
TARGET_SIZE = (1280, 720)
WEBP_QUALITY = 88

SPLASH_SOURCES = {
    "neon_breakout": "assets/splash.png",
    "asteroid_drift": "assets/graphics/splash.png",
    "vier_gewinnt": "assets/splash.png",
    "block_stack": "assets/splash.png",
    "lane_defenders": "assets/splash.png",
    "crypt_dash": "assets/splash.png",
    "lumaria": "assets/splash.png",
}

CAPTURES: dict[str, dict] = {
    "neon_breakout": {
        "files": [
            "01-main-menu.webp",
            "02-classic-gameplay.webp",
            "03-boss-fight.webp",
            "04-mode-select.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(18)
\tawait _snap("{OUT_DIR}/01.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Klassisches Gameplay mit aktivem Ball & Power-Ups
\tGameMode.selected = GameMode.Id.CLASSIC
\tvar g1 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg1.autoplay = true
\tadd_child(g1)
\tawait _wait_frames(110)
\tg1.apply_powerup(PowerUps.Kind.MULTI)
\tg1.apply_powerup(PowerUps.Kind.WIDE)
\tawait _wait_frames(45)
\tawait _snap("{OUT_DIR}/02.png")
\tg1.queue_free()
\tawait _wait_frames(3)

\t# 3. Bosskampf-Modus
\tGameMode.selected = GameMode.Id.BOSS
\tvar g2 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg2.autoplay = true
\tadd_child(g2)
\tawait _wait_frames(95)
\tawait _snap("{OUT_DIR}/03.png")
\tg2.queue_free()
\tawait _wait_frames(3)

\t# 4. Spielmodus-Auswahl
\tvar modes := (load("res://scenes/mode_select.tscn") as PackedScene).instantiate()
\tadd_child(modes)
\tawait _wait_frames(12)
\tawait _snap("{OUT_DIR}/04.png")
\tmodes.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "asteroid_drift": {
        "files": [
            "01-main-menu.webp",
            "02-space-combat.webp",
            "03-ufo-wave.webp",
            "04-upgrade-picker.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(18)
\tawait _snap("{OUT_DIR}/01.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Weltraumkampf (Welle 1 mit Autopilot)
\tvar g := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg.autoplay = true
\tadd_child(g)
\tawait _wait_frames(75)
\tawait _snap("{OUT_DIR}/02.png")

\t# 3. UFO & Mine spawnen
\tg._spawn_ufo(false)
\tg._spawn_mine()
\tawait _wait_frames(45)
\tawait _snap("{OUT_DIR}/03.png")

\t# 4. Tech-Upgrade-Auswahl
\tvar opts := UpgradeSystem.roll_random_upgrades({}, 3, g._rng)
\tg.upgrade_picker.display_options(opts)
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/04.png")

\tg.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "vier_gewinnt": {
        "files": [
            "01-main-menu.webp",
            "02-board-match.webp",
            "03-colorblind-hint.webp",
            "04-stats-modal.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(14)
\tawait _snap("{OUT_DIR}/01.png")

\t# 4. Statistik-Dialog (direkt vom Menü)
\tmenu._on_open_stats()
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/04.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Spannendes Match auf dem 7x6-Brett
\tvar g := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tadd_child(g)
\tawait _wait_frames(6)
\tfor col: int in [3, 3, 2, 4, 2, 5, 1, 3, 4, 2]:
\t\tg.controller.board.play(col)
\tg.controller.state = GameController.State.PLAYER_TURN
\tg.board_view.queue_redraw()
\tg.hud._update_ui()
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/02.png")

\t# 3. Farbenblindheitsmodus + Zug-Tipp
\tg.controller.colorblind_mode = true
\tg.board_view.queue_redraw()
\tg.controller.request_hint()
\tawait _wait_frames(12)
\tawait _snap("{OUT_DIR}/03.png")

\tg.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "block_stack": {
        "files": [
            "01-main-menu.webp",
            "02-marathon-play.webp",
            "03-cpu-duel.webp",
            "04-options-colorblind.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(14)
\tawait _snap("{OUT_DIR}/01.png")

\t# 4. Optionsmenü mit DAS/ARR & Farbblindheitsmodus
\tHandlingSettings.set_colorblind(true)
\tmenu._toggle_options(true)
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/04.png")
\tHandlingSettings.set_colorblind(false)
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Marathon mit Farbblind-Symbolen und gestapelten Steinen
\tHandlingSettings.set_colorblind(true)
\tSaveService.set_value("session", "selected_mode", "marathon")
\tvar g1 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg1.autoplay = true
\tadd_child(g1)
\tawait _wait_frames(140)
\tawait _snap("{OUT_DIR}/02.png")
\tg1.queue_free()
\tHandlingSettings.set_colorblind(false)
\tawait _wait_frames(3)

\t# 3. CPU-Duell
\tSaveService.set_value("session", "selected_mode", "duel")
\tvar g2 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg2.autoplay = true
\tadd_child(g2)
\tawait _wait_frames(140)
\tawait _snap("{OUT_DIR}/03.png")
\tg2.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "lane_defenders": {
        "files": [
            "01-main-menu.webp",
            "02-meadow-battle.webp",
            "03-magma-world.webp",
            "04-level-select.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(14)
\tawait _snap("{OUT_DIR}/01.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 4. Welt-/Levelauswahl (alle Welten kurz für Übersicht sichtbar markieren)
\tfor w in range(1, 5):
\t\tfor i in range(1, 6):
\t\t\tSaveService.set_value("lane_defenders", "unlocked_%d-%d" % [w, i], true)
\tvar lsel := (load("res://scenes/level_select.tscn") as PackedScene).instantiate()
\tadd_child(lsel)
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/04.png")
\tlsel.queue_free()
\tawait _wait_frames(3)

\t# 2. Grüne Wiese Kampf (Level 1-2)
\tSaveService.set_value("session", "selected_level", "1-2")
\tvar g1 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg1.autoplay = true
\tadd_child(g1)
\tawait _wait_frames(180)
\tawait _snap("{OUT_DIR}/02.png")
\tg1.queue_free()
\tawait _wait_frames(3)

\t# 3. Magma-Ödland (Level 4-2)
\tSaveService.set_value("session", "selected_level", "4-2")
\tvar g2 := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg2.autoplay = true
\tadd_child(g2)
\tawait _wait_frames(180)
\tawait _snap("{OUT_DIR}/03.png")
\tg2.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "crypt_dash": {
        "files": [
            "01-main-menu.webp",
            "02-dungeon-combat.webp",
            "03-soul-altar.webp",
            "04-almanac-relics.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)
\tSaveService.set_value("crypt_dash", "souls", 45)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(14)
\tawait _snap("{OUT_DIR}/01.png")

\t# 3. Seelen-Altar & Startwaffen-Auswahl
\tmenu._open_upgrades()
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/03.png")
\tmenu._close_upgrades()

\t# 4. Almanach / Bestiarium & Relikte
\tmenu._almanac_overlay.open()
\tawait _wait_frames(10)
\tawait _snap("{OUT_DIR}/04.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Dungeon-Kampf
\tvar g := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tg.autoplay = true
\tadd_child(g)
\t# Wechsle in einen benachbarten Kampfraum, falls Startraum friedlich ist
\tvar start_coords: Vector2i = g.current_room_coords
\tfor d: String in ["north", "east", "south", "west"]:
\t\tg._room_transition_cooldown = 0.0
\t\tg._on_door_entered(d)
\t\tif g.current_room_coords != start_coords:
\t\t\tbreak
\tawait _wait_frames(85)
\tawait _snap("{OUT_DIR}/02.png")
\tg.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
    "lumaria": {
        "files": [
            "01-main-menu.webp",
            "02-oakhaven-village.webp",
            "03-npc-dialogue.webp",
            "04-shrine-dungeon.webp",
        ],
        "script": """extends Node

func _wait_frames(count: int) -> void:
\tfor _i in range(count):
\t\tawait get_tree().process_frame

func _snap(path: String) -> void:
\tawait RenderingServer.frame_post_draw
\tvar img := get_viewport().get_texture().get_image()
\timg.save_png(path)

func _ready() -> void:
\tSaveService.set_test_mode(true)
\tSaveSlotManager.reset_runtime()
\tLocaleService.set_language("de", false)
\tAudioServer.set_bus_mute(0, true)

\t# 1. Hauptmenü
\tvar menu := (load("res://scenes/main_menu.tscn") as PackedScene).instantiate()
\tadd_child(menu)
\tawait _wait_frames(14)
\tawait _snap("{OUT_DIR}/01.png")
\tmenu.queue_free()
\tawait _wait_frames(3)

\t# 2. Dorf Oakhaven (Oberwelt)
\tvar g := (load("res://scenes/game.tscn") as PackedScene).instantiate()
\tadd_child(g)
\tawait _wait_frames(35)
\tawait _snap("{OUT_DIR}/02.png")

\t# 3. Illustrierter NPC-Porträtdialog (Lyra)
\tg.dialogue_box.start_dialogue("lyra")
\tawait _wait_frames(45)
\tawait _snap("{OUT_DIR}/03.png")
\tg.queue_free()
\tawait _wait_frames(3)

\t# 4. Wurzel-Schrein (Dungeon 1)
\tSaveSlotManager.reset_runtime()
\tvar shrine := (load("res://scenes/world/shrine_roots.tscn") as PackedScene).instantiate()
\tadd_child(shrine)
\tawait _wait_frames(40)
\tawait _snap("{OUT_DIR}/04.png")
\tshrine.queue_free()
\tawait _wait_frames(2)
\tget_tree().quit(0)
""",
    },
}

TSCN_TEMPLATE = """[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/_tmp_capture.gd" id="1"]

[node name="CaptureRunner" type="Node"]
script = ExtResource("1")
"""


def save_webp(src_path: Path, dst_path: Path) -> None:
    dst_path.parent.mkdir(parents=True, exist_ok=True)
    with Image.open(src_path) as im:
        rgb = im.convert("RGB")
        if rgb.size != TARGET_SIZE:
            rgb = rgb.resize(TARGET_SIZE, Image.Resampling.LANCZOS)
        stat = ImageStat.Stat(rgb)
        if max(stat.stddev) < 2.0:
            raise RuntimeError(f"Bild wirkt einfarbig/leer ({src_path}): stddev={stat.stddev}")
        rgb.save(dst_path, format="WEBP", quality=WEBP_QUALITY, method=6)


def capture_game(game: str) -> None:
    game_dir = ROOT / game
    media_dir = game_dir / "store-media"
    media_dir.mkdir(parents=True, exist_ok=True)

    # 1. Cover aus splash.png erzeugen
    splash_src = game_dir / SPLASH_SOURCES[game]
    if not splash_src.is_file():
        raise RuntimeError(f"Splash-Logo fehlt: {splash_src}")
    cover_dst = media_dir / "cover.webp"
    save_webp(splash_src, cover_dst)
    print(f"[{game}] Cover erzeugt: {cover_dst.relative_to(ROOT)} ({cover_dst.stat().st_size} Bytes)")

    # 2. 4 Gameplay-Screenshots via xvfb-run + Godot aufnehmen
    cfg = CAPTURES[game]
    tmp_gd = game_dir / "tests" / "_tmp_capture.gd"
    tmp_tscn = game_dir / "tests" / "_tmp_capture.tscn"
    with tempfile.TemporaryDirectory(prefix=f"shots_{game}_") as tmp_dir_str:
        tmp_dir = Path(tmp_dir_str)
        try:
            tmp_gd.write_text(cfg["script"].replace("{OUT_DIR}", str(tmp_dir)), encoding="utf-8")
            tmp_tscn.write_text(TSCN_TEMPLATE, encoding="utf-8")

            cmd = [
                "xvfb-run",
                "-a",
                "-s",
                "-screen 0 1280x720x24",
                "godot",
                "--path",
                str(game_dir),
                "--rendering-driver",
                "opengl3",
                "--display-driver",
                "x11",
                "--resolution",
                "1280x720",
                "res://tests/_tmp_capture.tscn",
            ]
            res = subprocess.run(cmd, capture_output=True, text=True, timeout=90)
            if res.returncode != 0:
                print(res.stdout)
                print(res.stderr, file=sys.stderr)
                raise RuntimeError(f"Godot-Screenshot-Lauf fehlgeschlagen für {game} (Exit {res.returncode})")

            for idx, filename in enumerate(cfg["files"], 1):
                raw_png = tmp_dir / f"0{idx}.png"
                if not raw_png.is_file():
                    print(res.stdout)
                    print(res.stderr, file=sys.stderr)
                    raise RuntimeError(f"Erwarteter Screenshot fehlt: {raw_png}")
                dst_webp = media_dir / filename
                save_webp(raw_png, dst_webp)
                print(f"[{game}] Screenshot {idx}: {dst_webp.relative_to(ROOT)} ({dst_webp.stat().st_size} Bytes)")
        finally:
            tmp_gd.unlink(missing_ok=True)
            tmp_tscn.unlink(missing_ok=True)
            Path(str(tmp_gd) + ".uid").unlink(missing_ok=True)


def main() -> int:
    selected = sys.argv[1:] if len(sys.argv) > 1 else list(CAPTURES.keys())
    for game in selected:
        capture_game(game)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
