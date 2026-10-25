// BlueZ discovery and operation state; pairing prompts come from a private agent.
pragma Singleton
import QtQuick
import Quickshell.Io
import ".."
import "../services"
QtObject {
    id: root
    property bool opened: false
    property bool ready: false
    property bool busy: false
    property string operation: ""
    property var selected: null
    property var prompt: null
    property string error: ""
    property string message: ""
    property int requestId: 0
    signal clearCode()
    readonly property var adapter: BluetoothService.adapter
    readonly property bool enabled: BluetoothService.enabled
    readonly property var devices: adapter ? adapter.devices.values : []
    readonly property var connected: devices.filter(d => d.connected)
    readonly property var saved: devices.filter(d => !d.connected && d.paired)
    readonly property var nearby: devices.filter(d => !d.connected && !d.paired)
    function send(packet): void { agent.write(JSON.stringify(packet) + "\n"); }
    function toggle(): void {
        SoundState.close();
        if (opened) close();
        else { WallpaperState.close(); WifiState.close(); PowerState.close(); error = ""; message = ""; opened = true; }
    }
    function close(): void {
        // Closing cancels active authentication rather than leaving a hidden prompt.
        if (prompt || (busy && operation === "pair")) send({action: "cancel"});
        prompt = null; clearCode(); opened = false;
    }
    function setEnabled(value: bool): void {
        if (!adapter) return;
        if (!value && busy) send({action: "cancel"});
        adapter.enabled = value;
        error = ""; message = ""; prompt = null; clearCode();
    }
    function operate(device, action): void {
        if (busy || !ready) return;
        if (device.blocked) { error = "This device is blocked in Bluetooth settings."; return; }
        selected = device; operation = action; busy = true; error = ""; message = "";
        send({id: ++requestId, action: action, path: device.dbusPath});
    }
    function choose(device): void { operate(device, device.connected ? "disconnect" : device.paired ? "connect" : "pair"); }
    function cancelPairing(): void { send({action: "cancel"}); prompt = null; clearCode(); }
    function respond(accepted, code): void {
        send({action: "reply", accepted: accepted, value: code || ""});
        clearCode();
    }
    function event(data): void {
        if (data.event === "ready") { ready = data.ready; error = data.error || ""; }
        else if (data.event === "prompt") { prompt = data; opened = true; }
        else if (data.event === "prompt-clear") { prompt = null; clearCode(); }
        else if (data.event === "validation") error = data.error;
        else if (data.event === "result" && data.id === requestId) {
            busy = false; prompt = null; clearCode();
            error = data.ok ? "" : "Bluetooth: " + data.error.replace(/([a-z])([A-Z])/g, "$1 $2");
            message = data.ok ? data.action === "disconnect" ? "Device disconnected" : "Device connected" : "";
        }
    }
    property Process agent: Process {
        command: ["python", "-B", decodeURIComponent(Qt.resolvedUrl("../services/bluetooth-agent.py").toString().replace("file://", ""))]
        running: true
        stdinEnabled: true
        stdout: SplitParser { onRead: line => { try { root.event(JSON.parse(line)); } catch (e) { root.error = "Could not read Bluetooth status."; } } }
        onExited: { root.ready = false; root.busy = false; root.prompt = null; root.clearCode(); retry.restart(); }
    }
    property Timer retry: Timer { interval: 5000; onTriggered: root.agent.running = true }
    // Only this adapter is scanned; closing the panel stops our discovery request.
    property Binding scan: Binding { target: root.adapter; property: "discovering"; value: root.opened && root.enabled; when: root.adapter !== null }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections fullscreen: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
}
