#!/bin/bash
# Build the Flutter web app for production.
# Usage: ./scripts/build_web_prod.sh https://your-backend.onrender.com
#
# This script temporarily patches .env with the production backend URL,
# runs `flutter build web`, then restores the original .env.

set -e

BACKEND_URL="${1:-}"
if [ -z "$BACKEND_URL" ]; then
  echo "Usage: $0 <backend-url>"
  echo "  e.g. $0 https://starbound-api.onrender.com"
  exit 1
fi

ENV_FILE=".env"
ENV_BACKUP=".env.dev.bak"

echo "→ Backing up $ENV_FILE..."
cp "$ENV_FILE" "$ENV_BACKUP"

echo "→ Patching $ENV_FILE with production backend URL: $BACKEND_URL"
# Replace the API base URL line
sed -i.tmp "s|^COMPLEXITY_API_BASE_URL=.*|COMPLEXITY_API_BASE_URL=$BACKEND_URL|" "$ENV_FILE"
# Disable local store for production
sed -i.tmp "s|^COMPLEXITY_API_USE_LOCAL_STORE=.*|COMPLEXITY_API_USE_LOCAL_STORE=0|" "$ENV_FILE"
rm -f "$ENV_FILE.tmp"

echo "→ Running flutter build web --release..."
flutter build web --release

echo "→ Restoring $ENV_FILE..."
mv "$ENV_BACKUP" "$ENV_FILE"

echo ""
echo "✓ Build complete. Upload the 'build/web/' folder to Netlify."
echo "  Quickest way: drag & drop at https://app.netlify.com/drop"
