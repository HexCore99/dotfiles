// Hide the bar during lock. The helper watches login1 lock hints and
// checks for Hyprlock; Wayland also keeps desktop surfaces behind the lock.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id: root
    property bool locked: false
    property Process watch: Process {
        command: ["python", decodeURIComponent(Qt.resolvedUrl("session-watch.py").toString().replace("file://", ""))]
        running: true
        stdout: SplitParser {
            onRead: data => {
                try { root.locked = JSON.parse(data).locked; } catch (e) { console.warn("Session state:", e); }
            }
        }
        onExited: (code, status) => { console.warn("Session watcher exited:", code); retry.restart(); }
    }
    property Timer retry: Timer { interval: 5000; onTriggered: root.watch.running = true }
}
