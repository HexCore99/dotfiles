// Real device identity/state comes from BlueZ, not cached command-line output.
import QtQuick
import QtQuick.Layouts
import ".."
import "../core"
Rectangle {
    id: row
    required property var device
    implicitHeight: Settings.bluetoothRowHeight
    color: Settings.bluetoothCard
    radius: Settings.bluetoothSpacing + 4
    RowLayout {
        anchors.fill: parent; anchors.margins: Settings.bluetoothSpacing
        spacing: Settings.bluetoothSpacing
        SvgIcon { name: "bluetooth"; color: row.device.connected ? Settings.bluetoothAccent : Settings.bluetoothMuted }
        ColumnLayout {
            Layout.fillWidth: true; spacing: 3
            Text {
                text: row.device.name || row.device.address
                textFormat: Text.PlainText; elide: Text.ElideRight
                color: Settings.bluetoothText; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize
                Layout.fillWidth: true
            }
            Text {
                text: row.device.connected ? "Connected" + (row.device.batteryAvailable ? " · " + Math.round(row.device.battery * 100) + "% battery" : "")
                    : row.device.pairing ? "Pairing…" : row.device.paired ? "Paired" : row.device.address
                color: row.device.connected ? Settings.bluetoothAccent : Settings.bluetoothMuted
                font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 3
                Layout.fillWidth: true; elide: Text.ElideRight
            }
        }
        BluetoothButton {
            text: row.device.connected ? "Disconnect" : row.device.paired ? "Connect" : "Pair"
            primary: !row.device.paired
            enabled: BluetoothState.ready && !BluetoothState.busy
            onClicked: BluetoothState.choose(row.device)
        }
    }
}
