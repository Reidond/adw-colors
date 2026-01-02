#! /bin/sh

# Functions for the install script

# Get script directory
get_script_dir() {
  dirname -- "$(readlink -f -- "$0")"
}

# Set up global variables
setup_variables() {
  gtk3_file="$HOME/.config/gtk-3.0/gtk.css"
  gtk4_file="$HOME/.config/gtk-4.0/gtk.css"
  gtk3_assets="$HOME/.config/gtk-3.0/assets"
  gtk4_assets="$HOME/.config/gtk-4.0/assets"
  backup_number=$(date +%s)
}

# Check if gsettings command exists
check_gsettings() {
  if ! command -v gsettings >/dev/null; then
    printf "\e[31mError:\e[0m gsettings command not found. Install dconf.\n"
    exit 1
  fi
}

# Ensure GTK_THEME is not set
check_gtk_theme_var() {
  if [ -n "${GTK_THEME}" ]; then
    printf "\e[31mError:\e[0m GTK_THEME environment variable is set. Please remove it by running:\n"
    printf "  unset GTK_THEME  # Temporarily for this session\n"
    printf "  nano ~/.bashrc   # Remove it permanently from your shell configuration\n"
    printf "  sudo nano /etc/environment  # Remove system-wide setting\n"
    printf "  Setting the GTK_THEME environment variable is not recommended. It can interfere with these themes. It's only meant to be used for developing purposes.\n"
    exit 1
  fi
}

# Check if adw-gtk3 is installed
check_adw_gtk3_installed() {
  if [ -d "$HOME/.local/share/themes/adw-gtk3" ] || [ -d "$HOME/.local/share/themes/adw-gtk3-dark" ]; then
    true
  elif [ -d "$HOME/.themes/adw-gtk3" ] || [ -d "$HOME/.themes/adw-gtk3-dark" ]; then
    printf "\e[33mWarning:\e[0m Unless you use a GTK2 theme you should install adw-gtk3 in ~/.local/share/themes instead of ~/.themes.\n"
    true
  elif [ -d "/usr/share/themes/adw-gtk3" ] || [ -d "/usr/share/themes/adw-gtk3-dark" ]; then
    true
  else
    printf "\e[31mError:\e[0m adw-gtk3 not installed. Download from: https://github.com/lassekongo83/adw-gtk3\n"
    exit 1
  fi
}

# Unlink previous styles
uninstall_old() {
  unlink "$HOME/.config/gtk-3.0/gtk.css" 2>/dev/null
  unlink "$HOME/.config/gtk-4.0/gtk.css" 2>/dev/null
  unlink "$HOME/.config/gtk-3.0/assets" 2>/dev/null
  unlink "$HOME/.config/gtk-4.0/assets" 2>/dev/null
  unlink "$HOME/.config/gtk-3.0/titlebutton-traffic-gtk3-dark.css" 2>/dev/null
  unlink "$HOME/.config/gtk-4.0/titlebutton-traffic-gtk4-dark.css" 2>/dev/null
  unlink "$HOME/.config/gtk-3.0/titlebutton-traffic-gtk3-light.css" 2>/dev/null
  unlink "$HOME/.config/gtk-4.0/titlebutton-traffic-gtk4-light.css" 2>/dev/null
}

# Backup existing GTK config
create_backup() {
  for file in "${gtk3_file}" "${gtk4_file}"; do
    if [ -f "$file" ] && [ ! -L "$file" ]; then
      mv "$file" "$file.${backup_number}.bak"
      echo "Backup created at $file.${backup_number}.bak"
    else
      mkdir -p "$(dirname "$file")"
    fi
  done
}

apply_theme() {
  variant="$1"
  gtk_theme="$2"
  color_scheme="$3"
  css_suffix="$4"

  create_backup
  uninstall_old

  printf "Setting %s theme...\n" "$variant"
  ln -s "${theme_dir}/gtk3-${css_suffix}.css" "${gtk3_file}" || {
    printf "Error creating symlink for gtk3 %s theme\n" "$variant"
    exit 1
  }
  ln -s "${theme_dir}/gtk4-${css_suffix}.css" "${gtk4_file}" || {
    printf "Error creating symlink for gtk4 %s theme\n" "$variant"
    exit 1
  }

  # Link assets if present
  theme_assets="${theme_dir}/assets"
  if [ -d "$theme_assets" ]; then
    ln -s "$theme_assets" "$gtk3_assets" || {
      printf "Error linking assets to %s\n" "$gtk3_assets"
      exit 1
    }
    ln -s "$theme_assets" "$gtk4_assets" || {
      printf "Error linking assets to %s\n" "$gtk4_assets"
      exit 1
    }
  fi

  # Apply theme settings
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
  gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"

  printf "Theme installed. Restart GTK applications or relog if needed.\n"
}

apply_theme_auto() {
  # Auto mode: install both light and dark, with a wrapper that imports based on current scheme
  create_backup
  uninstall_old

  printf "Setting Auto (Light + Dark) theme...\n"

  # Copy both variants to config directories
  gtk3_dir="$HOME/.config/gtk-3.0"
  gtk4_dir="$HOME/.config/gtk-4.0"
  mkdir -p "$gtk3_dir" "$gtk4_dir"

  cp "${theme_dir}/gtk3-light.css" "${gtk3_dir}/gtk-light.css" || {
    printf "Error copying gtk3 light theme\n"
    exit 1
  }
  cp "${theme_dir}/gtk3-dark.css" "${gtk3_dir}/gtk-dark.css" || {
    printf "Error copying gtk3 dark theme\n"
    exit 1
  }
  cp "${theme_dir}/gtk4-light.css" "${gtk4_dir}/gtk-light.css" || {
    printf "Error copying gtk4 light theme\n"
    exit 1
  }
  cp "${theme_dir}/gtk4-dark.css" "${gtk4_dir}/gtk-dark.css" || {
    printf "Error copying gtk4 dark theme\n"
    exit 1
  }

  # Create wrapper gtk.css that imports based on current color scheme
  # GTK4 supports prefers-color-scheme, GTK3 needs manual switching
  cat > "${gtk4_file}" << 'EOF'
/* Auto Light/Dark theme - switches based on system color scheme */
@import url("gtk-light.css") (prefers-color-scheme: light);
@import url("gtk-light.css") (prefers-color-scheme: no-preference);
@import url("gtk-dark.css") (prefers-color-scheme: dark);
EOF

  # For GTK3, we need to detect current scheme and import the right file
  current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")
  if echo "$current_scheme" | grep -q "dark"; then
    cat > "${gtk3_file}" << 'EOF'
/* Auto theme - run install.sh again or use the switch script to change variants */
@import url("gtk-dark.css");
EOF
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
  else
    cat > "${gtk3_file}" << 'EOF'
/* Auto theme - run install.sh again or use the switch script to change variants */
@import url("gtk-light.css");
EOF
    gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
  fi

  # Create a helper script for switching GTK3 theme
  switch_script="$gtk3_dir/switch-theme.sh"
  cat > "$switch_script" << 'SWITCH_EOF'
#!/bin/sh
# Helper script to switch GTK3 theme variant
# Usage: switch-theme.sh [light|dark]
# Without arguments, it toggles based on current color-scheme

gtk3_dir="$HOME/.config/gtk-3.0"
gtk3_file="$gtk3_dir/gtk.css"

current_scheme=$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null || echo "'default'")

if [ "$1" = "light" ] || { [ -z "$1" ] && echo "$current_scheme" | grep -q "dark"; }; then
  cat > "$gtk3_file" << 'EOF'
@import url("gtk-light.css");
EOF
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3"
  gsettings set org.gnome.desktop.interface color-scheme "default"
  echo "Switched to light theme"
elif [ "$1" = "dark" ] || { [ -z "$1" ] && ! echo "$current_scheme" | grep -q "dark"; }; then
  cat > "$gtk3_file" << 'EOF'
@import url("gtk-dark.css");
EOF
  gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark"
  gsettings set org.gnome.desktop.interface color-scheme "prefer-dark"
  echo "Switched to dark theme"
fi
SWITCH_EOF
  chmod +x "$switch_script"

  # Link assets if present
  theme_assets="${theme_dir}/assets"
  if [ -d "$theme_assets" ]; then
    ln -s "$theme_assets" "$gtk3_assets" 2>/dev/null
    ln -s "$theme_assets" "$gtk4_assets" 2>/dev/null
  fi

  printf "\nTheme installed with Auto (Light + Dark) support!\n"
  printf "  • GTK4 apps will automatically switch based on color-scheme\n"
  printf "  • For GTK3, use: ~/.config/gtk-3.0/switch-theme.sh [light|dark]\n"
  printf "  • Or change color-scheme in GNOME Settings and run the switch script\n"
  
  # Check if running KDE and offer to install the monitor
  if [ -n "$KDE_SESSION_VERSION" ] || [ "$XDG_CURRENT_DESKTOP" = "KDE" ]; then
    printf "\n\e[33mKDE Plasma detected!\e[0m\n"
    printf "Would you like to install the KDE color scheme monitor? [y/N]: "
    read -r install_kde_monitor
    if [ "$install_kde_monitor" = "y" ] || [ "$install_kde_monitor" = "Y" ]; then
      install_kde_monitor_service
    fi
  fi
  
  printf "Restart GTK applications or relog if needed.\n"
}

install_kde_monitor_service() {
  SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
  
  # Install the monitor script
  mkdir -p "$HOME/.local/bin"
  cp "$SCRIPT_DIR/kde-color-monitor.sh" "$HOME/.local/bin/"
  chmod +x "$HOME/.local/bin/kde-color-monitor.sh"
  
  # Install the systemd service
  mkdir -p "$HOME/.config/systemd/user"
  cp "$SCRIPT_DIR/kde-color-monitor.service" "$HOME/.config/systemd/user/"
  
  # Enable and start the service
  systemctl --user daemon-reload
  systemctl --user enable kde-color-monitor.service
  systemctl --user start kde-color-monitor.service
  
  printf "\e[32mKDE color monitor installed and started!\e[0m\n"
  printf "  • Service: kde-color-monitor.service\n"
  printf "  • Script: ~/.local/bin/kde-color-monitor.sh\n"
  printf "  • Status: systemctl --user status kde-color-monitor\n"
  printf "  • Logs: journalctl --user -u kde-color-monitor -f\n"
}

apply_theme_titlebutton() {
  variant="$1"
  gtk_theme="$2"
  color_scheme="$3"
  css_suffix="$4"

  create_backup
  uninstall_old

  printf "Setting %s theme...\n" "$variant"
  ln -s "${theme_dir}/titlebutton-traffic-gtk3-${css_suffix}.css" "${gtk3_file}" || {
    printf "Error creating symlink for gtk3 %s theme\n" "$variant"
    exit 1
  }
  ln -s "${theme_dir}/titlebutton-traffic-gtk4-${css_suffix}.css" "${gtk4_file}" || {
    printf "Error creating symlink for gtk4 %s theme\n" "$variant"
    exit 1
  }

  # Link assets if present
  theme_assets="${theme_dir}/assets"
  if [ -d "$theme_assets" ]; then
    ln -s "$theme_assets" "$gtk3_assets" || {
      printf "Error linking assets to %s\n" "$gtk3_assets"
      exit 1
    }
    ln -s "$theme_assets" "$gtk4_assets" || {
      printf "Error linking assets to %s\n" "$gtk4_assets"
      exit 1
    }
  fi

  # Apply theme settings
  gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme"
  gsettings set org.gnome.desktop.interface color-scheme "$color_scheme"

  printf "Theme installed. Restart GTK applications or relog if needed.\n"
}

# Auto-detect theme variants
auto_apply_variant() {
  theme_dir=$1
  [ -d "$theme_dir" ] || {
    printf "\e[31mError:\e[0m theme_dir '%s' not found\n" "$theme_dir" >&2
    exit 1
  }

  i=0

  # 1) Auto (Light + Dark) - only if both variants exist
  if [ -f "$theme_dir/gtk3-light.css" ] && [ -f "$theme_dir/gtk4-light.css" ] \
     && [ -f "$theme_dir/gtk3-dark.css" ] && [ -f "$theme_dir/gtk4-dark.css" ]; then
    i=$((i+1))
    printf " %d) Auto (Light + Dark) - switches with system\n" "$i"
    eval "fn_$i=apply_theme_auto"
    eval "variant_$i=auto"
    eval "gtk_theme_$i=adw-gtk3"
    eval "color_scheme_$i=default"
    eval "suffix_$i=auto"
  fi

  # 2) Light
  if [ -f "$theme_dir/gtk3-light.css" ] && [ -f "$theme_dir/gtk4-light.css" ]; then
    i=$((i+1))
    printf " %d) Light theme\n" "$i"
    eval "fn_$i=apply_theme"
    eval "variant_$i=light"
    eval "gtk_theme_$i=adw-gtk3"
    eval "color_scheme_$i=default"
    eval "suffix_$i=light"
  fi

  # 3) Dark
  if [ -f "$theme_dir/gtk3-dark.css" ] && [ -f "$theme_dir/gtk4-dark.css" ]; then
    i=$((i+1))
    printf " %d) Dark theme\n" "$i"
    eval "fn_$i=apply_theme"
    eval "variant_$i=dark"
    eval "gtk_theme_$i=adw-gtk3-dark"
    eval "color_scheme_$i=prefer-dark"
    eval "suffix_$i=dark"
  fi

  # 4) Light + traffic-light
  if [ -f "$theme_dir/titlebutton-traffic-gtk3-light.css" ] \
     && [ -f "$theme_dir/titlebutton-traffic-gtk4-light.css" ]; then
    i=$((i+1))
    printf " %d) Light + traffic-light titlebar buttons\n" "$i"
    eval "fn_$i=apply_theme_titlebutton"
    eval "variant_$i=light"
    eval "gtk_theme_$i=adw-gtk3"
    eval "color_scheme_$i=default"
    eval "suffix_$i=light"
  fi

  # 5) Dark + traffic-light
  if [ -f "$theme_dir/titlebutton-traffic-gtk3-dark.css" ] \
     && [ -f "$theme_dir/titlebutton-traffic-gtk4-dark.css" ]; then
    i=$((i+1))
    printf " %d) Dark + traffic-light titlebar buttons\n" "$i"
    eval "fn_$i=apply_theme_titlebutton"
    eval "variant_$i=dark"
    eval "gtk_theme_$i=adw-gtk3-dark"
    eval "color_scheme_$i=prefer-dark"
    eval "suffix_$i=dark"
  fi

  [ "$i" -gt 0 ] || {
    printf "\e[31mError:\e[0m no variants detected in '%s'\n" "$theme_dir" >&2
    exit 1
  }

  # prompt
  printf "Enter choice [1-%d]: " "$i"
  read -r choice

  # validate numeric
  case $choice in
    ''|*[!0-9]*|0) 
      printf "\e[31mError:\e[0m invalid choice\n" >&2
      exit 1
    ;;
  esac
  if [ "$choice" -gt "$i" ]; then
    printf "\e[31mError:\e[0m choice out of range\n" >&2
    exit 1
  fi

  # retrieve the chosen parameters
  eval fn=\$fn_"$choice"
  eval variant=\$variant_"$choice"
  eval gtk_theme=\$gtk_theme_"$choice"
  eval color_scheme=\$color_scheme_"$choice"
  eval suffix=\$suffix_"$choice"

  # dispatch
  if [ "$fn" = "apply_theme_auto" ]; then
    $fn
  else
    $fn "$variant" "$gtk_theme" "$color_scheme" "$suffix"
  fi
}

