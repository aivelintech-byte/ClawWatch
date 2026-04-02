#!/bin/bash
set -e
cd ~/projects/ClawWatch

echo "🦀 Pulling latest ClawWatch…"
git pull

echo "🔨 Building…"
bash scripts/build-app.sh

echo "♻️  Restarting…"
pkill ClawWatch 2>/dev/null || true
sleep 0.5
open ~/projects/ClawWatch/ClawWatch.app

echo "✓ ClawWatch updated and running!"
