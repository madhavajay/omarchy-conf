# Omarchy Setup

Personal configuration and customizations for Omarchy Linux (Arch-based, T2 MacBook).

## CURRENT STATUS / TODO (Resume Here)

**Last session:** 2026-01-03 - Working on fixing Mac-like copy/paste keyboard shortcuts

### Problem
`Cmd+C` (copy) and `Cmd+V` (paste) not working. The keyd config in `/etc/keyd/default.conf` has syntax errors.

### Root Cause
The OLD config in `/etc/keyd/default.conf` has these errors (from `systemctl status keyd`):
```
ERROR: line 24: shift is not a valid key
ERROR: line 25: shift is not a valid key
```

The lines `shift+left = S-home` and `shift+right = S-end` use invalid syntax for keyd.

### Solution
A FIXED config exists at `~/om/configs/keyd/default.conf` with proper syntax using `[cmd+shift]` and `[alt+shift]` layers instead of inline `shift+` syntax.

### To Fix It Now
```bash
# Apply the fixed config
sudo cp ~/om/configs/keyd/default.conf /etc/keyd/default.conf

# Restart keyd
sudo systemctl restart keyd

# Check for errors
systemctl status keyd
```

### If Still Not Working
Debug with:
```bash
# Watch what keyd sees when you press keys
sudo keyd monitor

# Check keyd logs
journalctl -u keyd -f
```

The config should map:
- Physical `Meta/Cmd` key → activates `cmd` layer
- In `cmd` layer: `c` → sends `Ctrl+C` (copy)
- In `cmd` layer: `v` → sends `Ctrl+V` (paste)

### What Was Changed in Fixed Config
1. Changed `capslock = leftmeta` → `capslock = layer(meta)` (fixes warning)
2. Added `[cmd+shift]` layer for Cmd+Shift combos (fixes syntax error)
3. Added `[alt]` and `[alt+shift]` layers for Option/word navigation
4. Added more Mac shortcuts: Cmd+N/O/P/R/L/K/D/G/B/I/U/Y and Cmd+1-9

---

## Overview

This repo contains scripts and documentation for reproducing my Omarchy setup on a fresh machine. The actual dotfiles are managed by **chezmoi** - this repo provides the automation to set everything up.

## Documentation

- [Firmware Setup](docs/firmware.md) - Wi-Fi and Bluetooth firmware for T2 MacBooks
- [Keyboard Configuration](docs/keyboard.md) - Full keybinding reference and keyd setup
- [Touch Bar Setup](docs/touchbar.md) - Touch Bar, brightness controls, and media keys

## What's Configured

### Firmware (T2 MacBook)
Wi-Fi and Bluetooth require proprietary Broadcom firmware extracted from macOS. See [docs/firmware.md](docs/firmware.md) for details. The `firmware.sh` script handles extraction.

### Keyboard (keyd)
Mac-like keyboard shortcuts system-wide:
- `Capslock` -> `Meta/Super` key
- `Meta/Cmd` + standard keys work like macOS (Cmd+C, Cmd+V, Cmd+S, etc.)
- `Meta + Left/Right` -> Home/End

### Touch Bar (tiny-dfr)
Configures the MacBook Touch Bar to work properly on Linux:
- Shows media controls (brightness, volume, play/pause) by default
- Press `Fn` to switch to F1-F12 keys
- Fixes brightness controls to use the correct display device (not Touch Bar backlight)
- Custom OSD showing accurate brightness percentage

```bash
# Run to configure Touch Bar
~/om/touchbar.sh
```

The script:
1. Configures `/etc/tiny-dfr/config.toml` for media keys by default
2. Installs `~/.local/bin/t2-brightness` wrapper script
3. Adds Hyprland bindings for correct brightness control with OSD

### Terminal (Ghostty)
- Font: JetBrains Mono Nerd Font (size 9)
- Mac-style keybindings (Super+C/V for copy/paste)
- Block cursor, no blink
- Custom window padding

### Window Manager (Hyprland)

#### Input Settings
- Natural scroll on touchpad
- Tap-to-click enabled
- Two-finger click for right-click
- Palm rejection (aggressive)
- Tap-to-click disabled
- Click-to-focus (no focus follows mouse)
- Keyboard repeat: 40 rate, 600ms delay

#### Key Bindings
| Shortcut | Action |
|----------|--------|
| `Super + Return` | Terminal |
| `Super + Shift + F` | File manager (Nautilus) |
| `Super + Shift + B` | Browser |
| `Super + Shift + N` | Editor |
| `Super + \`` | Cycle windows (like Cmd+Tab on Mac) |

#### Magnet-Style Window Snapping
| Shortcut | Position |
|----------|----------|
| `Ctrl + Alt + Left` | Left half |
| `Ctrl + Alt + Right` | Right half |
| `Ctrl + Alt + Up` | Top half |
| `Ctrl + Alt + Down` | Bottom half |
| `Ctrl + Alt + U` | Top-left quarter |
| `Ctrl + Alt + I` | Top-right quarter |
| `Ctrl + Alt + J` | Bottom-left quarter |
| `Ctrl + Alt + K` | Bottom-right quarter |
| `Ctrl + Alt + Return` | Maximize |
| `Ctrl + Alt + C` | Center |
| `Ctrl + Alt + D/F/G` | Thirds (left/center/right) |
| `Ctrl + Alt + E/T` | Two-thirds (left/right) |
| `Ctrl + Alt + Backspace` | Restore to tiling |

## File Locations

| Config | Location |
|--------|----------|
| keyd | `/etc/keyd/default.conf` |
| ghostty | `~/.config/ghostty/config` |
| hyprland bindings | `~/.config/hypr/bindings.conf` |
| hyprland input | `~/.config/hypr/input.conf` |
| snap script | `~/.local/share/omarchy/bin/omarchy-hyprland-snap` |
| tiny-dfr | `/etc/tiny-dfr/config.toml` |
| t2-brightness | `~/.local/bin/t2-brightness` |
| chezmoi source | `~/.local/share/chezmoi` |

## Quick Setup

```bash
# Clone this repo
git clone <your-repo-url> ~/om
cd ~/om

# Run the setup script
./setup.sh
```

## Manual Setup Steps

1. Extract and install Wi-Fi/Bluetooth firmware (see [docs/firmware.md](docs/firmware.md))
2. Install keyd and configure it
3. Configure Touch Bar and brightness (`./touchbar.sh`)
4. Apply chezmoi dotfiles
5. Reload hyprland

See `setup.sh` for the full automated process.

## Workflow: Adding New Customizations

This section explains how to add new customizations to this setup.

### How It Works

There are two systems at play:

1. **chezmoi** (`~/.local/share/chezmoi`) - Manages dotfiles in your home directory. When you run `chezmoi apply`, it copies files from the chezmoi source to their actual locations.

2. **This repo** (`~/om`) - Stores the "master" copies of configs plus setup scripts and documentation. The `setup.sh` script copies configs into chezmoi and applies them.

### Adding a New Customization

#### Step 1: Make the change on your live system

Edit the config file directly where it lives:
```bash
# Example: edit hyprland bindings
vim ~/.config/hypr/bindings.conf
```

Test that it works.

#### Step 2: Copy to this repo

```bash
# Copy the updated config to ~/om/configs/
cp ~/.config/hypr/bindings.conf ~/om/configs/hypr/bindings.conf
```

#### Step 3: Update chezmoi (so it tracks the file)

```bash
# Add to chezmoi if not already tracked
chezmoi add ~/.config/hypr/bindings.conf
```

#### Step 4: Document it

- Update the relevant doc in `~/om/docs/`
- Update the README if it's a notable change
- Add to `setup.sh` if it requires new install steps

#### Step 5: Commit

```bash
cd ~/om
git add -A
git commit -m "Add: description of change"
```

### Adding a New Config File

For a completely new config (e.g., adding waybar config):

```bash
# 1. Create/edit the config on your system
vim ~/.config/waybar/config

# 2. Create the directory in this repo
mkdir -p ~/om/configs/waybar

# 3. Copy the config
cp ~/.config/waybar/config ~/om/configs/waybar/

# 4. Add to chezmoi
chezmoi add ~/.config/waybar/config

# 5. Update setup.sh to include the new config path
# (add the cp and mkdir lines for the new config)

# 6. Document and commit
```

### Adding System Configs (requires sudo)

For configs in `/etc/` (like keyd):

```bash
# 1. Edit the system config
sudo vim /etc/keyd/default.conf

# 2. Copy to this repo
sudo cp /etc/keyd/default.conf ~/om/configs/keyd/default.conf
sudo chown $USER:$USER ~/om/configs/keyd/default.conf

# 3. Document and commit
```

Note: System configs can't be managed by chezmoi (it only handles `~`). The `setup.sh` script uses `sudo cp` for these.

### Quick Reference

| Task | Command |
|------|---------|
| See what chezmoi manages | `chezmoi managed` |
| Add file to chezmoi | `chezmoi add <file>` |
| Apply chezmoi changes | `chezmoi apply` |
| Diff chezmoi vs actual | `chezmoi diff` |
| Chezmoi source location | `~/.local/share/chezmoi` |

### Syncing After Changes on Live System

If you tweak configs and want to capture them:

```bash
# See what changed
chezmoi diff

# Pull changes from live system into chezmoi
chezmoi re-add

# Then copy to this repo
cp ~/.local/share/chezmoi/dot_config/hypr/bindings.conf ~/om/configs/hypr/bindings.conf
```

## Repository Structure

```
~/om/
├── README.md
├── setup.sh              # Main setup script
├── firmware.sh           # T2 firmware extraction script
├── touchbar.sh           # Touch Bar + brightness config
├── configs/
│   ├── keyd/
│   │   └── default.conf  # System-wide key remapping
│   ├── ghostty/
│   │   └── config        # Terminal configuration
│   ├── hypr/
│   │   ├── bindings.conf # Hyprland keybindings
│   │   └── input.conf    # Touchpad/keyboard input settings
│   └── omarchy/
│       └── bin/
│           └── omarchy-hyprland-snap  # Window snapping script
└── docs/
    ├── firmware.md       # Firmware setup guide
    ├── keyboard.md       # Keyboard configuration reference
    └── touchbar.md       # Touch Bar and brightness setup
```
