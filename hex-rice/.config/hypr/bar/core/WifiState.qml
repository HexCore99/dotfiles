// Wi-Fi menu state and NetworkManager operations. Passwords go directly through
// Quickshell's D-Bus API; they are never command arguments or diagnostic output.
pragma Singleton
import QtQuick
import Quickshell.Networking
import ".."
import "../services"
QtObject {
    id: root
    property bool opened: false
    property var selected: null
    property bool passwordRequired: false
    property bool connecting: false
    property string error: ""
    property string message: ""
    signal clearPassword()
    readonly property var devices: Networking.devices.values.filter(d => d.type === DeviceType.Wifi)
    readonly property bool available: devices.length > 0
    readonly property bool hardwareEnabled: Networking.wifiHardwareEnabled
    readonly property bool enabled: Networking.wifiEnabled
    readonly property var networks: {
        // Keep the strongest AP per SSID/security pair, preferring a connected AP.
        const list = [];
        devices.forEach(d => d.networks.values.forEach(n => { if (n.name !== "") list.push(n); }));
        list.sort((a,b) => Number(b.connected) - Number(a.connected) || b.signalStrength - a.signalStrength);
        return list.filter((n,i) => list.findIndex(other => other.name === n.name && other.security === n.security) === i);
    }
    readonly property var connected: networks.find(n => n.connected) || null
    readonly property var others: networks.filter(n => !n.connected)
    function isPersonal(network): bool {
        return [WifiSecurityType.WpaPsk, WifiSecurityType.Wpa2Psk, WifiSecurityType.Sae].includes(network.security);
    }
    function securityLabel(network): string {
        if (network.security === WifiSecurityType.Open) return "Open network";
        if (network.security === WifiSecurityType.Owe) return "Enhanced open";
        return WifiSecurityType.toString(network.security).replace(/([a-z])([A-Z])/g, "$1 $2");
    }
    function toggle(): void {
        SoundState.close();
        if (opened) close();
        else { WallpaperState.close(); BluetoothState.close(); PowerState.close(); reset(); opened = true; }
    }
    function close(): void {
        opened = false;
        // Clear typed secrets on every dismissal; background connections may finish.
        clearPassword();
        passwordRequired = false;
    }
    function reset(): void {
        clearPassword(); selected = null; passwordRequired = false;
        connecting = false; error = ""; message = "";
    }
    function setEnabled(value: bool): void {
        if (!hardwareEnabled && value) { error = "Wi-Fi is blocked by the hardware switch."; return; }
        reset(); Networking.wifiEnabled = value;
    }
    function choose(network): void {
        if (connecting || network.connected) return;
        reset(); selected = network;
        if (!network.known && isPersonal(network)) {
            passwordRequired = true;
        } else if (!network.known && ![WifiSecurityType.Open, WifiSecurityType.Owe].includes(network.security)) {
            error = "This network needs advanced authentication settings.";
        } else {
            // Saved connections reuse NetworkManager's stored credentials.
            connecting = true; network.connect();
        }
    }
    function submit(password: string): void {
        if (!selected || connecting || !passwordRequired) return;
        if (!password.length) { error = "Enter the Wi-Fi password."; return; }
        error = ""; connecting = true;
        selected.connectWithPsk(password);
        clearPassword();
    }
    function failed(reason): void {
        connecting = false; message = "";
        if (selected && isPersonal(selected) && [ConnectionFailReason.NoSecrets, ConnectionFailReason.WifiAuthTimeout].includes(reason)) {
            passwordRequired = true;
            error = "Could not authenticate. Check the password and try again.";
        } else {
            error = "Connection failed: " + ConnectionFailReason.toString(reason);
        }
    }
    property Connections connection: Connections {
        target: root.selected || null
        ignoreUnknownSignals: true
        function onConnectionFailed(reason) { root.failed(reason); }
        function onConnectedChanged() {
            if (root.selected && root.selected.connected) {
                root.connecting = false; root.passwordRequired = false;
                root.error = ""; root.message = "Connected to " + root.selected.name;
                root.clearPassword();
            }
        }
    }
    // Scan only while the panel is visible; NetworkManager controls scan frequency.
    property Instantiator scanning: Instantiator {
        model: root.devices
        delegate: QtObject {
            required property var modelData
            property Binding scan: Binding { target: modelData; property: "scannerEnabled"; value: root.opened && root.enabled }
        }
    }
    property Timer timeout: Timer {
        interval: Settings.wifiConnectTimeout
        running: root.connecting
        onTriggered: { root.connecting = false; root.error = "Connection timed out. Please try again."; }
    }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections fullscreen: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
    onEnabledChanged: { if (!enabled) reset(); }
}
