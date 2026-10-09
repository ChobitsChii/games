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
		if [ -f "$ROOT/tools/web/game_topbar_template.html" ]; then
			case "$name" in
				"block_stack")   disp="Block Stack" ;;
				"lane_defenders") disp="Lane Defenders" ;;
				"vier_gewinnt")  disp="Connect Four Deluxe" ;;
				"neon_breakout") disp="Neon Breakout" ;;
				*)               disp="$name" ;;
			esac
			ver="$(git tag -l "${name}-v*" 2>/dev/null | sort -V | tail -n 1 | sed "s/^${name}-//" || true)"
			[ -n "$ver" ] || ver="v1.0.0"
			python3 -c "
import sys
html_path, template_path, game_name, game_ver = sys.argv[1:5]
with open(html_path, 'r', encoding='utf-8') as f:
    html = f.read()
if 'id=\"game-topbar\"' not in html:
    with open(template_path, 'r', encoding='utf-8') as f:
        tpl = f.read()
    tpl = tpl.replace('%%GAME_NAME%%', game_name).replace('%%GAME_VERSION%%', game_ver)
    html = html.replace('</body>', tpl + '\n</body>')
    with open(html_path, 'w', encoding='utf-8') as f:
        f.write(html)
" "$ROOT/build/$name/web/index.html" "$ROOT/tools/web/game_topbar_template.html" "$disp" "$ver"
		fi
	else
		echo "WARNUNG: Web-Export-Templates (web_release.zip) fehlen, Web-Build wird übersprungen."
	fi
done
