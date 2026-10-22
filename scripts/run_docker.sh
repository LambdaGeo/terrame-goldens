#!/usr/bin/env bash
# Generate the raw goldens in the terrame-docker image. The packages of
# packages.lock are cloned on the host (scripts/fetch_packages.sh) and mounted
# into the image, so any image with TerraME 2.0.1 works.
#
#   scripts/run_docker.sh [IMAGE] [SEEDS] [JOBS]
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMAGE="${1:-profsergiocosta/terrame-luccme:0.4.2}"
SEEDS="${2:-50}"
JOBS="${3:-2}"
"$ROOT/scripts/fetch_packages.sh"
mounts=()
while read -r name _ _; do
  mounts+=(-v "$ROOT/.packages/$name:/opt/terrame/bin/packages/$name")
done < <(grep -v '^\s*#' "$ROOT/packages.lock" | grep -v '^\s*$')
mkdir -p "$ROOT/build"
docker run --rm --user "$(id -u):$(id -g)" \
  -v "$ROOT:/work" "${mounts[@]}" -w /work \
  "$IMAGE" bash -c "export HOME=/tmp/home XDG_RUNTIME_DIR=/tmp/xdg; mkdir -p \$HOME \$XDG_RUNTIME_DIR; chmod 700 \$XDG_RUNTIME_DIR; scripts/run_local.sh /work/build $SEEDS $JOBS"
docker image inspect --format '{{index .RepoDigests 0}}' "$IMAGE" > "$ROOT/build/docker_image.txt" || true
