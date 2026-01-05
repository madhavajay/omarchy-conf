# Keyboard Configuration

This document details the keyboard customizations for a Mac-like experience on Linux.

## Overview

Using **keyd** for system-wide key remapping, the keyboard behaves like macOS:
- Capslock becomes Meta/Super (acts like Command key)
- Meta/Command + standard keys work like macOS
- Home/End navigation with Meta + arrow keys

## keyd Configuration

Location: `/etc/keyd/default.conf`

See `~/om/configs/keyd/default.conf` for the full config. Key sections:

```ini
[ids]
*

[main]
leftmeta = layer(cmd)
rightmeta = layer(cmd)
capslock = layer(meta)
leftalt = layer(alt)
rightalt = layer(alt)

[cmd]
# Basic editing: a, c, v, x, z, s, f, w, t, n, o, p, q, r, l, k, d, g, b, i, u, y, h
# Tab switching: 1-9
# Navigation: left/right (home/end), up/down (top/bottom), backspace (delete line)

[cmd+shift]
# Shift combos: z (redo), t (reopen tab), n (private), p (palette), g (find prev), f (find in files)
# Shifted navigation: left/right/up/down (select to line/document edges)

[alt]
# Word navigation: left/right, backspace, delete

[alt+shift]
# Word selection: left/right
```

### Key Mappings Explained

| Physical Key | Becomes |
|--------------|---------|
| Capslock | Meta/Super (Command) |
| Left Meta | Layer activator for cmd shortcuts |
| Right Meta | Layer activator for cmd shortcuts |
| Left Alt | Layer activator for option shortcuts |
| Right Alt | Layer activator for option shortcuts |

### Command Layer Shortcuts

When holding Meta/Command:

| Shortcut | Action |
|----------|--------|
| Cmd+A | Select All |
| Cmd+C | Copy |
| Cmd+V | Paste |
| Cmd+X | Cut |
| Cmd+Z | Undo |
| Cmd+Y | Redo (alternative) |
| Cmd+S | Save |
| Cmd+F | Find |
| Cmd+G | Find next |
| Cmd+W | Close window/tab |
| Cmd+T | New tab |
| Cmd+N | New window |
| Cmd+O | Open |
| Cmd+P | Print |
| Cmd+Q | Quit |
| Cmd+R | Refresh |
| Cmd+L | Address bar / Go to line |
| Cmd+K | Insert link |
| Cmd+D | Bookmark / Duplicate |
| Cmd+H | History / Replace |
| Cmd+B | Bold |
| Cmd+I | Italic |
| Cmd+U | Underline |
| Cmd+1-9 | Switch to workspace 1-9 (Hyprland) |
| Cmd+` | Cycle windows (Hyprland) |
| Cmd+[ / Cmd+] | Workspace left/right (Hyprland) |

### Command+Shift Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+Shift+Z | Redo |
| Cmd+Shift+T | Reopen closed tab |
| Cmd+Shift+N | New incognito/private window |
| Cmd+Shift+P | Command palette |
| Cmd+Shift+G | Find previous |
| Cmd+Shift+F | Find in files |

### Navigation Shortcuts

| Shortcut | Action |
|----------|--------|
| Cmd+Left | Start of line |
| Cmd+Right | End of line |
| Cmd+Up | Top of document |
| Cmd+Down | Bottom of document |
| Cmd+Shift+Left | Select to start of line |
| Cmd+Shift+Right | Select to end of line |
| Cmd+Shift+Up | Select to top of document |
| Cmd+Shift+Down | Select to bottom of document |
| Cmd+Backspace | Delete to start of line |
| Cmd+[ | Browser back |
| Cmd+] | Browser forward |
| Cmd+{ (Cmd+Shift+[) | Previous tab |
| Cmd+} (Cmd+Shift+]) | Next tab |

### Option/Alt Layer Shortcuts (Word Navigation)

| Shortcut | Action |
|----------|--------|
| Option+Left | Move word left |
| Option+Right | Move word right |
| Option+Shift+Left | Select word left |
| Option+Shift+Right | Select word right |
| Option+Backspace | Delete word backward |
| Option+Delete | Delete word forward |

## Installation

```bash
# Install keyd
sudo pacman -S keyd

# Copy config
sudo cp configs/keyd/default.conf /etc/keyd/default.conf

# Enable and start
sudo systemctl enable keyd
sudo systemctl restart keyd
```

## Testing

Use `keyd list-apps` to see app identifiers for app-specific bindings.

Check keyd status:
```bash
sudo systemctl status keyd
keyd --version
```

## Ghostty Terminal Keybindings

The terminal has additional Mac-style bindings configured in `~/.config/ghostty/config`:

```
keybind = super+c=copy_to_clipboard
keybind = super+v=paste_from_clipboard
keybind = super+x=copy_to_clipboard
keybind = super+w=close_surface
keybind = super+q=quit
```

## Hyprland Window Manager Bindings

### Application Launchers

| Shortcut | Action |
|----------|--------|
| Super+Return | Terminal |
| Super+Shift+F | File manager (Nautilus) |
| Super+Shift+B | Browser |
| Super+Shift+Alt+B | Browser (private) |
| Super+Shift+M | Music (Spotify) |
| Super+Shift+N | Editor |
| Super+Shift+T | Activity monitor (btop) |
| Super+Shift+D | Docker (lazydocker) |
| Super+Shift+G | Signal |
| Super+Shift+O | Obsidian |
| Super+Shift+W | Typora |
| Super+Shift+/ | 1Password |

### Web Apps

| Shortcut | App |
|----------|-----|
| Super+Shift+A | ChatGPT |
| Super+Shift+Alt+A | Grok |
| Super+Shift+C | Calendar (Hey) |
| Super+Shift+E | Email (Hey) |
| Super+Shift+Y | YouTube |
| Super+Shift+Alt+G | WhatsApp |
| Super+Shift+Ctrl+G | Google Messages |
| Super+Shift+P | Google Photos |
| Super+Shift+X | X (Twitter) |
| Super+Shift+Alt+X | X Post |

### Window Management

| Shortcut | Action |
|----------|--------|
| Super+` | Cycle windows forward |
| Super+Shift+` | Cycle windows backward |

## Hyprland Input Settings

Touchpad:
- Natural scroll
- Tap-to-click disabled
- Disable while typing

Window focus:
- Click-to-focus (no focus follows mouse)

### Magnet-Style Window Snapping

| Shortcut | Position |
|----------|----------|
| Ctrl+Alt+Left | Left half |
| Ctrl+Alt+Right | Right half |
| Ctrl+Alt+Up | Top half |
| Ctrl+Alt+Down | Bottom half |
| Ctrl+Alt+U | Top-left quarter |
| Ctrl+Alt+I | Top-right quarter |
| Ctrl+Alt+J | Bottom-left quarter |
| Ctrl+Alt+K | Bottom-right quarter |
| Ctrl+Alt+Return | Maximize (with gaps) |
| Ctrl+Alt+C | Center (2/3 size) |
| Ctrl+Alt+D | Left third |
| Ctrl+Alt+F | Center third |
| Ctrl+Alt+G | Right third |
| Ctrl+Alt+E | Left two-thirds |
| Ctrl+Alt+T | Right two-thirds |
| Ctrl+Alt+Backspace | Restore to tiling |

## Touchpad/Input Settings

Configured in `~/.config/hypr/input.conf`:

- Natural scroll enabled
- Tap-to-click enabled
- Two-finger click for right-click
- Scroll factor: 0.4 (slower)
- Keyboard repeat: 40 rate, 600ms delay
