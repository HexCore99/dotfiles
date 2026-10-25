#!/bin/sh
# Supervise this Quickshell bar only. Other Quickshell configurations are untouched.
# A file lock prevents two copies at login or when start-desktop is called again.
config="$HOME/.config/hypr"
logs="${XDG_RUNTIME_DIR:?A desktop session is required}/hypr-minimal"
mkdir -p "$logs"
exec 9>"$logs/bar.lock"
flock -n 9 || exit 0
[ ! -f "$config/bar/disabled" ] || exit 0

fallback() {
    # Keep a usable bar if Quickshell is missing or exits. Close the supervisor's
    # lock in the child, otherwise a future restart could stay locked out.
    if ! pgrep -u "$(id -u)" -x waybar >/dev/null; then
        waybar -c "$config/waybar/config.jsonc" -s "$config/waybar/style.css" >"$logs/waybar.log" 2>&1 9>&- &
    fi
}
if ! command -v quickshell >/dev/null; then
    echo 'Quickshell missing; using Waybar.' >&2
    fallback
    exit 1
fi
quickshell -p "$config/bar" --no-duplicate --no-color >"$logs/bar.log" 2>&1 &
bar_pid=$!
# Stop our own child cleanly if the supervisor receives a normal shutdown signal.
trap 'kill "$bar_pid" 2>/dev/null; wait "$bar_pid" 2>/dev/null; fallback; exit 0' INT TERM

# Do not remove the working fallback until the new bar answers its IPC endpoint.
ready=0
attempt=0
while [ "$attempt" -lt 40 ]; do
    kill -0 "$bar_pid" 2>/dev/null || break
    if quickshell -p "$config/bar" ipc call bar status >/dev/null 2>&1; then
        ready=1
        break
    fi
    attempt=$((attempt + 1))
    sleep 0.15
done
if [ "$ready" -ne 1 ]; then
    echo 'Flat bar failed to load; restoring Waybar. Check bar.log.' >&2
    kill "$bar_pid" 2>/dev/null || true
    wait "$bar_pid" 2>/dev/null || true
    fallback
    exit 1
fi
pkill -u "$(id -u)" -x waybar 2>/dev/null || true
printf '%s\n' 'Quickshell flat bar ready.'
wait "$bar_pid"
result=$?
printf 'Bar exited (%s); restoring Waybar.\n' "$result" >&2
fallback
exit "$result"
