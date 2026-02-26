#!/usr/bin/env bash
set -euo pipefail

# Runs the local checks required before building the backend image.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT_DIR"

echo "[1/3] Running backend unit tests"
python3 -m unittest backend.tests.test_vocabulary_registry \
  backend.tests.test_question_mapper \
  backend.tests.test_ingestion_service \
  backend.tests.test_http_graph_writer \
  backend.tests.test_feedback_repository \
  backend.tests.test_feedback_router \
  backend.tests.test_remote_profile_store \
  backend.tests.test_health

echo "[2/3] Showing git status"
git status -sb || true

echo "[3/3] Ready to build image. Set CONTAINER_REGISTRY and STARBOUND_IMAGE_TAG before running build script."
