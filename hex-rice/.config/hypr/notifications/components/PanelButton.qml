// Shared plain, keyboard-accessible button. No transitions or tooltip overlays.
import QtQuick
import QtQuick.Controls.Basic
import "../../bar"
Button {
    id: button
    property bool selected: false
    implicitHeight: Settings.panelButtonHeight
    implicitWidth: label.implicitWidth + Settings.panelPadding
    padding: 6
    contentItem: Text {
        id: label
        text: button.text
        color: button.selected ? Settings.panelBackground : Settings.panelText
        font.family: Settings.font
        font.pixelSize: Settings.panelFontSize
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        textFormat: Text.PlainText
    }
    background: Rectangle {
        color: button.selected ? Settings.panelAccent : button.hovered ? Settings.panelHover : Settings.panelCard
        radius: Settings.panelRadius / 2
        border.width: button.visualFocus ? 1 : 0
        border.color: Settings.panelAccent
    }
}
