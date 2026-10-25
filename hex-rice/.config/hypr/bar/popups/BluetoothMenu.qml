// Floating Bluetooth overlay matching Wi-Fi. Agent/authentication logic stays
// in BluetoothState.qml and bluetooth-agent.py, not in this layout file.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../components"
import "../core"
import "../services"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    visible: BluetoothState.opened && HyprlandService.screen !== null && !SessionService.locked
    anchors { top: true; right: true }
    margins { top: Settings.topMargin + Settings.height + Settings.panelGap; right: Settings.sideMargin }
    implicitWidth: Settings.bluetoothWidth
    implicitHeight: Math.min(Settings.bluetoothHeight, screen ? screen.height - margins.top - 16 : Settings.bluetoothHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-bluetooth"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: background; radius: background.radius }
    HyprlandFocusGrab { windows: [window]; active: window.visible; onCleared: BluetoothState.close() }
    onVisibleChanged: { if (visible) background.forceActiveFocus(); }
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Settings.bluetoothRadius
        color: Qt.rgba(Settings.bluetoothBackground.r, Settings.bluetoothBackground.g, Settings.bluetoothBackground.b, Math.max(0, Math.min(1, Settings.bluetoothBackgroundOpacity)))
        border.width: 1; border.color: Settings.bluetoothHover
        focus: true
        Keys.onEscapePressed: BluetoothState.close()
        ColumnLayout {
            anchors.fill: parent; anchors.margins: Settings.bluetoothPadding
            spacing: Settings.bluetoothSpacing
            Item {
                Layout.fillWidth: true; implicitHeight: title.implicitHeight
                Column {
                    id: title
                    Text { text: "Bluetooth"; color: Settings.bluetoothText; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTitleSize; font.bold: true }
                    Text { text: !BluetoothState.adapter ? "No Bluetooth adapter" : BluetoothState.enabled ? "Find and connect devices" : "Bluetooth is off"; color: Settings.bluetoothMuted; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 2 }
                }
                Switch {
                    id: radio
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    enabled: BluetoothState.adapter !== null
                    checked: BluetoothState.enabled
                    onToggled: BluetoothState.setEnabled(checked)
                    implicitWidth: Settings.wifiSwitchWidth; implicitHeight: Settings.wifiSwitchHeight; padding: 0
                    indicator: Rectangle {
                        implicitWidth: Settings.wifiSwitchWidth; implicitHeight: Settings.wifiSwitchHeight; radius: height / 2
                        color: radio.checked ? Settings.bluetoothAccent : Settings.bluetoothHover
                        border.width: radio.visualFocus ? 1 : 0; border.color: Settings.bluetoothText
                        Rectangle { width: parent.height - 8; height: width; radius: width / 2; x: radio.checked ? parent.width - width - 4 : 4; anchors.verticalCenter: parent.verticalCenter; color: "white" }
                    }
                }
            }
            Text {
                visible: BluetoothState.error !== "" || BluetoothState.message !== "" || BluetoothState.busy
                text: BluetoothState.error || (BluetoothState.busy ? "Working with " + (BluetoothState.selected ? BluetoothState.selected.name : "device") + "…" : BluetoothState.message)
                textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true
                color: BluetoothState.error ? Settings.warning : Settings.bluetoothAccent
                font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 1
            }
            BluetoothPairingForm { visible: BluetoothState.prompt !== null; Layout.fillWidth: true }
            ScrollView {
                visible: BluetoothState.enabled && BluetoothState.prompt === null
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: availableWidth
                Column {
                    width: parent.width; spacing: Settings.bluetoothSpacing * 2
                    BluetoothDeviceSection { title: "Connected"; devices: BluetoothState.connected; width: parent.width }
                    BluetoothDeviceSection { title: "Paired devices"; devices: BluetoothState.saved; width: parent.width }
                    BluetoothDeviceSection { title: "Nearby devices"; devices: BluetoothState.nearby; width: parent.width }
                    Text {
                        text: "Searching for devices… Put your device in pairing mode to make it appear."
                        color: Settings.bluetoothMuted; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 2
                        width: parent.width; wrapMode: Text.Wrap
                    }
                }
            }
            Item { visible: !BluetoothState.enabled || BluetoothState.prompt !== null; Layout.fillWidth: true; Layout.fillHeight: true }
            BluetoothButton { visible: BluetoothState.busy && BluetoothState.prompt === null; text: "Cancel pairing"; enabled: BluetoothState.operation === "pair"; Layout.fillWidth: true; onClicked: BluetoothState.cancelPairing() }
        }
    }
}
