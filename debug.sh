#!/bin/bash
# Collect keyd diagnostics for troubleshooting copy/paste

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Omarchy Debug: keyd ==="
echo ""

echo "--- systemctl status keyd ---"
systemctl status keyd --no-pager -l || true
echo ""

echo "--- keyd config diff (repo vs /etc) ---"
if [[ -f "$SCRIPT_DIR/configs/keyd/default.conf" && -f /etc/keyd/default.conf ]]; then
    diff -u "$SCRIPT_DIR/configs/keyd/default.conf" /etc/keyd/default.conf || true
else
    echo "Missing repo or /etc keyd config for diff."
fi
echo ""

echo "--- journalctl (last 80 lines) ---"
sudo journalctl -u keyd -n 80 --no-pager || true
echo ""

echo "--- keyd monitor (press Cmd+C and Cmd+V once) ---"
echo "You have 6 seconds. Press Cmd+C and Cmd+V once each."
echo "----------------------------------------------"
if command -v timeout >/dev/null 2>&1; then
    sudo timeout 6s keyd monitor || true
else
    echo "timeout not found; press Ctrl+C to stop keyd monitor after testing."
    sudo keyd monitor || true
fi
echo ""

echo "--- keyd list-apps ---"
if command -v keyd >/dev/null 2>&1; then
    keyd list-apps 2>/dev/null || true
fi
echo ""

echo "--- keyd group membership ---"
id -nG "$USER" || true
echo ""

echo "--- keyd app config ---"
if [[ -f "$HOME/.config/keyd/app.conf" ]]; then
    cat "$HOME/.config/keyd/app.conf"
else
    echo "No app.conf at $HOME/.config/keyd/app.conf"
fi
echo ""

echo "--- keyd-application-mapper active window (focus Ghostty) ---"
if command -v keyd-application-mapper >/dev/null 2>&1; then
    echo "You have 6 seconds. Focus Ghostty."
    if command -v timeout >/dev/null 2>&1; then
        timeout 6s keyd-application-mapper -v || true
    else
        keyd-application-mapper -v || true
    fi
fi
echo ""

echo "=== Debug Complete ==="
