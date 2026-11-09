#!/usr/bin/env bash
# Builds the Flutter web app and publishes it to the Sports Tamil container
# on the VPS (stack in /root/sportstamil, served on port 8080).
#
# Usage: khelo/scripts/deploy_vps.sh [--skip-build]
# Needs the `omi-vps` host in ~/.ssh/config (or set VPS_HOST).
set -euo pipefail

VPS_HOST="${VPS_HOST:-omi-vps}"
REMOTE_DIR="/root/sportstamil"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"

export PATH="/Users/anu/flutter/bin:$PATH"

if [[ "${1:-}" != "--skip-build" ]]; then
  # Build-time keys (e.g. CRICKETDATA_API_KEY) live in the git-ignored
  # khelo/dart_defines.env; the build still works without it.
  DEFINES=()
  [[ -f "$APP_DIR/dart_defines.env" ]] && DEFINES=(--dart-define-from-file=dart_defines.env)
  (cd "$APP_DIR" && flutter build web --release "${DEFINES[@]}")
fi

rsync -az --delete "$APP_DIR/build/web/" "$VPS_HOST:$REMOTE_DIR/www/"
ssh "$VPS_HOST" "cd $REMOTE_DIR && docker compose up -d --remove-orphans >/dev/null && docker compose ps --format '{{.Name}} {{.Status}}'"
echo "Deployed to http://$(ssh -G "$VPS_HOST" | awk '/^hostname /{print $2}'):8080"
