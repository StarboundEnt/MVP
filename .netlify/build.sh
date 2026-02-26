#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="${FLUTTER_VERSION:-3.24.0}"
FLUTTER_DIR="$HOME/flutter"

# Install Flutter if not cached
if [ ! -d "$FLUTTER_DIR/bin" ]; then
  echo "Installing Flutter $FLUTTER_VERSION..."
  git clone https://github.com/flutter/flutter.git \
    -b "$FLUTTER_VERSION" --depth 1 "$FLUTTER_DIR"
else
  echo "Flutter already cached at $FLUTTER_DIR"
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter precache --web
flutter pub get

# Generate .env from Netlify environment variables
printf 'OPENROUTER_API_KEY=%s\nOPENROUTER_MODEL=%s\nCOMPLEXITY_API_BASE_URL=%s\nCOMPLEXITY_API_INGEST_PATH=%s\nCOMPLEXITY_API_BATCH_PATH=%s\nCOMPLEXITY_API_PROFILE_PATH=%s\nCOMPLEXITY_API_TIMEOUT=%s\nCOMPLEXITY_API_KEY=%s\nCOMPLEXITY_API_USE_LOCAL_STORE=%s\n' \
  "${OPENROUTER_API_KEY:-}" \
  "${OPENROUTER_MODEL:-gemini-2.5-flash-lite}" \
  "${COMPLEXITY_API_BASE_URL:-}" \
  "${COMPLEXITY_API_INGEST_PATH:-/ingest}" \
  "${COMPLEXITY_API_BATCH_PATH:-/ingest/batch}" \
  "${COMPLEXITY_API_PROFILE_PATH:-/users/{id}/complexity-profile}" \
  "${COMPLEXITY_API_TIMEOUT:-10}" \
  "${COMPLEXITY_API_KEY:-${OPENROUTER_API_KEY:-}}" \
  "${COMPLEXITY_API_USE_LOCAL_STORE:-0}" > .env

echo ".env generated"

flutter build web --release
echo "Build complete"
