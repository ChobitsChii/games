#!/usr/bin/env bash
# Packt ein Spiel als Release-ZIP-Dateien für Linux, Windows und Web.
# Aufruf: tools/package_release.sh <spiel> <version>
# Beispiel: tools/package_release.sh lane_defenders v1.0.0
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:?Aufruf: package_release.sh <spiel> <version>}"
VERSION="${2:?Aufruf: package_release.sh <spiel> <version>}"

OUT_DIR="$ROOT/build/packages/$NAME"
mkdir -p "$OUT_DIR"
rm -f "$OUT_DIR"/*

# Stelle sicher, dass die Builds existieren
if [ ! -f "$ROOT/build/$NAME/linux/$NAME.x86_64" ] || [ ! -f "$ROOT/build/$NAME/windows/$NAME.exe" ] || [ ! -f "$ROOT/build/$NAME/web/index.html" ]; then
	echo "Builds für $NAME fehlen, starte build_all.sh..."
	"$ROOT/tools/build_all.sh" "$NAME"
fi

# Linux ZIP
echo "Packe Linux..."
zip -j -9 "$OUT_DIR/${NAME}-${VERSION}-linux-x86_64.zip" "$ROOT/build/$NAME/linux/${NAME}.x86_64"

# Windows ZIP
echo "Packe Windows..."
zip -j -9 "$OUT_DIR/${NAME}-${VERSION}-windows-x86_64.zip" "$ROOT/build/$NAME/windows/${NAME}.exe"

# Web ZIP (inkl. coi-serviceworker)
echo "Packe Web..."
(
	cd "$ROOT/build/$NAME/web"
	zip -r -9 "$OUT_DIR/${NAME}-${VERSION}-web.zip" .
)

echo "Pakete erfolgreich erstellt in $OUT_DIR:"
ls -lh "$OUT_DIR"
