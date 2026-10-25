// Native Bluetooth overlay: discovery, connected/paired devices and pairing.
// Right-click still toggles adapter power.
import QtQuick
import ".."
import "../core"
import "../components"
import "../services"
BarButton {
    icon: BluetoothService.enabled ? "bluetooth" : "bluetooth-off"
    foreground: BluetoothService.enabled ? Settings.foreground : Settings.muted
    hint: BluetoothService.detail + " · click to manage; right-click to toggle"
    onClicked: BluetoothState.toggle()
    onRightClicked: BluetoothService.toggle()
}
