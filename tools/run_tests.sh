#!/usr/bin/env bash
# Führt die Tests aller Spiele aus (Logik-Tests + Smoke-Test). Rückgabecode 1 bei Fehlern.
set -uo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SMOKE_SEED="${SMOKE_SEED:-42}"
status=0

"$ROOT/tools/sync_shared.sh" >/dev/null

for project in "$ROOT"/*/project.godot; do
	[ -e "$project" ] || continue
	dir="$(dirname "$project")"
	echo "== $(basename "$dir") =="
	godot --headless --path "$dir" --import >/dev/null 2>&1 || true
	timeout 60 godot --headless --path "$dir" -s res://tests/run_tests.gd || status=1
	timeout 60 godot --headless --fixed-fps 480 --path "$dir" res://tests/smoke.tscn -- --seed="$SMOKE_SEED" || status=1
done
exit $status
