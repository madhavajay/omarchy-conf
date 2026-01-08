#!/bin/bash
# Omarchy Setup Script
# Run this on a fresh Omarchy installation to apply all customizations

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Omarchy Setup ==="
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

# 1. Install required packages
if ! command -v zsh &> /dev/null; then
    info "Installing zsh..."
    sudo pacman -S --noconfirm zsh
fi

if ! command -v keyd &> /dev/null; then
    info "Installing keyd..."
    sudo pacman -S --noconfirm keyd
fi

# 2. Configure keyd
info "Configuring keyd..."
sudo mkdir -p /etc/keyd
sudo cp "$SCRIPT_DIR/configs/keyd/default.conf" /etc/keyd/default.conf
sudo systemctl enable keyd
sudo systemctl restart keyd
info "keyd configured and restarted"

# 3. Apply chezmoi dotfiles
info "Applying chezmoi dotfiles..."
mkdir -p ~/.local/share/chezmoi

# Copy ghostty config
mkdir -p ~/.local/share/chezmoi/dot_config/ghostty
cp "$SCRIPT_DIR/configs/ghostty/config" ~/.local/share/chezmoi/dot_config/ghostty/config

# Copy hyprland configs
mkdir -p ~/.local/share/chezmoi/dot_config/hypr
cp "$SCRIPT_DIR/configs/hypr/bindings.conf" ~/.local/share/chezmoi/dot_config/hypr/bindings.conf
cp "$SCRIPT_DIR/configs/hypr/input.conf" ~/.local/share/chezmoi/dot_config/hypr/input.conf

# Copy omarchy scripts
mkdir -p ~/.local/share/chezmoi/dot_local/share/omarchy/bin
cp "$SCRIPT_DIR/configs/omarchy/bin/omarchy-hyprland-snap" ~/.local/share/chezmoi/dot_local/share/omarchy/bin/omarchy-hyprland-snap

# Apply with chezmoi
chezmoi apply
info "chezmoi dotfiles applied"

# 4. Configure zsh
info "Configuring zsh..."
ZSHRC="$HOME/.zshrc"
GHOSTTY_SOURCE='source ~/.config/omarchy/zsh/ghostty-colors.zsh'

if [[ ! -f "$ZSHRC" ]]; then
    echo "# Omarchy zsh config" > "$ZSHRC"
fi

if ! grep -qF "$GHOSTTY_SOURCE" "$ZSHRC" 2>/dev/null; then
    echo "" >> "$ZSHRC"
    echo "# Ghostty random background colors" >> "$ZSHRC"
    echo "$GHOSTTY_SOURCE" >> "$ZSHRC"
    info "Added ghostty-colors.zsh to .zshrc"
else
    info "ghostty-colors.zsh already in .zshrc"
fi

# Change default shell to zsh if not already
if [[ "$SHELL" != *"zsh"* ]]; then
    info "Changing default shell to zsh..."
    chsh -s "$(which zsh)"
    info "Default shell changed to zsh (takes effect on next login)"
fi

# 5. Reload hyprland if running
if pgrep -x "Hyprland" > /dev/null; then
    info "Reloading Hyprland..."
    hyprctl reload
    info "Hyprland reloaded"
else
    warn "Hyprland not running, skipping reload"
fi

echo ""
echo "=== Setup Complete ==="
echo "You may need to log out and back in for all changes to take effect."
