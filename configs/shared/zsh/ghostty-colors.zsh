# Ghostty random background colors
# New windows get random color, splits inherit the same color
# Source this from .zshrc: source ~/.config/omarchy/zsh/ghostty-colors.zsh

if [[ -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  _GHOSTTY_COLORS=(
    "#1a1a2e"  # deep navy
    "#16213e"  # dark blue
    "#1b2631"  # charcoal
    "#0d1117"  # github dark
    "#1e1e2e"  # catppuccin base
    "#282a36"  # dracula
    "#2e3440"  # nord
    "#1d1f21"  # tomorrow night
    "#263238"  # material dark
    "#0f111a"  # material darker
  )

  # Pick new random color, save it, apply it
  newcolor() {
    local color=${_GHOSTTY_COLORS[$((RANDOM % ${#_GHOSTTY_COLORS[@]} + 1))]}
    echo "$(date +%s) $color" > /tmp/ghostty_current_color
    printf '\e]21;background=%s\e\\' "$color"
  }

  # Detect: split (< 3 sec since last shell) vs new window (> 3 sec)
  _ghostty_apply_color() {
    if [[ -f /tmp/ghostty_current_color ]]; then
      local last_time last_color now
      read last_time last_color < /tmp/ghostty_current_color
      now=$(date +%s)
      if (( now - last_time < 3 )); then
        # Recent shell = likely a split, reuse color
        printf '\e]21;background=%s\e\\' "$last_color"
        echo "$now $last_color" > /tmp/ghostty_current_color
      else
        # Old timestamp = new window, pick new color
        newcolor
      fi
    else
      newcolor  # First ever window
    fi
  }

  _ghostty_apply_color
fi
