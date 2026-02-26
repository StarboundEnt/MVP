#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${CONTAINER_REGISTRY:-}" || -z "${STARBOUND_IMAGE_TAG:-}" ]]; then
  echo "CONTAINER_REGISTRY and STARBOUND_IMAGE_TAG must be set" >&2
  exit 1
fi

IMAGE="$CONTAINER_REGISTRY/backend:$STARBOUND_IMAGE_TAG"

echo "Building backend image $IMAGE"
docker build -f ops/docker/backend.Dockerfile -t "$IMAGE" .

echo "Pushing $IMAGE"
docker push "$IMAGE"

echo "Done"
