// Rounded notification-only pill. Calendar buttons retain their own styling.
import QtQuick
import QtQuick.Controls.Basic
import "../../bar"
import "../services"
Button {
    id: control
    property bool outlined: false
    property bool accent: false
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    scale: down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    implicitHeight: Settings.notificationControlHeight
    implicitWidth: label.implicitWidth + Settings.notificationSpacing * 3
    opacity: enabled ? 1 : 0.45
    contentItem: Text {
        id: label
        text: control.text
        textFormat: Text.PlainText
        color: control.accent ? NotificationTheme.accentText : NotificationTheme.text
        font.family: Settings.notificationFont
        font.pixelSize: Settings.notificationTextSize - 1
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
    background: Rectangle {
        color: control.accent ? NotificationTheme.accent : control.hovered ? NotificationTheme.hover : control.outlined ? "transparent" : NotificationTheme.control
        Behavior on color { ColorAnimation { duration: 130 } }
        radius: control.outlined ? Settings.notificationSpacing : height / 2
        border.width: control.outlined || control.visualFocus ? 1 : 0
        border.color: control.visualFocus ? NotificationTheme.accent : NotificationTheme.control
    }
}
