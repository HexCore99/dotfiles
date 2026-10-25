#!/bin/sh
# Small, independent components. Logs are available in the runtime directory.
config="$HOME/.config/hypr"
logs="${XDG_RUNTIME_DIR:-/tmp}/hypr-minimal"
mkdir -p "$logs"

start_once() {
    name="$1"
    shift
    command -v "$1" >/dev/null 2>&1 || return 0
    pgrep -u "$(id -u)" -x "$name" >/dev/null && return 0
    "$@" >"$logs/$name.log" 2>&1 &
}

# Independent Quickshell notification daemon; bar restarts preserve its history.
sh "$config/scripts/start-notifications.sh" >"$logs/notification-session.log" 2>&1 &
# The bar supervisor restores Waybar only if the Quickshell bar cannot run.
if command -v quickshell >/dev/null && [ ! -f "$config/bar/disabled" ]; then
    sh "$config/scripts/start-bar.sh" >"$logs/bar-session.log" 2>&1 &
else
    start_once waybar waybar -c "$config/waybar/config.jsonc" -s "$config/waybar/style.css"
fi
start_once hypridle hypridle -c "$config/hypridle.conf"

# Restore only a saved selection. With no selection, leave the desktop as-is.
# The helper reuses an existing Hyprpaper and serializes simultaneous requests.
python3 -B "$config/bar/services/wallpaper_backend.py" restore >"$logs/wallpaper-restore.log" 2>&1 &

# Authentication prompts and saved secrets.
start_once polkit-gnome-au /usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1
start_once gnome-keyring-d gnome-keyring-daemon --start --components=secrets

# Keep clipboard history independent of the desktop shell.
pgrep -u "$(id -u)" -f '^wl-paste --type text --watch cliphist store$' >/dev/null ||
    wl-paste --type text --watch cliphist store >"$logs/clipboard-text.log" 2>&1 &
pgrep -u "$(id -u)" -f '^wl-paste --type image --watch cliphist store$' >/dev/null ||
    wl-paste --type image --watch cliphist store >"$logs/clipboard-image.log" 2>&1 &
