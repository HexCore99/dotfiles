#!/bin/sh
# A separate Quickshell instance owns notifications and both independent popups.
# Hold the runtime lock across exec so login/bar restarts cannot duplicate it.
config="$HOME/.config/hypr"
logs="${XDG_RUNTIME_DIR:?A desktop session is required}/hypr-minimal"
mkdir -p "$logs"
exec 9>"$logs/notifications.lock"
flock -n 9 || exit 0
exec quickshell -p "$config/notification-shell.qml" --no-duplicate --no-color >"$logs/notifications.log" 2>&1
