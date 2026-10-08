#!/usr/bin/env bash
# tools/release_game.sh
# Erstellt vollautomatisch ein neues Release für ein Spiel:
# 1. Ermittelt oder erhöht die Semantic Version (patch / minor / major)
# 2. Führt Tests aus
# 3. Baut das Spiel für Linux, Windows und Web
# 4. Packt die Release-ZIP-Archive
# 5. Erstellt das GitHub-Release via `gh release create`
# 6. Aktualisiert den Floating-Tag/Release `<spiel>-latest`
# 7. Passt README.md und tools/build_web_portal.sh an und pusht die Änderungen
#
# Aufruf:
#   tools/release_game.sh <spiel> [patch|minor|major|<version>]
# Beispiele:
#   tools/release_game.sh lane_defenders minor
#   tools/release_game.sh vier_gewinnt v1.1.0
#   tools/release_game.sh block_stack          # auto-detect (feat -> minor, sonst patch)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

GAME="${1:?Aufruf: tools/release_game.sh <spiel> [patch|minor|major|<version>]}"
BUMP_ARG="${2:-auto}"

if [ ! -d "$ROOT/$GAME" ] || [ ! -f "$ROOT/$GAME/project.godot" ]; then
	echo "FEHLER: Spielordner '$GAME' mit project.godot nicht gefunden!" >&2
	exit 1
fi

# Display-Name ermitteln
case "$GAME" in
	"block_stack")   DISPLAY_NAME="Block Stack" ;;
	"lane_defenders") DISPLAY_NAME="Lane Defenders" ;;
	"vier_gewinnt")  DISPLAY_NAME="Connect Four Deluxe" ;;
	"neon_breakout") DISPLAY_NAME="Neon Breakout" ;;
	*)               DISPLAY_NAME="$GAME" ;;
esac

echo "=========================================================="
echo "🚀 Starte Release-Prozess für: $DISPLAY_NAME ($GAME)"
echo "=========================================================="

# Letzten Release-Tag ermitteln
LAST_TAG="$(git tag -l "${GAME}-v*" | sort -V | tail -n 1 || true)"
if [ -z "$LAST_TAG" ]; then
	LAST_VER="v1.0.0"
	echo "Kein vorheriger Tag gefunden. Basis: $LAST_VER"
else
	LAST_VER="${LAST_TAG#${GAME}-}"
	echo "Letzter Tag: $LAST_TAG (Version: $LAST_VER)"
fi

# Berechne neue Version
RAW_VER="${LAST_VER#v}"
IFS='.' read -r MAJOR MINOR PATCH <<< "$RAW_VER"
MAJOR="${MAJOR:-1}"
MINOR="${MINOR:-0}"
PATCH="${PATCH:-0}"

if [[ "$BUMP_ARG" =~ ^v?[0-9]+\.[0-9]+\.[0-9]+ ]]; then
	if [[ "$BUMP_ARG" == v* ]]; then
		NEW_VERSION="$BUMP_ARG"
	else
		NEW_VERSION="v$BUMP_ARG"
	fi
elif [ "$BUMP_ARG" = "major" ]; then
	NEW_VERSION="v$((MAJOR + 1)).0.0"
elif [ "$BUMP_ARG" = "minor" ]; then
	NEW_VERSION="v${MAJOR}.$((MINOR + 1)).0"
elif [ "$BUMP_ARG" = "patch" ]; then
	NEW_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
elif [ "$BUMP_ARG" = "auto" ]; then
	# Prüfe Commits seit dem letzten Tag für dieses Spiel
	COMMITS=""
	if [ -n "$LAST_TAG" ]; then
		COMMITS="$(git log "${LAST_TAG}..HEAD" --oneline -- "$GAME" 2>/dev/null || true)"
	fi
	if echo "$COMMITS" | grep -qE "feat(\(|$|:)"; then
		NEW_VERSION="v${MAJOR}.$((MINOR + 1)).0"
		echo "Erkenne neue Features -> Minor-Bump zu $NEW_VERSION"
	else
		NEW_VERSION="v${MAJOR}.${MINOR}.$((PATCH + 1))"
		echo "Erkenne Bugfixes/Wartung -> Patch-Bump zu $NEW_VERSION"
	fi
else
	echo "FEHLER: Unbekanntes Version-Argument '$BUMP_ARG'. Erlaubt: auto, patch, minor, major oder z. B. v1.1.0" >&2
	exit 1
fi

TAG_NAME="${GAME}-${NEW_VERSION}"
echo "🎯 Ziel-Version: $NEW_VERSION (Tag: $TAG_NAME)"

# 1. Tests ausführen
echo ""
echo "--- 1. Tests ausführen ---"
"$ROOT/tools/run_tests.sh"

# 2. Spiel bauen
echo ""
echo "--- 2. Spiel exportieren (Linux, Windows, Web) ---"
"$ROOT/tools/build_all.sh" "$GAME"

# 3. Release-Pakete packen
echo ""
echo "--- 3. Release-ZIPs erstellen ---"
"$ROOT/tools/package_release.sh" "$GAME" "$NEW_VERSION"

# 4. Release Notes zusammenstellen
COMMITS_LOG=""
if [ -n "$LAST_TAG" ]; then
	COMMITS_LOG="$(git log "${LAST_TAG}..HEAD" --pretty=format:"• %s" -- "$GAME" 2>/dev/null || true)"
fi
if [ -z "$COMMITS_LOG" ]; then
	COMMITS_LOG="• Wartung und Performance-Verbesserungen"
fi

NOTES="### $DISPLAY_NAME $NEW_VERSION

#### Änderungen & Neuerungen:
$COMMITS_LOG

#### Unterstützte Plattformen:
• **Linux:** \`${GAME}-${NEW_VERSION}-linux-x86_64.zip\`
• **Windows:** \`${GAME}-${NEW_VERSION}-windows-x86_64.zip\`
• **Web (HTML5):** \`${GAME}-${NEW_VERSION}-web.zip\` (auch direkt im Browser spielbar)"

# 5. GitHub Release erstellen
echo ""
echo "--- 4. GitHub Release $TAG_NAME erstellen ---"
gh release create "$TAG_NAME" \
	--title "[$DISPLAY_NAME] $NEW_VERSION" \
	--notes "$NOTES" \
	"$ROOT/build/packages/$GAME"/*

# 6. Floating Tag & Release aktualisieren
echo ""
echo "--- 5. Floating Tag ${GAME}-latest aktualisieren ---"
git tag -f "${GAME}-latest" HEAD
git push -f origin "${GAME}-latest"

LATEST_RELEASE_TITLE="[$DISPLAY_NAME] Latest Release"
LATEST_NOTES="Neueste Version von **$DISPLAY_NAME**. Details siehe [$NEW_VERSION](https://github.com/ChobitsChii/games/releases/tag/${TAG_NAME})."

# Falls bereits ein Release mit dem Tag existiert, löschen wir es vor Neuerstellung
gh release delete "${GAME}-latest" -y 2>/dev/null || true
gh release create "${GAME}-latest" \
	--title "$LATEST_RELEASE_TITLE" \
	--notes "$LATEST_NOTES" \
	"$ROOT/build/packages/$GAME"/*

# 7. README.md und Portal aktualisieren
echo ""
echo "--- 6. README.md und Web-Portal aktualisieren ---"
# Ersetze die Version in der README-Tabelle
# Suchmuster für Zeile mit [Display Name](...) | `vX.Y.Z`
sed -i -E "s/(\[$DISPLAY_NAME\]\($GAME\/README\.md\)[[:space:]]*\|[[:space:]]*)(\`v[0-9]+\.[0-9]+\.[0-9]+\`)/\1\`$NEW_VERSION\`/" "$ROOT/README.md"

# Ersetze die Version im Portal-Generator
sed -i -E "/<h2>$DISPLAY_NAME<\/h2>/!b;n;n;s/<span class=\"tag tag-ver\">v[0-9]+\.[0-9]+\.[0-9]+<\/span>/<span class=\"tag tag-ver\">$NEW_VERSION<\/span>/" "$ROOT/tools/build_web_portal.sh"

# Portal lokal neu generieren
"$ROOT/tools/build_web_portal.sh"

# Prüfen, ob README oder tools modifiziert wurden, dann committen und pushen
if ! git diff --quiet README.md tools/build_web_portal.sh; then
	git add README.md tools/build_web_portal.sh
	git commit -m "chore($GAME): bump version to $NEW_VERSION in README and portal"
	git push origin main
	echo "README.md und Web-Portal committet und gepusht."
fi

# Deploy-Pages Workflow anstoßen falls nötig
gh workflow run deploy-pages.yml 2>/dev/null || true

echo ""
echo "=========================================================="
echo "🎉 Release $TAG_NAME erfolgreich abgeschlossen!"
echo "🌐 Release-Link: https://github.com/ChobitsChii/games/releases/tag/$TAG_NAME"
echo "🌐 Latest-Link:  https://github.com/ChobitsChii/games/releases/tag/${GAME}-latest"
echo "=========================================================="
