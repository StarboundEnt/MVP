#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <health-endpoint-url>" >&2
  exit 1
fi

HEALTH_URL="$1"

echo "Checking $HEALTH_URL"

response=$(curl -sf "$HEALTH_URL") || {
  echo "Health check failed" >&2
  exit 2
}

echo "Health response:" >&2
echo "$response" | jq '.status, .vocabulary.version, .question_mapping.version'
