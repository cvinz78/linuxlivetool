#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
IMAGE="${LLT_TEST_IMAGE:-linuxlivetool-functional-tests:local}"

command -v docker >/dev/null 2>&1 || {
    printf 'FEHLER: Docker wurde nicht gefunden.\n' >&2
    exit 1
}

docker build --tag "$IMAGE" --file "$ROOT/tests/Dockerfile" "$ROOT"
docker run --rm \
    --network none \
    --cap-drop ALL \
    --security-opt no-new-privileges \
    --pids-limit 256 \
    --memory 1g \
    --tmpfs /tmp:rw,nosuid,nodev,exec,size=512m \
    --volume "$ROOT:/src:ro" \
    --workdir /work \
    "$IMAGE" bash /src/tests/functional-in-container.sh
