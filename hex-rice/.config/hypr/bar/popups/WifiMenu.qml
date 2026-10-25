// Floating Wi-Fi controls beside the status area. This window owns presentation;
// WifiState owns scanning, selection, credentials and connection results.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Networking
import ".."
import "../components"
import "../core"
import "../services"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    visible: WifiState.opened && HyprlandService.screen !== null && !SessionService.locked
    anchors { top: true; right: true }
    margins { top: Settings.topMargin + Settings.height + Settings.panelGap; right: Settings.sideMargin }
    implicitWidth: Settings.wifiWidth
    implicitHeight: Math.min(Settings.wifiHeight, screen ? screen.height - margins.top - 16 : Settings.wifiHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-wifi"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: background; radius: background.radius }
    HyprlandFocusGrab { windows: [window]; active: window.visible; onCleared: WifiState.close() }
    onVisibleChanged: { if (visible) background.forceActiveFocus(); }
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Settings.wifiRadius
        color: Qt.rgba(Settings.wifiBackground.r, Settings.wifiBackground.g, Settings.wifiBackground.b, Math.max(0, Math.min(1, Settings.wifiBackgroundOpacity)))
        border.width: 1; border.color: Settings.wifiHover
        focus: true
        Keys.onEscapePressed: WifiState.close()
        ColumnLayout {
            anchors.fill: parent; anchors.margins: Settings.wifiPadding
            spacing: Settings.wifiSpacing
            Item {
                Layout.fillWidth: true
                implicitHeight: title.implicitHeight
                Column {
                    id: title
                    anchors.left: parent.left
                    spacing: 0
                    Text { text: "Wi-Fi"; color: Settings.wifiText; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTitleSize; font.bold: true }
                    Text { text: !WifiState.available ? "No Wi-Fi adapter" : !WifiState.hardwareEnabled ? "Hardware switch is off" : WifiState.enabled ? "Wireless connections" : "Wi-Fi is off"; color: Settings.wifiMuted; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 2 }
                }
                Switch {
                    id: radio
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: WifiState.available && WifiState.hardwareEnabled
                    checked: WifiState.enabled
                    onToggled: WifiState.setEnabled(checked)
                    implicitWidth: Settings.wifiSwitchWidth; implicitHeight: Settings.wifiSwitchHeight; padding: 0
                    indicator: Rectangle {
                        implicitWidth: Settings.wifiSwitchWidth; implicitHeight: Settings.wifiSwitchHeight; radius: height / 2
                        color: radio.checked ? Settings.wifiAccent : Settings.wifiHover
                        border.width: radio.visualFocus ? 1 : 0; border.color: Settings.wifiText
                        Rectangle { width: parent.height - 8; height: width; radius: width / 2; x: radio.checked ? parent.width - width - 4 : 4; anchors.verticalCenter: parent.verticalCenter; color: "white" }
                    }
                }
            }
            Loader {
                active: WifiState.enabled && WifiState.connected !== null
                visible: active
                Layout.fillWidth: true
                sourceComponent: WifiNetworkRow { network: WifiState.connected }
            }
            Text {
                visible: WifiState.error !== "" || WifiState.message !== "" || WifiState.connecting
                text: WifiState.error || (WifiState.connecting ? "Connecting to " + (WifiState.selected ? WifiState.selected.name : "network") + "…" : WifiState.message)
                textFormat: Text.PlainText; wrapMode: Text.Wrap; Layout.fillWidth: true
                color: WifiState.error ? Settings.warning : Settings.wifiAccent
                font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 1
            }
            WifiPasswordForm { visible: WifiState.enabled && WifiState.passwordRequired; Layout.fillWidth: true }
            Text { visible: WifiState.enabled; text: "Available networks"; color: Settings.wifiMuted; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 1 }
            ScrollView {
                visible: WifiState.enabled
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; contentWidth: availableWidth
                Column {
                    width: parent.width; spacing: Settings.wifiSpacing
                    Repeater {
                        model: WifiState.others
                        WifiNetworkRow { required property var modelData; network: modelData; width: parent.width }
                    }
                    Text { visible: WifiState.others.length === 0; text: "No other networks found. Scanning continues while this panel is open."; color: Settings.wifiMuted; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 1; width: parent.width; wrapMode: Text.Wrap }
                }
            }
            Item { visible: !WifiState.enabled; Layout.fillWidth: true; Layout.fillHeight: true }
            WifiButton { text: "Advanced setup…"; Layout.fillWidth: true; onClicked: { WifiState.close(); Actions.run("network-advanced"); } }
        }
    }
}
