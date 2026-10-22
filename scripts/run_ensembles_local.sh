#!/usr/bin/env bash
# Run the ca ensembles with a TerraME installed on this machine (no Docker),
# one TerraME process per (case, seed): TerraME does not free the cellular
# spaces of a finished model, so many seeds in one process run out of memory.
#
#   TME_PATH=/opt/terrame/bin GOLDEN_OUT=out scripts/run_ensembles_local.sh [SEEDS] [JOBS]
#
# The parts (<case>.<seed>-<seed>.csv) are joined by scripts/build_goldens.py.
set -euo pipefail
SEEDS="${1:-50}"
JOBS="${2:-2}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export GOLDEN_LUA="$ROOT/lua" GOLDEN_SEEDS="$SEEDS"
: "${GOLDEN_OUT:?set GOLDEN_OUT}"
export GOLDEN_OUT
mkdir -p "$GOLDEN_OUT/ca/ensembles"

CASES="growth snow solid_diffusion interspecific_competition fire"
for c in $CASES; do
  for s in $(seq 1 "$SEEDS"); do echo "$c $s"; done
done | xargs -P "$JOBS" -n 2 sh -c '
  GOLDEN_CASE=$0 GOLDEN_SEED_FIRST=$1 GOLDEN_SEED_LAST=$1 \
    xvfb-run -a terrame "$GOLDEN_LUA/ca_ensembles.lua" >/dev/null 2>&1 \
    || echo "failed: $0 seed $1" >&2'
