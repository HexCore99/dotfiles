// A battery outline whose interior tracks the current UPower percentage.
import QtQuick
import ".."
Item {
    id: root
    property int percent: 0
    property bool available: false
    property bool charging: false
    property color color: Settings.foreground
    implicitWidth: Settings.iconSize
    implicitHeight: Settings.iconSize

    // The Lucide outline uses a 24x24 viewBox. Keep the fill inside its body.
    Rectangle {
        x: root.width * 4 / 24
        y: root.height * 8 / 24
        width: root.width * 12 / 24 * Math.max(0, Math.min(100, root.percent)) / 100
        height: root.height * 8 / 24
        radius: 1
        color: root.color
        visible: root.available && !root.charging && root.percent > 0
    }
    SvgIcon {
        anchors.fill: parent
        name: root.charging ? "battery-charging" : "battery"
        color: root.color
    }
}
