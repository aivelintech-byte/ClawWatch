#!/bin/bash
# Auto-updater — only rebuilds if the remote has new commits
set -e

REPO="$HOME/projects/ClawWatch"
LOG="$HOME/Library/Logs/clawwatch-update.log"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG"; }

cd "$REPO"
git fetch origin main --quiet

LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    log "Up to date ($LOCAL). No rebuild needed."
    exit 0
fi

log "Update available: $LOCAL → $REMOTE. Rebuilding…"
git pull origin main --quiet
bash "$REPO/scripts/build-app.sh" >> "$LOG" 2>&1
cp -r "$REPO/ClawWatch.app" /Applications/

pkill ClawWatch 2>/dev/null || true
sleep 0.5
open /Applications/ClawWatch.app

log "Update complete. Now at $(git rev-parse HEAD)."
