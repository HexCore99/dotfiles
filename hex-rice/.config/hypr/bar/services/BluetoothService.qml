// Read the real BlueZ adapter and connected devices. Right-click changes
// adapter power; BluetoothState and its private agent manage pairing.
pragma Singleton
import QtQuick
import Quickshell.Bluetooth
QtObject {
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: adapter !== null
    readonly property bool enabled: adapter ? adapter.enabled : false
    readonly property var connected: Bluetooth.devices.values.filter(d => d.connected)
    readonly property string detail: !available ? "No Bluetooth adapter" : !enabled ? "Bluetooth off" : connected.length ? connected.map(d => d.name).join(", ") : "Bluetooth on · no connected devices"
    function toggle(): void { if (adapter) adapter.enabled = !adapter.enabled; }
}
