#!/usr/bin/env bash
# Run the logo ensembles with a TerraME installed on this machine, one TerraME
# process per (case, seed). The parts (<case>.<seed>-<seed>.csv) are joined by
# scripts/build_goldens.py.
#   TME_PATH=... GOLDEN_OUT=out scripts/run_logo_local.sh [SEEDS] [JOBS]
set -euo pipefail
SEEDS="${1:-50}"
JOBS="${2:-2}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GOLDEN_LUA="$ROOT/lua"
: "${GOLDEN_OUT:?set GOLDEN_OUT}"
export GOLDEN_OUT
mkdir -p "$GOLDEN_OUT/logo"
CASES="predator_prey ants schelling life_cycle disease"
for c in $CASES; do
  for s in $(seq 1 "$SEEDS"); do echo "$c $s"; done
done | xargs -P "$JOBS" -n 2 sh -c '
  GOLDEN_CASE=$0 GOLDEN_SEED_FIRST=$1 GOLDEN_SEED_LAST=$1 \
    xvfb-run -a terrame "$GOLDEN_LUA/logo.lua" >/dev/null 2>&1 \
    || echo "failed: $0 seed $1" >&2'
