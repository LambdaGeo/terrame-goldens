#!/usr/bin/env bash
# Generate the raw goldens with a TerraME 2.0.1 installed on this machine.
# Needs: TME_PATH (TerraME's bin folder, with the packages of packages.lock
# installed in $TME_PATH/packages) and xvfb-run.
#
#   scripts/run_local.sh [OUT] [SEEDS] [JOBS]      (defaults: build 50 2)
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$(mkdir -p "${1:-$ROOT/build}" && cd "${1:-$ROOT/build}" && pwd)"
SEEDS="${2:-50}"
JOBS="${3:-2}"
export GOLDEN_LUA="$ROOT/lua" GOLDEN_OUT="$OUT"
mkdir -p "$OUT/ca/grids" "$OUT/ca/ensembles" "$OUT/sysdyn"
xvfb-run -a terrame -version 2>/dev/null | head -2
echo "ca: grids"
xvfb-run -a terrame "$GOLDEN_LUA/ca_grids.lua"
echo "ca: ensembles ($SEEDS seeds, $JOBS jobs)"
"$ROOT/scripts/run_ensembles_local.sh" "$SEEDS" "$JOBS"
echo "sysdyn ($SEEDS seeds for RandomWalk)"
GOLDEN_SEEDS="$SEEDS" xvfb-run -a terrame "$GOLDEN_LUA/sysdyn.lua"
