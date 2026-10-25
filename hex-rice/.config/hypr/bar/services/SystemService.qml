// Receive CPU and memory samples from one small long-running Python helper.
// JSON arrives every two seconds; no shell command is spawned per sample.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id: root
    property int cpu: 0
    property int memory: 0
    property Process sampler: Process {
        command: ["python", decodeURIComponent(Qt.resolvedUrl("system-stats.py").toString().replace("file://", ""))]
        running: true
        stdout: SplitParser { onRead: data => { try { const s = JSON.parse(data); root.cpu = s.cpu; root.memory = s.memory; } catch (e) { console.warn(e); } } }
        onExited: retry.restart()
    }
    property Timer retry: Timer { interval: 5000; onTriggered: root.sampler.running = true }
}
