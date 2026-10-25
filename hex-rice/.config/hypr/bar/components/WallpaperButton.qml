// Compact panel actions. No tooltips, transitions or animated Controls style.
import QtQuick
import QtQuick.Controls.Basic
import ".."
Button {
    id: control
    property string iconName: ""
    implicitHeight: Settings.wallpaperButtonHeight
    implicitWidth: iconName ? implicitHeight : label.implicitWidth + Settings.wallpaperPadding
    opacity: enabled ? 1 : Settings.wallpaperDisabledOpacity
    padding: 0
    contentItem: Item {
        Text {
            id: label
            anchors.centerIn: parent
            visible: control.iconName === ""
            text: control.text; textFormat: Text.PlainText
            color: Settings.wallpaperText
            font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize
        }
        SvgIcon {
            anchors.centerIn: parent
            visible: control.iconName !== ""
            name: control.iconName; color: Settings.wallpaperText
            width: Settings.wallpaperIconSize; height: width
        }
    }
    background: Rectangle {
        radius: Settings.wallpaperCardRadius
        color: control.hovered ? Settings.wallpaperHover : Settings.wallpaperCard
        border.width: control.visualFocus ? 2 : 1
        border.color: control.visualFocus ? Settings.wallpaperAccent : Settings.wallpaperBorder
    }
    Accessible.name: text
}
