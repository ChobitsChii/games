#!/usr/bin/env bash
# Kopiert shared/ in jedes Spiel-Projekt nach <spiel>/addons/shared/.
# Godot-Projekte können nur Dateien unterhalb ihres eigenen Ordners per res:// laden.
# Von Godot erzeugte Dateien (.import, .translation, .uid) bleiben erhalten.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for project in "$ROOT"/*/project.godot; do
	[ -e "$project" ] || continue
	dir="$(dirname "$project")"
	echo "sync shared -> $(basename "$dir")/addons/shared"
	mkdir -p "$dir/addons/shared"
	rsync -a --delete \
		--exclude '*.import' --exclude '*.translation' --exclude '*.uid' \
		"$ROOT/shared/" "$dir/addons/shared/"
done
