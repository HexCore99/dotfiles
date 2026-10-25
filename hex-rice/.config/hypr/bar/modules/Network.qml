// Icon only: the native Wi-Fi overlay owns scanning, selection and passwords.
import QtQuick
import ".."
import "../core"
import "../components"
import "../services"
BarButton {
    // Ethernet has a different symbol; disconnected Wi-Fi gets a crossed icon.
    icon: !NetworkService.connected ? "wifi-off" : NetworkService.network && NetworkService.network.signalStrength !== undefined ? "wifi" : "ethernet-port"
    foreground: NetworkService.connected ? Settings.foreground : Settings.muted
    hint: NetworkService.label + " · click for connections; right-click to toggle Wi-Fi"
    onClicked: WifiState.toggle()
    onRightClicked: NetworkService.toggleWifi()
}
