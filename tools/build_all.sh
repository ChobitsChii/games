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
				"asteroid_drift") disp="Asteroid Drift" ;;
				"crypt_dash")    disp="Crypt Dash" ;;
				"lumaria")       disp="Lumaria: The Prismatic Odyssey" ;;
				*)               disp="$name" ;;
			esac
			# Version primär aus README.md lesen, Fallback auf Git-Tags
			ver="$(awk -F'|' -v g="$name/README.md" '$0 ~ g { gsub(/[ `]/, "", $3); print $3 }' "$ROOT/README.md" 2>/dev/null || true)"
			if [ -z "$ver" ]; then
				ver="$(git tag -l "${name}-v*" 2>/dev/null | sort -V | tail -n 1 | sed "s/^${name}-//" || true)"
			fi
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

	# Android-Release-Export (falls Preset "Android" in export_presets.cfg vorhanden ist)
	if [ -f "$dir/export_presets.cfg" ] && grep -q 'name="Android"' "$dir/export_presets.cfg"; then
		if ls "$HOME"/.local/share/godot/export_templates/*/android_release.apk >/dev/null 2>&1; then
			ks_dir="$HOME/.local/share/chii-arcade/signing/games/$name"
			ks_file="$ks_dir/${name}-release.p12"
			pw_file="$ks_dir/${name}-release.pass"
			fp_file="$ks_dir/${name}-release.sha256"
			if [ ! -f "$ks_file" ] || [ ! -f "$pw_file" ]; then
				"$ROOT/tools/setup_android_signing.sh"
			fi
			# Stelle sicher, dass <spiel>/.godot/export_credentials.cfg existiert
			if [ ! -f "$dir/.godot/export_credentials.cfg" ]; then
				"$ROOT/tools/setup_android_signing.sh"
			fi
			mkdir -p "$ROOT/build/$name/android"
			out_apk="$ROOT/build/$name/android/$name.apk"
			rm -f "$out_apk"
			echo "   Exportiere Android Release APK ($name)..."
			GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$ks_file" \
			GODOT_ANDROID_KEYSTORE_RELEASE_USER="$name" \
			GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(tr -d '\r\n' < "$pw_file")" \
				godot --headless --path "$dir" --export-release "Android" "$out_apk"

			# Verifiziere Signatur und Zertifikats-Fingerprint via apksigner (mit JDK 17)
			export JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk}"
			export PATH="${JAVA_HOME}/bin:${PATH}"
			apksigner_bin="/opt/android-sdk/build-tools/36.1.0/apksigner"
			[ -x "$apksigner_bin" ] || apksigner_bin="/opt/android-sdk/build-tools/36.0.0/apksigner"
			[ -x "$apksigner_bin" ] || apksigner_bin="$(command -v apksigner || true)"
			zipalign_bin="/opt/android-sdk/build-tools/36.1.0/zipalign"
			[ -x "$zipalign_bin" ] || zipalign_bin="/opt/android-sdk/build-tools/36.0.0/zipalign"
			if [ -n "$apksigner_bin" ] && [ -x "$apksigner_bin" ]; then
				if ! "$apksigner_bin" verify "$out_apk" >/dev/null 2>&1; then
					if [ -x "$zipalign_bin" ]; then
						aligned_tmp="${out_apk}.aligned"
						"$zipalign_bin" -P 16 -f 4 "$out_apk" "$aligned_tmp"
						mv "$aligned_tmp" "$out_apk"
					fi
					tr -d '\r\n' < "$pw_file" | "$apksigner_bin" sign \
						--ks "$ks_file" \
						--ks-key-alias "$name" \
						--ks-pass stdin \
						--out "$out_apk" "$out_apk"
				fi
				actual_pin="$("$apksigner_bin" verify --verbose --print-certs "$out_apk" \
					| sed -n 's/.*Signer #1 certificate SHA-256 digest: *//p' \
					| tr -d ':' | tr '[:upper:]' '[:lower:]' | head -n1)"
				expected_pin="$(tr -d '\r\n' < "$fp_file")"
				if [ "$actual_pin" != "$expected_pin" ]; then
					echo "FEHLER: APK-Signatur-Mismatch für $name (erwartet: $expected_pin, erhalten: $actual_pin)" >&2
					exit 1
				fi
				echo "   Android APK signiert & verifiziert (SHA-256 Cert: $actual_pin)"
			fi
		else
			echo "WARNUNG: Android-Export-Templates (android_release.apk) fehlen, Android-Build wird übersprungen."
		fi
	fi
done
