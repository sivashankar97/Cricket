#!/usr/bin/env bash
# Runs ON the VPS (cron, daily 18:45 UTC, after the omijaffna DB backup).
# Archives the server's configuration (both sites' compose / nginx / .env,
# certificates, firewall rules, crontab, rclone config), encrypts it with the
# same passphrase file as the omijaffna DB backup and uploads it to Google
# Drive. Archives older than KEEP_DAYS are deleted from Drive.
#
# Installed at /root/vps-config-backup/backup.sh (copy of khelo/scripts/vps-config-backup.sh).
# The passphrase file itself is NOT in the archive: keep a copy of it in a
# password manager, or the backups can't be decrypted.
# Restore: gpg -d vps-config-DATE.tar.gz.gpg | tar -xzf - -C /tmp/restore
set -euo pipefail

REMOTE="${CONFIG_BACKUP_REMOTE:-gdrive:VPS config backups}"
KEEP_DAYS="${CONFIG_BACKUP_KEEP_DAYS:-30}"
PASS_FILE="${BACKUP_PASSPHRASE_FILE:-/root/.omi-backup-passphrase}"

PATHS=(
  /root/omi-jaffna-cms/deploy/vps
  /root/omi-jaffna-cms/scripts
  /root/sportstamil/docker-compose.yml
  /root/sportstamil/nginx.conf
  /root/vps-config-backup
  /etc/letsencrypt
  /etc/ufw/user.rules
  /etc/ufw/user6.rules
  /root/.config/rclone/rclone.conf
)

if [[ ! -s "$PASS_FILE" ]]; then
  echo "$(date -u +%FT%TZ) config backup FAILED: passphrase file $PASS_FILE missing or empty" >&2
  exit 1
fi

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT
name="vps-config-$(TZ=Asia/Colombo date +%F)"
crontab -l > "$tmp/crontab.txt" 2>/dev/null || true

existing=()
for p in "${PATHS[@]}"; do [[ -e "$p" ]] && existing+=("$p"); done
tar -czf "$tmp/$name.tar.gz" -C / "${existing[@]#/}" -C "$tmp" crontab.txt 2>/dev/null
gzip -t "$tmp/$name.tar.gz"

gpg --batch --yes --quiet --pinentry-mode loopback --passphrase-file "$PASS_FILE" \
  --symmetric --cipher-algo AES256 --output "$tmp/$name.tar.gz.gpg" "$tmp/$name.tar.gz"
gpg --batch --quiet --pinentry-mode loopback --passphrase-file "$PASS_FILE" \
  --decrypt "$tmp/$name.tar.gz.gpg" | tar -tzf - >/dev/null

rclone copy "$tmp/$name.tar.gz.gpg" "$REMOTE"
rclone delete "$REMOTE" --min-age "${KEEP_DAYS}d" --include 'vps-config-*.tar.gz.gpg'
echo "$(date -u +%FT%TZ) config backup ok: $name.tar.gz.gpg $(du -h "$tmp/$name.tar.gz.gpg" | cut -f1) (encrypted)"
