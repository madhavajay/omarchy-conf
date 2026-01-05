#!/bin/bash
# Touch Bar configuration script for T2 Macs on Arch Linux
# Sets media keys (brightness, volume, etc.) as the default layer
# Also fixes brightness control to use the correct device with OSD

set -e

echo "Configuring Touch Bar..."

# Create config directory if it doesn't exist
sudo mkdir -p /etc/tiny-dfr

# Copy default config if not present
if [ ! -f /etc/tiny-dfr/config.toml ]; then
    sudo cp /usr/share/tiny-dfr/config.toml /etc/tiny-dfr/config.toml
    echo "Created /etc/tiny-dfr/config.toml"
fi

# Set media keys as default (brightness, volume, etc. visible without Fn)
sudo sed -i 's/MediaLayerDefault = false/MediaLayerDefault = true/' /etc/tiny-dfr/config.toml

# Restart the service
sudo systemctl restart tiny-dfr

echo "Touch Bar configured."

# Create brightness wrapper script with OSD support
echo "Installing brightness control script..."

mkdir -p ~/.local/bin

cat > ~/.local/bin/t2-brightness <<'EOF'
#!/bin/bash
# Brightness control for T2 Macs - uses correct device and shows OSD
DEVICE="acpi_video0"

case "$1" in
    up)
        brightnessctl -d "$DEVICE" set +10% > /dev/null
        ;;
    down)
        brightnessctl -d "$DEVICE" set 10%- > /dev/null
        ;;
    *)
        echo "Usage: t2-brightness up|down"
        exit 1
        ;;
esac

# Get current brightness percentage
CURRENT=$(brightnessctl -d "$DEVICE" -m | cut -d',' -f4 | tr -d '%')

# Build a simple bar visualization
BAR_LENGTH=10
FILLED=$((CURRENT / 10))
EMPTY=$((BAR_LENGTH - FILLED))
BAR=$(printf '█%.0s' $(seq 1 $FILLED 2>/dev/null) ; printf '░%.0s' $(seq 1 $EMPTY 2>/dev/null))

# Show notification
notify-send -h string:x-canonical-private-synchronous:brightness \
    -h int:value:$CURRENT \
    -t 1000 \
    "Brightness" "$BAR $CURRENT%"
EOF

chmod +x ~/.local/bin/t2-brightness

# Update Hyprland bindings (live + repo copy so apply.sh doesn't overwrite it)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIVE_BINDINGS_FILE="$HOME/.config/hypr/bindings.conf"
REPO_BINDINGS_FILE="$SCRIPT_DIR/configs/hypr/bindings.conf"

update_bindings() {
    local file="$1"
    if [[ ! -f "$file" ]]; then
        return
    fi
    # Remove old brightness fix if present
    sed -i '/# Fix brightness for T2 Mac/,+5d' "$file"
    # Add new brightness bindings
    if ! grep -q "t2-brightness" "$file"; then
        cat >> "$file" <<'EOF'

# Fix brightness for T2 Mac (use correct device with OSD)
# First unbind the default swayosd brightness bindings
unbind = ,XF86MonBrightnessUp
unbind = ,XF86MonBrightnessDown
bindeld = ,XF86MonBrightnessUp, Brightness up, exec, ~/.local/bin/t2-brightness up
bindeld = ,XF86MonBrightnessDown, Brightness down, exec, ~/.local/bin/t2-brightness down
EOF
    fi
}

update_bindings "$LIVE_BINDINGS_FILE"
update_bindings "$REPO_BINDINGS_FILE"
echo "Updated Hyprland bindings."

# Reload Hyprland
hyprctl reload

echo ""
echo "Done! Touch Bar and brightness controls configured."
echo "- Touch Bar shows media controls by default (Fn for F-keys)"
echo "- Brightness buttons now work with correct OSD"
