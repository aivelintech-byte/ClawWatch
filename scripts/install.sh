#!/bin/bash
# ClawWatch install — run once after cloning on any Mac
set -e

REPO="$(cd "$(dirname "$0")/.." && pwd)"
AGENTS="$HOME/Library/LaunchAgents"

echo "🦀 Installing ClawWatch…"

# 1. Build
echo "  Building release binary…"
cd "$REPO"
bash "$REPO/scripts/build-app.sh"

# 2. Install app
echo "  Copying to /Applications/…"
cp -r "$REPO/ClawWatch.app" /Applications/

# 3. ~/bin symlink
echo "  Linking clawwatch-update to ~/bin/…"
mkdir -p "$HOME/bin"
ln -sf "$REPO/scripts/update.sh" "$HOME/bin/clawwatch-update"
ln -sf "$REPO/scripts/auto-update.sh" "$HOME/bin/clawwatch-auto-update"
chmod +x "$REPO/scripts/auto-update.sh" "$REPO/scripts/update.sh"

# 4. Auto-start LaunchAgent (login → open app)
echo "  Installing auto-start LaunchAgent…"
mkdir -p "$AGENTS"
cp "$REPO/launchd/com.local.clawwatch.plist" "$AGENTS/"
launchctl unload "$AGENTS/com.local.clawwatch.plist" 2>/dev/null || true
launchctl load "$AGENTS/com.local.clawwatch.plist"

# 5. Auto-update LaunchAgent (hourly, generated with real HOME path)
echo "  Installing auto-update LaunchAgent (hourly)…"
cat > "$AGENTS/com.local.clawwatch.autoupdate.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.local.clawwatch.autoupdate</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>$REPO/scripts/auto-update.sh</string>
    </array>
    <key>StartInterval</key>
    <integer>3600</integer>
    <key>RunAtLoad</key>
    <false/>
    <key>StandardOutPath</key>
    <string>$HOME/Library/Logs/clawwatch-update.log</string>
    <key>StandardErrorPath</key>
    <string>$HOME/Library/Logs/clawwatch-update.log</string>
</dict>
</plist>
PLIST
launchctl unload "$AGENTS/com.local.clawwatch.autoupdate.plist" 2>/dev/null || true
launchctl load "$AGENTS/com.local.clawwatch.autoupdate.plist"

# 6. Launch now
echo "  Launching ClawWatch…"
pkill ClawWatch 2>/dev/null || true
sleep 0.3
open /Applications/ClawWatch.app

echo ""
echo "✓ ClawWatch is running!"
echo "  Auto-starts at login    — com.local.clawwatch"
echo "  Auto-updates every hour — com.local.clawwatch.autoupdate"
echo "  Update log: ~/Library/Logs/clawwatch-update.log"
echo "  Manual update: clawwatch-update"
