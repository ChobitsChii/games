#!/usr/bin/env bash
# tools/backup_to_nas.sh
# Sichert alle wichtigen Release- und Signierdaten dieses Repositories auf das NAS:
#   /media/nas.home/Development-Backups/games/
#
# Gesichert werden:
#   1. signing-keys/          – Alle 7 Android-Release-Keystores (.p12), Passwörter (.pass),
#                               SHA-256-Fingerprints (.sha256) und SIGNING_KEYS_MANIFEST.txt
#   2. snapshots/             – Zeitgestempeltes tar.gz-Archiv der Signierschlüssel
#   3. export-configs/        – project.godot, export_presets.cfg & export_credentials.cfg je Spiel
#   4. android-releases/      – Gebaute, signierte Android-Release-APKs (falls vorhanden)
#   5. BACKUP_INFO.txt & SHA256SUMS.txt
#
# Hinweis: Das Zielverzeichnis liegt auf einem per CIFS eingebundenen NAS (Rechte 0777 sind
# dort mountbedingt normal und werden bewusst nicht beanstandet oder per chmod geändert).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIGNING_SRC="${HOME}/.local/share/chii-arcade/signing/games"
NAS_DEST="${1:-/media/nas.home/Development-Backups/games}"
TIMESTAMP="$(date -u +%Y%m%dT%H%M%SZ)"

if [ ! -d "${SIGNING_SRC}" ]; then
	echo "Signierschlüssel noch nicht vorhanden – führe setup_android_signing.sh aus..."
	"${ROOT}/tools/setup_android_signing.sh"
fi

if [ ! -d "$(dirname "${NAS_DEST}")" ]; then
	echo "FEHLER: NAS-Verzeichnis $(dirname "${NAS_DEST}") ist nicht erreichbar / nicht gemountet." >&2
	exit 1
fi

mkdir -p "${NAS_DEST}/signing-keys" \
         "${NAS_DEST}/snapshots" \
         "${NAS_DEST}/export-configs" \
         "${NAS_DEST}/android-releases"

echo "== 1. Sichere Android-Release-Signierschlüssel nach ${NAS_DEST}/signing-keys/ =="
cp -rf "${SIGNING_SRC}/." "${NAS_DEST}/signing-keys/"

echo "== 2. Erstelle Snapshot-Archiv unter ${NAS_DEST}/snapshots/ =="
tar -czf "${NAS_DEST}/snapshots/games-signing-keys-${TIMESTAMP}.tar.gz" \
	-C "$(dirname "${SIGNING_SRC}")" "$(basename "${SIGNING_SRC}")"

echo "== 3. Sichere Godot-Export-Konfigurationen nach ${NAS_DEST}/export-configs/ =="
for project in "${ROOT}"/*/project.godot; do
	[ -e "${project}" ] || continue
	dir="$(dirname "${project}")"
	game="$(basename "${dir}")"
	mkdir -p "${NAS_DEST}/export-configs/${game}"
	cp -f "${dir}/project.godot" "${NAS_DEST}/export-configs/${game}/project.godot"
	if [ -f "${dir}/export_presets.cfg" ]; then
		cp -f "${dir}/export_presets.cfg" "${NAS_DEST}/export-configs/${game}/export_presets.cfg"
	fi
	if [ -f "${dir}/.godot/export_credentials.cfg" ]; then
		cp -f "${dir}/.godot/export_credentials.cfg" "${NAS_DEST}/export-configs/${game}/export_credentials.cfg"
	fi
done

echo "== 4. Sichere signierte Android-Release-APKs (falls gebaut) nach ${NAS_DEST}/android-releases/ =="
apk_count=0
for apk in "${ROOT}"/build/*/android/*.apk; do
	[ -e "${apk}" ] || continue
	cp -f "${apk}" "${NAS_DEST}/android-releases/$(basename "${apk}")"
	apk_count=$((apk_count + 1))
done
echo "   ${apk_count} APK(s) kopiert."

GIT_HEAD="$(git -C "${ROOT}" rev-parse --short HEAD 2>/dev/null || echo "unknown")"
cat > "${NAS_DEST}/BACKUP_INFO.txt" <<EOF
# Chii Arcade Games – NAS Backup Info
Backup-Zeitpunkt (UTC): ${TIMESTAMP}
Quell-Repository:       ${ROOT} (Git Commit: ${GIT_HEAD})
Quell-Keystores:        ${SIGNING_SRC}
Symlink (Godot):        ${HOME}/.local/share/godot/keystores/games
NAS-Zielverzeichnis:    ${NAS_DEST}

Enthaltene Ordner:
  - signing-keys/       Alle 7 per-Game Android Release Keystores (.p12 + .pass + .sha256)
  - snapshots/          Zeitgestempelte .tar.gz Voll-Backups der Signierschlüssel
  - export-configs/     project.godot, export_presets.cfg und export_credentials.cfg aller 7 Spiele
  - android-releases/   Signierte Release-APKs der Android-fähigen Spiele
EOF

(
	cd "${NAS_DEST}"
	find signing-keys export-configs android-releases -type f -exec sha256sum {} + | sort -k 2 > "${NAS_DEST}/SHA256SUMS.txt"
)

echo "== Backup erfolgreich abgeschlossen: ${NAS_DEST} =="
