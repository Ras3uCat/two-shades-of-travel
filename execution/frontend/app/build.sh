#!/usr/bin/env bash
# build.sh — Build the Flutter web app using client.json for configuration.
# Usage: ./build.sh
# Requires: client.json in the same directory as this script.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLIENT_JSON="$SCRIPT_DIR/client.json"

if [[ ! -f "$CLIENT_JSON" ]]; then
  echo "❌ client.json not found."
  echo "   Copy client.json.example → client.json and fill in all values."
  exit 1
fi

echo "🔨 Building Flutter web app..."
echo "   Config: $CLIENT_JSON"
echo ""

flutter pub get

flutter build web \
  --dart-define-from-file="$CLIENT_JSON" \
  --web-renderer html \
  --release

echo ""
echo "✅ Build complete. Output: build/web/"
