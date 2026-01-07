#!/bin/bash
# Reapply Omarchy tweaks to the live system
# Supports Linux (Omarchy) and macOS

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect OS
OS_TYPE="unknown"
if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    RUN_HOME="$HOME"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    OS_TYPE="linux"
    RUN_USER="${SUDO_USER:-$USER}"
    RUN_HOME="$(getent passwd "$RUN_USER" | cut -d: -f6)"
    RUN_UID="$(id -u "$RUN_USER")"
    RUN_XDG_RUNTIME_DIR="/run/user/$RUN_UID"
fi

run_user() {
    if [[ "$OS_TYPE" == "macos" ]]; then
        "$@"
    elif [[ "$EUID" -eq 0 ]]; then
        if [[ -d "$RUN_XDG_RUNTIME_DIR" ]]; then
            sudo -u "$RUN_USER" env HOME="$RUN_HOME" XDG_RUNTIME_DIR="$RUN_XDG_RUNTIME_DIR" "$@"
        else
            sudo -u "$RUN_USER" env HOME="$RUN_HOME" "$@"
        fi
    else
        "$@"
    fi
}

echo "=== Omarchy Reapply ($OS_TYPE) ==="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Apply shared configs (both OSes)
apply_shared() {
    info "Applying shared configs..."

    # Shared ghostty config
    mkdir -p "$RUN_HOME/.config/omarchy/ghostty"
    cp "$SCRIPT_DIR/configs/shared/ghostty/common.conf" "$RUN_HOME/.config/omarchy/ghostty/common.conf"

    # Shared zsh config (ghostty colors)
    mkdir -p "$RUN_HOME/.config/omarchy/zsh"
    cp "$SCRIPT_DIR/configs/shared/zsh/ghostty-colors.zsh" "$RUN_HOME/.config/omarchy/zsh/ghostty-colors.zsh"

    info "Shared configs applied"
}

# Apply macOS-specific configs
apply_macos() {
    info "Applying macOS configs..."

    # Ghostty config
    mkdir -p "$RUN_HOME/.config/ghostty"
    cp "$SCRIPT_DIR/configs/macos/ghostty/config" "$RUN_HOME/.config/ghostty/config"

    info "macOS configs applied"
    echo ""
    info "Add to your .zshrc:"
    echo "  source ~/.config/omarchy/zsh/ghostty-colors.zsh"
}

# Apply Linux-specific configs
apply_linux() {
    # 1. Reapply keyd config if keyd is available
    if command -v keyd &> /dev/null; then
        info "Reapplying keyd config..."
        sudo mkdir -p /etc/keyd
        sudo cp "$SCRIPT_DIR/configs/linux/keyd/default.conf" /etc/keyd/default.conf
        sudo systemctl restart keyd
        if systemctl --quiet is-active keyd; then
            info "keyd restarted"
        else
            warn "keyd not active after restart"
            systemctl status keyd --no-pager -l || true
        fi
    else
        warn "keyd not installed; skipping keyd config"
    fi

    # 2. Reapply chezmoi-managed dotfiles
    if command -v chezmoi &> /dev/null; then
        info "Reapplying chezmoi dotfiles..."
        run_user mkdir -p "$RUN_HOME/.local/share/chezmoi"

        # Copy ghostty config
        run_user mkdir -p "$RUN_HOME/.local/share/chezmoi/dot_config/ghostty"
        run_user cp "$SCRIPT_DIR/configs/linux/ghostty/config" "$RUN_HOME/.local/share/chezmoi/dot_config/ghostty/config"

        # Copy omarchy scripts
        run_user mkdir -p "$RUN_HOME/.local/share/chezmoi/dot_local/share/omarchy/bin"
        run_user cp "$SCRIPT_DIR/configs/linux/omarchy/bin/omarchy-hyprland-snap" "$RUN_HOME/.local/share/chezmoi/dot_local/share/omarchy/bin/executable_omarchy-hyprland-snap"
        run_user cp "$SCRIPT_DIR/configs/linux/omarchy/bin/omarchy-new-terminal-workspace" "$RUN_HOME/.local/share/chezmoi/dot_local/share/omarchy/bin/executable_omarchy-new-terminal-workspace"

        # Copy keyd app-specific config
        run_user mkdir -p "$RUN_HOME/.config/keyd"
        run_user cp "$SCRIPT_DIR/configs/linux/keyd/app.conf" "$RUN_HOME/.config/keyd/app.conf"

        # Apply with chezmoi
        if run_user chezmoi apply; then
            info "chezmoi dotfiles applied"
        else
            warn "chezmoi apply failed (inconsistent state); fix and rerun if needed"
        fi

        # Apply Hyprland configs directly so they don't get overwritten by chezmoi
        run_user mkdir -p "$RUN_HOME/.config/hypr"
        run_user cp "$SCRIPT_DIR/configs/linux/hypr/bindings.conf" "$RUN_HOME/.config/hypr/bindings.conf"
        run_user cp "$SCRIPT_DIR/configs/linux/hypr/input.conf" "$RUN_HOME/.config/hypr/input.conf"

        # Apply Ghostty config directly for immediate effect.
        run_user mkdir -p "$RUN_HOME/.config/ghostty"
        run_user cp "$SCRIPT_DIR/configs/linux/ghostty/config" "$RUN_HOME/.config/ghostty/config"
    else
        warn "chezmoi not installed; skipping dotfiles apply"
    fi

    # 3. Reload hyprland if running
    if run_user pgrep -x "Hyprland" > /dev/null; then
        info "Reloading Hyprland..."
        run_user hyprctl reload
        info "Hyprland reloaded"
    else
        warn "Hyprland not running, skipping reload"
    fi

    # 4. Start keyd application mapper if available
    if command -v keyd-application-mapper &> /dev/null; then
        info "Ensuring keyd application mapper..."
        # Clear stale lockfile so mapper can start cleanly.
        run_user rm -f "$RUN_HOME/.config/keyd/app.lock"
        if ! id -nG "$RUN_USER" | tr ' ' '\n' | grep -qx "keyd"; then
            warn "User $RUN_USER is not in the keyd group; app-specific mappings will not work"
            info "Adding $RUN_USER to keyd group..."
            sudo usermod -aG keyd "$RUN_USER"
            warn "Log out and back in to pick up keyd group membership"
        else
            # Prefer systemd user service if available; fallback to direct daemonize.
            if run_user systemctl --user >/dev/null 2>&1; then
                run_user mkdir -p "$RUN_HOME/.config/systemd/user"
                run_user tee "$RUN_HOME/.config/systemd/user/keyd-application-mapper.service" >/dev/null <<'EOF'
[Unit]
Description=keyd application mapper
After=default.target

[Service]
ExecStart=/usr/bin/keyd-application-mapper -d
Restart=on-failure

[Install]
WantedBy=default.target
EOF
                run_user systemctl --user daemon-reload || true
                run_user systemctl --user enable --now keyd-application-mapper.service || true
            fi
            if ! run_user pgrep -f "keyd-application-mapper" > /dev/null; then
                info "Starting keyd application mapper..."
                run_user keyd-application-mapper -d || warn "keyd-application-mapper failed to start"
            else
                info "keyd-application-mapper already running"
            fi
        fi
    fi

    # 5. Reload user mapper service if present
    if [[ -d "$RUN_XDG_RUNTIME_DIR" ]]; then
        if command -v timeout >/dev/null 2>&1; then
            run_user timeout 3s systemctl --user daemon-reload >/dev/null 2>&1 || true
            run_user timeout 3s systemctl --user restart keyd-application-mapper.service >/dev/null 2>&1 || true
        else
            run_user systemctl --user daemon-reload >/dev/null 2>&1 || true
            run_user systemctl --user restart keyd-application-mapper.service >/dev/null 2>&1 || true
        fi
    fi

    # 6. Force mapper reconnect and show recent log on failure
    if command -v keyd-application-mapper &> /dev/null; then
        info "Reloading keyd application mapper..."
        run_user rm -f "$RUN_HOME/.config/keyd/app.lock"
        run_user pkill -f "keyd-application-mapper" >/dev/null 2>&1 || true
        run_user keyd-application-mapper -d || warn "keyd-application-mapper failed to start"
        if run_user pgrep -f "keyd-application-mapper" >/dev/null 2>&1; then
            info "keyd-application-mapper running"
        else
            warn "keyd-application-mapper not running"
        fi
        if [[ -f "$RUN_HOME/.config/keyd/app.log" ]]; then
            if run_user tail -n 20 "$RUN_HOME/.config/keyd/app.log" | grep -q "Failed to connect"; then
                warn "keyd-application-mapper cannot connect to /var/run/keyd.socket"
                ls -l /var/run/keyd.socket || true
                run_user id || true
            fi
        fi
    fi
}

# Main execution
apply_shared

if [[ "$OS_TYPE" == "macos" ]]; then
    apply_macos
elif [[ "$OS_TYPE" == "linux" ]]; then
    apply_linux
else
    warn "Unknown OS type: $OSTYPE"
fi

echo ""
echo "=== Reapply Complete ==="
