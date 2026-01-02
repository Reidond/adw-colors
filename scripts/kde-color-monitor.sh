#!/bin/bash
# KDE Color Scheme Monitor for adw-colors
# This script monitors KDE Plasma color scheme changes and switches GTK themes accordingly

GTK3_DIR="$HOME/.config/gtk-3.0"
GTK3_FILE="$GTK3_DIR/gtk.css"

switch_to_light() {
    echo "[$(date)] Switching to light theme..."
    cat > "$GTK3_FILE" << 'EOF'
@import url("gtk-light.css");
EOF
    # For systems with both GNOME and KDE settings
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3" 2>/dev/null
        gsettings set org.gnome.desktop.interface color-scheme "default" 2>/dev/null
    fi
}

switch_to_dark() {
    echo "[$(date)] Switching to dark theme..."
    cat > "$GTK3_FILE" << 'EOF'
@import url("gtk-dark.css");
EOF
    # For systems with both GNOME and KDE settings
    if command -v gsettings >/dev/null 2>&1; then
        gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
        gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
    fi
}

get_kde_color_scheme() {
    # Try to detect if KDE is using a dark color scheme
    # Method 1: Check kdeglobals ColorScheme name
    local scheme=$(kreadconfig5 --group "General" --key "ColorScheme" 2>/dev/null)
    if [ -n "$scheme" ]; then
        # Common dark scheme patterns
        if echo "$scheme" | grep -qi "dark\|breezedark\|night\|obsidian"; then
            echo "dark"
            return
        fi
    fi
    
    # Method 2: Check the actual background color brightness
    local bg_color=$(kreadconfig5 --group "Colors:Window" --key "BackgroundNormal" 2>/dev/null)
    if [ -n "$bg_color" ]; then
        # Parse RGB values (format: R,G,B)
        local r=$(echo "$bg_color" | cut -d',' -f1)
        local g=$(echo "$bg_color" | cut -d',' -f2)
        local b=$(echo "$bg_color" | cut -d',' -f3)
        if [ -n "$r" ] && [ -n "$g" ] && [ -n "$b" ]; then
            # Calculate perceived brightness (0-255)
            local brightness=$(( (r * 299 + g * 587 + b * 114) / 1000 ))
            if [ "$brightness" -lt 128 ]; then
                echo "dark"
                return
            fi
        fi
    fi
    
    echo "light"
}

apply_current_scheme() {
    local scheme=$(get_kde_color_scheme)
    if [ "$scheme" = "dark" ]; then
        switch_to_dark
    else
        switch_to_light
    fi
}

# Check if required files exist
if [ ! -f "$GTK3_DIR/gtk-light.css" ] || [ ! -f "$GTK3_DIR/gtk-dark.css" ]; then
    echo "Error: gtk-light.css and gtk-dark.css not found in $GTK3_DIR"
    echo "Please run install.sh and select 'Auto (Light + Dark)' first."
    exit 1
fi

# Handle command line arguments
case "$1" in
    --once)
        # Just apply current scheme and exit
        apply_current_scheme
        exit 0
        ;;
    --light)
        switch_to_light
        exit 0
        ;;
    --dark)
        switch_to_dark
        exit 0
        ;;
    --daemon)
        # Continue to daemon mode below
        ;;
    *)
        echo "KDE Color Scheme Monitor for adw-colors"
        echo ""
        echo "Usage: $0 [option]"
        echo ""
        echo "Options:"
        echo "  --once    Apply current KDE scheme and exit"
        echo "  --light   Force light theme"
        echo "  --dark    Force dark theme"
        echo "  --daemon  Run as daemon, monitoring for changes"
        echo ""
        echo "Without options, shows this help."
        exit 0
        ;;
esac

# Daemon mode: Monitor for changes
echo "Starting KDE color scheme monitor..."
echo "Monitoring ~/.config/kdeglobals for changes..."
echo "Press Ctrl+C to stop."

# Apply current scheme immediately
apply_current_scheme

# Check if inotifywait is available
if ! command -v inotifywait >/dev/null 2>&1; then
    echo ""
    echo "Warning: inotifywait not found. Install inotify-tools for file monitoring."
    echo "Falling back to polling mode (checks every 5 seconds)..."
    echo ""
    
    last_scheme=""
    while true; do
        current_scheme=$(get_kde_color_scheme)
        if [ "$current_scheme" != "$last_scheme" ]; then
            apply_current_scheme
            last_scheme="$current_scheme"
        fi
        sleep 5
    done
else
    # Use inotifywait for efficient monitoring
    while true; do
        inotifywait -q -e modify,create "$HOME/.config/kdeglobals" 2>/dev/null
        sleep 0.5  # Small delay to let KDE finish writing
        apply_current_scheme
    done
fi
