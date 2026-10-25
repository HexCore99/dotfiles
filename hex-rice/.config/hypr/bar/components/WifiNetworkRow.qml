// One real NetworkManager network. Clicking selects it; no hardcoded SSIDs.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../core"
AbstractButton {
    id: row
    required property var network
    implicitHeight: Settings.wifiRowHeight
    padding: Settings.wifiSpacing
    onClicked: WifiState.choose(network)
    enabled: !WifiState.connecting || network.connected
    background: Rectangle {
        radius: Settings.wifiSpacing + 4
        color: row.hovered ? Settings.wifiHover : Settings.wifiCard
        border.width: row.visualFocus ? 1 : 0
        border.color: Settings.wifiAccent
    }
    contentItem: RowLayout {
        spacing: Settings.wifiSpacing
        SvgIcon { name: "wifi"; color: row.network.connected ? Settings.wifiAccent : Settings.wifiMuted }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: row.network.name; textFormat: Text.PlainText
                color: Settings.wifiText; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize
                Layout.fillWidth: true; elide: Text.ElideRight
            }
            Text {
                text: row.network.connected ? "Connected" : row.network.stateChanging ? "Connecting…"
                    : WifiState.securityLabel(row.network) + (row.network.known ? " · Saved" : "")
                color: row.network.connected ? Settings.wifiAccent : Settings.wifiMuted
                font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 2
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }
        SvgIcon { name: row.network.connected ? "wifi" : "lock-keyhole"; visible: row.network.connected || WifiState.isPersonal(row.network); color: Settings.wifiMuted }
    }
}
