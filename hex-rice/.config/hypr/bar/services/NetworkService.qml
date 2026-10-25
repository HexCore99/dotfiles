// Read NetworkManager through Quickshell: prefer a connected device and
// its connected network. Show real Wi-Fi signal strength or LAN for Ethernet.
pragma Singleton
import QtQuick
import Quickshell.Networking
QtObject {
    readonly property var device: Networking.devices.values.find(d => d.connected) || null
    readonly property var network: device ? device.networks.values.find(n => n.connected) : null
    readonly property int signal: network && network.signalStrength !== undefined ? Math.round(network.signalStrength * 100) : 0
    function toggleWifi(): void { Networking.wifiEnabled = !Networking.wifiEnabled; }
    readonly property bool connected: device !== null
    readonly property string label: network ? network.name : connected ? "Connected" : "Offline"
    readonly property string detail: connected ? device.name : "No network connection"
}
