#!/bin/sh
set -e
[ -f .env ] || { cp .env.example .env; echo Created .env - fill in API key; exit 1; }
IMAGE="${REVIEW_IMAGE:-aliocr-dckr:latest}"
if [ "${PULL_IMAGE:-0}" = 1 ]; then docker pull "$IMAGE"; else docker build -t "$IMAGE" .; fi
if [ $# -eq 0 ]; then
  set -- review --format json --audience agent --output /repo/review.json
fi
docker run --rm --env-file .env -v ./:/repo -w /repo "$IMAGE" "$@"
