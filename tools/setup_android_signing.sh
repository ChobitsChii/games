#!/usr/bin/env bash
# Erstellt (falls noch nicht vorhanden) für jedes der 7 Spiele im Repo einen eigenen
# Android-Release-Signierschlüssel (PKCS12, RSA 3072, 10000 Tage Laufzeit) unter:
#   ~/.local/share/chii-arcade/signing/games/<spiel>/<spiel>-release.p12
# sowie einen Symlink unter:
#   ~/.local/share/godot/keystores/games
# und hinterlegt die lokalen Godot-Export-Credentials in <spiel>/.godot/export_credentials.cfg (gitignored).
# Bestehende Schlüssel werden NIEMALS überschrieben.

set -euo pipefail
umask 077

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIGNING_BASE="${HOME}/.local/share/chii-arcade/signing/games"
GODOT_KEYSTORES_DIR="${HOME}/.local/share/godot/keystores"
JAVA_HOME="${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk}"
export PATH="${JAVA_HOME}/bin:${PATH}"

mkdir -p "${SIGNING_BASE}"
chmod 700 "${SIGNING_BASE}"

mkdir -p "${GODOT_KEYSTORES_DIR}"
if [ ! -e "${GODOT_KEYSTORES_DIR}/games" ]; then
	ln -s "${SIGNING_BASE}" "${GODOT_KEYSTORES_DIR}/games"
fi

GAMES=(
	"neon_breakout:Neon Breakout"
	"asteroid_drift:Asteroid Drift"
	"vier_gewinnt:Connect Four Deluxe"
	"block_stack:Block Stack"
	"lane_defenders:Lane Defenders"
	"crypt_dash:Crypt Dash"
	"lumaria:Lumaria The Prismatic Odyssey"
)

MANIFEST="${SIGNING_BASE}/SIGNING_KEYS_MANIFEST.txt"
cat > "${MANIFEST}" <<EOF
# Chii Arcade – Android Release Signing Keys Manifest (Repository: games)
# Generiert am: $(date -Iseconds)
# Lokaler Pfad: ${SIGNING_BASE}
# NAS-Backup:   /media/nas.home/Development-Backups/games/signing-keys/
#
# WICHTIG: Diese Datei und die .p12/.pass-Dateien niemals in Git committen!
================================================================================
EOF

for entry in "${GAMES[@]}"; do
	game="${entry%%:*}"
	title="${entry#*:}"
	pkg="de.chobitschii.${game}"
	game_dir="${SIGNING_BASE}/${game}"
	ks_file="${game_dir}/${game}-release.p12"
	pw_file="${game_dir}/${game}-release.pass"
	fp_file="${game_dir}/${game}-release.sha256"
	alias_name="${game}"

	mkdir -p "${game_dir}"
	chmod 700 "${game_dir}"

	if [ ! -f "${pw_file}" ]; then
		openssl rand -hex 20 > "${pw_file}"
		chmod 600 "${pw_file}"
	fi
	pw="$(tr -d '\r\n' < "${pw_file}")"

	if [ ! -f "${ks_file}" ]; then
		echo "== Erzeuge Android-Release-Keystore für ${title} (${game}) =="
		KS_PASS="${pw}" keytool -genkeypair \
			-storetype PKCS12 \
			-keystore "${ks_file}" \
			-alias "${alias_name}" \
			-storepass:env KS_PASS \
			-keypass:env KS_PASS \
			-keyalg RSA \
			-keysize 3072 \
			-validity 10000 \
			-dname "CN=${title}, OU=Chii Arcade, O=ChobitsChii, C=DE"
		chmod 600 "${ks_file}"
	else
		echo "== Vorhandener Keystore für ${title} (${game}) bleibt unverändert =="
	fi

	# SHA-256 Fingerprint auslesen
	cert_sha256="$(KS_PASS="${pw}" keytool -list -v -storetype PKCS12 -keystore "${ks_file}" -alias "${alias_name}" -storepass:env KS_PASS \
		| awk '/SHA256:/ { print $2; exit }')"
	cert_sha256_clean="$(echo "${cert_sha256}" | tr -d ':' | tr '[:upper:]' '[:lower:]')"
	printf '%s\n' "${cert_sha256_clean}" > "${fp_file}"
	chmod 600 "${fp_file}"

	cat >> "${MANIFEST}" <<EOF
Spiel:          ${title} (${game})
Package-ID:     ${pkg}
Keystore-Pfad:  ${ks_file}
Key-Alias:      ${alias_name}
Passwort-Datei: ${pw_file}
Passwort:       ${pw}
Cert SHA-256:   ${cert_sha256}
Cert Pin (hex): ${cert_sha256_clean}
--------------------------------------------------------------------------------
EOF

	# Lokale Godot export_credentials.cfg in <spiel>/.godot/ schreiben (wird von Git ignoriert)
	if [ -d "${ROOT}/${game}" ]; then
		mkdir -p "${ROOT}/${game}/.godot"
		cat > "${ROOT}/${game}/.godot/export_credentials.cfg" <<EOF
[preset.3.options]

keystore/debug=""
keystore/debug_user=""
keystore/debug_password=""
keystore/release="${ks_file}"
keystore/release_user="${alias_name}"
keystore/release_password="${pw}"
EOF
		chmod 600 "${ROOT}/${game}/.godot/export_credentials.cfg"
	fi
done

echo ""
echo "Alle 7 Android-Release-Keystores sind bereit unter: ${SIGNING_BASE}"
