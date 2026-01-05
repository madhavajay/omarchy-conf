# Touch Bar Setup for T2 MacBooks

This guide covers setting up the Touch Bar on T2 MacBooks running Arch Linux with Hyprland.

## Overview

T2 MacBooks have a Touch Bar that can display either F-keys or media controls (brightness, volume, playback). On Linux, this is handled by `tiny-dfr` (Dynamic Function Row daemon).

**The Problem:** By default, the Touch Bar shows F1-F12 keys and the brightness controls adjust the wrong device (Touch Bar backlight instead of the screen).

**The Solution:** Configure tiny-dfr for media keys by default, and use a custom brightness script that targets the correct backlight device.

## Prerequisites

The following packages should already be installed on a T2 Arch Linux setup:

- `tiny-dfr` - Touch Bar daemon
- `brightnessctl` - Brightness control utility
- `libnotify` - For OSD notifications

```bash
# Check if installed
pacman -Qs tiny-dfr brightnessctl libnotify
```

## Quick Setup

Run the automated script:

```bash
~/om/touchbar.sh
```

This will configure everything. Read on for manual setup or troubleshooting.

## Manual Setup

### 1. Configure tiny-dfr for Media Keys

By default, tiny-dfr shows F-keys and requires holding Fn for media controls. To swap this:

```bash
# Create config directory
sudo mkdir -p /etc/tiny-dfr

# Copy default config
sudo cp /usr/share/tiny-dfr/config.toml /etc/tiny-dfr/config.toml

# Edit to enable media keys by default
sudo sed -i 's/MediaLayerDefault = false/MediaLayerDefault = true/' /etc/tiny-dfr/config.toml

# Restart the service
sudo systemctl restart tiny-dfr
```

Now the Touch Bar shows brightness/volume/playback by default. Hold Fn to see F1-F12.

### 2. Fix Brightness Controls

T2 Macs have two backlight devices:

| Device | Description | Levels |
|--------|-------------|--------|
| `appletb_backlight` | Touch Bar backlight | 3 (0%, 50%, 100%) |
| `acpi_video0` | Screen backlight | 100 (0-100%) |

The default brightness handlers (swayosd, etc.) pick up `appletb_backlight` first, giving you only 3 brightness levels.

**Check your devices:**
```bash
brightnessctl -l | grep -A2 "class 'backlight'"
```

### 3. Install the Brightness Script

Create `~/.local/bin/t2-brightness`:

```bash
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
```

### 4. Configure Hyprland Bindings

Add to `~/.config/hypr/bindings.conf`:

```bash
# Fix brightness for T2 Mac (use correct device with OSD)
# First unbind the default swayosd brightness bindings
unbind = ,XF86MonBrightnessUp
unbind = ,XF86MonBrightnessDown
bindeld = ,XF86MonBrightnessUp, Brightness up, exec, ~/.local/bin/t2-brightness up
bindeld = ,XF86MonBrightnessDown, Brightness down, exec, ~/.local/bin/t2-brightness down
```

Reload Hyprland:
```bash
hyprctl reload
```

## How It Works

1. **tiny-dfr** renders the Touch Bar display and sends key events when you tap buttons
2. Tapping brightness icons sends `XF86MonBrightnessUp/Down` key events
3. **Hyprland** catches these keys and runs our `t2-brightness` script
4. **t2-brightness** uses `brightnessctl` with the correct device (`acpi_video0`)
5. **notify-send** displays an OSD with the actual brightness percentage

## Troubleshooting

### Touch Bar not showing anything

```bash
# Check if tiny-dfr is running
systemctl status tiny-dfr

# Check kernel messages
sudo dmesg | grep -i "appletb\|dfr"

# Restart the service
sudo systemctl restart tiny-dfr
```

### Fn key doesn't switch layers

Check fnmode setting:
```bash
cat /sys/module/hid_apple/parameters/fnmode
# Should be 1 or 2
```

### Brightness changes but wrong OSD shows

If you see two OSDs (one correct, one wrong), the default swayosd bindings are still active. Make sure you have the `unbind` lines before your brightness bindings:

```bash
unbind = ,XF86MonBrightnessUp
unbind = ,XF86MonBrightnessDown
```

### Test brightness manually

```bash
# Check current brightness
brightnessctl -d acpi_video0 info

# Set to 50%
brightnessctl -d acpi_video0 set 50%

# Increase by 10%
brightnessctl -d acpi_video0 set +10%
```

## File Locations

| File | Purpose |
|------|---------|
| `/etc/tiny-dfr/config.toml` | tiny-dfr configuration |
| `/usr/share/tiny-dfr/config.toml` | Default config (don't edit) |
| `~/.local/bin/t2-brightness` | Custom brightness script |
| `~/.config/hypr/bindings.conf` | Hyprland key bindings |

## References

- [tiny-dfr GitHub](https://github.com/WhatAmISupposedToPutHere/tiny-dfr)
- [T2 Linux Wiki](https://wiki.t2linux.org/)
- [Arch Wiki - MacBookPro](https://wiki.archlinux.org/title/MacBookPro)
