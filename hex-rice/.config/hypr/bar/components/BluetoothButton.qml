// Shared Bluetooth button; all appearance constants stay in Settings.qml.
import QtQuick
import QtQuick.Controls.Basic
import ".."
Button {
    id: control
    property bool primary: false
    implicitHeight: Settings.wifiButtonHeight
    implicitWidth: label.implicitWidth + Settings.bluetoothPadding
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        id: label
        text: control.text; textFormat: Text.PlainText
        color: control.primary ? Settings.bluetoothBackground : Settings.bluetoothText
        font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 1
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: control.primary ? Settings.bluetoothAccent : control.hovered ? Qt.lighter(Settings.bluetoothHover, 1.15) : Settings.bluetoothHover
        radius: Settings.bluetoothSpacing
        border.width: control.visualFocus ? 1 : 0
        border.color: Settings.bluetoothAccent
    }
}
