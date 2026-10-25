// Keyboard-accessible session tile; the allowlisted helper owns system commands.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
AbstractButton {
    id: root
    property string title: ""
    property string subtitle: ""
    property string iconName: ""
    property bool destructive: false
    readonly property bool selected: hovered || activeFocus
    readonly property color accent: destructive ? "#efb2a7" : Settings.powerAccent
    signal activated()
    implicitWidth: Settings.powerTileWidth
    implicitHeight: Settings.powerTileHeight
    hoverEnabled: true
    Accessible.name: title
    scale: down ? 0.96 : 1
    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    onClicked: root.activated()
    Keys.onReturnPressed: root.activated()
    Keys.onEnterPressed: root.activated()
    background: Rectangle {
        radius: 15
        color: root.selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.17) : Settings.powerTileBackground
        border.width: 1
        border.color: root.selected ? Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.6) : "#10ffffff"
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on border.color { ColorAnimation { duration: 160 } }
    }
    contentItem: Column {
        spacing: 5
        topPadding: 12
        SvgIcon {
            anchors.horizontalCenter: parent.horizontalCenter
            width: 21; height: 21
            name: root.iconName
            color: root.selected || root.destructive ? root.accent : Settings.powerText
            scale: root.selected ? 1.10 : 1
            Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: 160 } }
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.title
            font { family: Settings.powerFont; pixelSize: 13; weight: Font.DemiBold }
            color: Settings.powerText
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.subtitle
            font { family: Settings.powerFont; pixelSize: 9 }
            color: Settings.powerMuted
        }
    }
}
