#!/bin/sh
# Persistently disable the new bar and return to Waybar. barctl restart reverses it.
set -eu
config="$HOME/.config/hypr"
touch "$config/bar/disabled"
quickshell -p "$config/bar" kill >/dev/null 2>&1 || true
flock -w 5 "${XDG_RUNTIME_DIR:?}/hypr-minimal/bar.lock" true || exit 1
hyprctl dispatch "hl.dsp.exec_cmd('sh ~/.config/hypr/scripts/start-desktop.sh')"
printf '%s\n' 'Waybar restored. Re-enable with: ~/.config/hypr/scripts/barctl restart'
