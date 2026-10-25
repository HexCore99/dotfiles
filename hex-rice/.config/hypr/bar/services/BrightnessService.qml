// Backlight adapter. Read actual hardware values on opening and while visible.
// Rapid slider moves are coalesced, with only one brightnessctl write at a time.
pragma Singleton
import QtQuick
import Quickshell.Io
import ".."
QtObject {
    id: root
    property bool watching: false
    property bool available: false
    property int percent: 0
    property int pending: -1
    property string error: ""
    function refresh(): void { if (!query.running && !setter.running && pending < 0) query.running = true; }
    function setPercent(value: real): void {
        if (!available || !Number.isFinite(value)) return;
        pending = Math.round(Math.max(Settings.brightnessMinimum, Math.min(100, value)));
        percent = pending;
        debounce.restart();
    }
    function apply(): void {
        if (pending < 0 || setter.running) return;
        const value = pending; pending = -1;
        setter.command = ["brightnessctl", "-c", "backlight", "set", value + "%"];
        setter.running = true;
    }
    property Process query: Process {
        command: ["brightnessctl", "-c", "backlight", "-m"]
        stdout: SplitParser {
            onRead: line => {
                const fields = line.split(",");
                const current = Number(fields[2]), maximum = Number(fields[4]);
                if (fields.length < 5 || !Number.isFinite(current) || !Number.isFinite(maximum) || maximum <= 0) return;
                root.available = true;
                // A query started before a drag must not overwrite its new target.
                if (!setter.running && root.pending < 0) root.percent = Math.round(current / maximum * 100);
            }
        }
        onExited: (code, status) => { if (code !== 0) { root.available = false; root.error = "No accessible screen backlight."; } }
    }
    property Process setter: Process {
        onExited: (code, status) => {
            root.error = code === 0 ? "" : "Could not change screen brightness.";
            if (root.pending >= 0) root.apply(); else root.refresh();
        }
    }
    property Timer debounce: Timer { interval: 45; onTriggered: root.apply() }
    property Timer poll: Timer { interval: 1000; running: root.watching; repeat: true; onTriggered: root.refresh() }
    Component.onCompleted: refresh()
}
