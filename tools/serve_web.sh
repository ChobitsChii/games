#!/usr/bin/env bash
# Startet einen lokalen Webserver für einen Web-Build.
# Aufruf: tools/serve_web.sh <spiel> [port]
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NAME="${1:?Aufruf: serve_web.sh <spiel> [port]}"
PORT="${2:-8080}"
echo "http://localhost:$PORT  (Strg+C zum Beenden)"
python3 -m http.server "$PORT" --directory "$ROOT/build/$NAME/web"
