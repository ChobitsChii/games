#!/usr/bin/env bash
# Exportiert alle Spiele für Linux, Windows und Web nach build/<spiel>/<plattform>/.
# Aufruf: tools/build_all.sh [spiel]   (ohne Argument: alle Spiele)
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ONLY="${1:-}"

"$ROOT/tools/sync_shared.sh"

for project in "$ROOT"/*/project.godot; do
	[ -e "$project" ] || continue
	dir="$(dirname "$project")"
	name="$(basename "$dir")"
	[ -z "$ONLY" ] || [ "$ONLY" = "$name" ] || continue

	echo "== Build $name =="
	godot --headless --path "$dir" --import >/dev/null 2>&1 || true
	mkdir -p "$ROOT/build/$name/linux" "$ROOT/build/$name/windows" "$ROOT/build/$name/web"
	godot --headless --path "$dir" --export-release "Linux"   "$ROOT/build/$name/linux/$name.x86_64"
	godot --headless --path "$dir" --export-release "Windows" "$ROOT/build/$name/windows/$name.exe"
	if ls "$HOME"/.local/share/godot/export_templates/*/web_release.zip >/dev/null 2>&1; then
		godot --headless --path "$dir" --export-release "Web" "$ROOT/build/$name/web/index.html"
		if [ -f "$ROOT/tools/web/coi-serviceworker.js" ]; then
			cp "$ROOT/tools/web/coi-serviceworker.js" "$ROOT/build/$name/web/"
			if ! grep -q "coi-serviceworker.js" "$ROOT/build/$name/web/index.html"; then
				sed -i 's|<head>|<head>\n\t\t<script src="coi-serviceworker.js"></script>|' "$ROOT/build/$name/web/index.html"
			fi
		fi
	else
		echo "WARNUNG: Web-Export-Templates (web_release.zip) fehlen, Web-Build wird übersprungen."
	fi
done
