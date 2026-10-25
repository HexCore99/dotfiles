#!/bin/sh
# A temporary root entry lets the tests import the shared QML singletons.
# The fake networks in WifiFlow.qml never change the actual connection.
set -eu
config="$HOME/.config/hypr"
entry=$(mktemp "$config/.wifi-test-XXXXXX.qml")
trap 'rm -f "$entry"' EXIT HUP INT TERM
cat >"$entry" <<'QML'
import Quickshell
import "bar/tests"
ShellRoot { WifiFlow {} }
QML
timeout 12 quickshell -p "$entry" --no-color
