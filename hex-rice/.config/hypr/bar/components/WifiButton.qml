// Shared Wi-Fi panel button; styling constants live in Settings.qml.
import QtQuick
import QtQuick.Controls.Basic
import ".."
Button {
    id: control
    property bool primary: false
    implicitHeight: Settings.wifiButtonHeight
    implicitWidth: label.implicitWidth + Settings.wifiPadding * 2
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        id: label
        text: control.text; textFormat: Text.PlainText
        color: control.primary ? Settings.wifiBackground : Settings.wifiText
        font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        radius: Settings.wifiSpacing
        color: control.primary ? Settings.wifiAccent : control.hovered ? Settings.wifiHover : Settings.wifiCard
        border.width: control.visualFocus ? 1 : 0
        border.color: Settings.wifiAccent
    }
}
