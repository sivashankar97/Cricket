#!/usr/bin/env bash
# Deploys the WhatsApp login service (khelo/whatsapp_login) to the VPS as the
# `wa-login` container in the sportstamil compose project, and routes
# https://sportstamil.network/wa/* to it through the Sports Tamil nginx.
#
# Needs two git-ignored files on this Mac (their contents are never printed):
#   khelo/whatsapp_login/.env          (see .env.example)
#   khelo/secrets/firebase-admin.json  (Firebase → Project settings → Service accounts → Generate new private key)
#
# Usage: khelo/scripts/deploy_whatsapp_login.sh
set -euo pipefail

VPS_HOST="${VPS_HOST:-omi-vps}"
REMOTE_DIR="/root/sportstamil"
APP_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$APP_DIR/whatsapp_login/.env"
SA_FILE="$APP_DIR/secrets/firebase-admin.json"

for f in "$ENV_FILE" "$SA_FILE"; do
  [[ -s "$f" ]] || { echo "Missing $f"; exit 1; }
done
for key in WA_PHONE_NUMBER_ID WA_ACCESS_TOKEN WA_APP_SECRET WA_VERIFY_TOKEN; do
  grep -qE "^$key=.+" "$ENV_FILE" || { echo "$key is empty in $ENV_FILE"; exit 1; }
done

ssh "$VPS_HOST" "mkdir -p $REMOTE_DIR/whatsapp_login $REMOTE_DIR/secrets && chmod 700 $REMOTE_DIR/secrets"
rsync -az --delete --exclude node_modules --exclude test --exclude .env --exclude .env.example \
  "$APP_DIR/whatsapp_login/" "$VPS_HOST:$REMOTE_DIR/whatsapp_login/"
rsync -a --chmod=F600 "$ENV_FILE" "$VPS_HOST:$REMOTE_DIR/whatsapp_login/.env"
rsync -a --chmod=F644 "$SA_FILE" "$VPS_HOST:$REMOTE_DIR/secrets/firebase-admin.json"
rsync -a "$APP_DIR/scripts/vps/docker-compose.yml" "$APP_DIR/scripts/vps/nginx.conf" "$VPS_HOST:$REMOTE_DIR/"

ssh "$VPS_HOST" "cd $REMOTE_DIR && docker compose up -d --build --remove-orphans >/dev/null \
  && sleep 3 && docker compose exec -T web nginx -s reload \
  && docker compose ps --format '{{.Name}} {{.Status}}'"
curl -s -m 10 https://sportstamil.network/wa/health && echo
