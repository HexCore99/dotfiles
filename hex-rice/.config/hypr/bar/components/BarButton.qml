// Shared hit area for one bar item. Text is small, but the full bar height
// responds to clicks and scrolls. Modules supply the label, tooltip, and actions.
import QtQuick
import QtQuick.Controls.Basic
import ".."
Item {
    id: root
    property string text: ""
    property string icon: "" // Local SVG name; empty for text-only items.
    property Component iconComponent: null // Optional custom icon with the same hit area.
    property string hint: ""
    property int textSize: Settings.fontSize // A module can override this (e.g. the clock).
    property color foreground: Settings.foreground
    property int horizontalPadding: 6
    implicitWidth: content.implicitWidth + horizontalPadding * 2
    implicitHeight: Settings.height - 2
    signal clicked()
    signal rightClicked()
    signal scrolled(bool up)
    // Rectangle { anchors.fill: parent; color: mouse.containsMouse ? Settings.hover : "transparent" }
    Rectangle {
        anchors.fill: parent
        radius: Settings.barRadius
        color: mouse.containsMouse ? Settings.hover : "transparent"
    }
    // A real SVG and an ordinary text label share one centered row.
    // Hiding either item also removes its space from this Row.
    Row {
        id: content
        anchors.centerIn: parent
        spacing: Settings.iconSpacing
        Loader {
            visible: root.icon !== "" || root.iconComponent !== null
            sourceComponent: root.iconComponent || defaultIcon
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.text !== ""
            text: root.text
            anchors.verticalCenter: parent.verticalCenter
            // Native rendering keeps the small monospace label crisp.
            renderType: Text.NativeRendering
            font.hintingPreference: Font.PreferFullHinting
            textFormat: Text.PlainText
            color: root.foreground
            font.family: Settings.font
            font.pixelSize: root.textSize
            font.weight: Settings.fontWeight
        }
    }
    Component {
        id: defaultIcon
        SvgIcon { name: root.icon; color: root.foreground }
    }
    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        cursorShape: Qt.PointingHandCursor
        onClicked: event => { if (event.button === Qt.RightButton) root.rightClicked(); else root.clicked(); }
        onWheel: event => { root.scrolled(event.angleDelta.y > 0); event.accepted = true; }
    }
    // Hover overlays are controlled centrally in Settings.qml.
    ToolTip {
        visible: Settings.showTooltips && mouse.containsMouse && root.hint !== ""
        delay: 700
        text: root.hint
        enter: null
        exit: null
        background: Rectangle { color: Settings.background; border.color: Settings.border; border.width: 1 }
        contentItem: Text { text: root.hint; color: Settings.foreground; font.family: Settings.font; font.pixelSize: Settings.fontSize }
    }
}
