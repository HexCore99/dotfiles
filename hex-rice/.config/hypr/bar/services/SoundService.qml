// Device, stream and card controls. Only poll while the panel is open.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
QtObject {
    id: root
    property bool watching: false
    property bool loading: false
    property string error: ""
    property var data: ({outputs: [], inputs: [], playback: [], recording: [], cards: []})
    property var queue: []
    readonly property bool busy: setter.running || queue.length > 0
    function refresh() { if (!query.running && !busy) { loading = true; query.running = true; } }
    function change(op, item, value) {
        const next = {op: op, kind: item.kind, id: item.id, value: value};
        // Coalesce slider traffic without losing unrelated device actions.
        queue = queue.filter(q => !(q.op === op && q.kind === item.kind && q.id === item.id)).concat([next]);
        debounce.restart();
    }
    function apply() {
        if (setter.running || !queue.length) return;
        const next = queue[0]; queue = queue.slice(1);
        setter.command = ["python3", Quickshell.shellPath("audio/backend.py"), JSON.stringify(next)];
        setter.running = true;
    }
    property Process query: Process {
        command: ["python3", Quickshell.shellPath("audio/backend.py")]
        stdout: StdioCollector { onStreamFinished: {
            try {
                const result = JSON.parse(text);
                if (result.error) root.error = result.error;
                else if (!root.busy) { root.data = result; }
            } catch(e) { root.error = "Could not read the audio server."; }
        } }
        onExited: root.loading = false
    }
    property Process setter: Process {
        stdout: StdioCollector { onStreamFinished: {
            try { root.error = JSON.parse(text).error || ""; }
            catch(e) { root.error = "Could not apply the audio setting."; }
        } }
        onExited: { if (root.queue.length) root.apply(); else root.refresh(); }
    }
    property Timer debounce: Timer { interval: 65; onTriggered: root.apply() }
    property Timer poll: Timer { interval: 1500; running: root.watching; repeat: true; onTriggered: root.refresh() }
    onWatchingChanged: if (watching) refresh()
}
