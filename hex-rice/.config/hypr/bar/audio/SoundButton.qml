import QtQuick
import QtQuick.Controls.Basic
Button {
    id: control
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    property bool selected: false
    font.family: "Noto Sans"
    font.pixelSize: 13
    implicitHeight: 36
    leftPadding: 14; rightPadding: 14
    hoverEnabled: true
    contentItem: Text {
        text: control.text; font: control.font
        color: control.selected ? "#142a25" : "#e5ecea"
        horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
    background: Rectangle {
        radius: 12
        color: control.selected ? "#9fe3cd" : control.hovered ? "#383f43" : "#2b3135"
        border.width: control.visualFocus ? 2 : 0; border.color: "#9fe3cd"
        Behavior on color { ColorAnimation { duration: 140 } }
    }
    scale: down ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 100 } }
    opacity: enabled ? 1 : 0.4
}
