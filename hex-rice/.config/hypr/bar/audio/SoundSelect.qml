pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
ComboBox {
    id: control
    HoverHandler { cursorShape: Qt.PointingHandCursor }
    property string selectedName: ""
    textRole: "label"
    valueRole: "name"
    implicitHeight: 40
    font.family: "Noto Sans"; font.pixelSize: 13
    currentIndex: {
        for (let i = 0; i < count; i++) if (valueAt(i) === selectedName) return i;
        return -1;
    }
    contentItem: Text {
        text: control.displayText; color: "#e5ecea"; font: control.font
        verticalAlignment: Text.AlignVCenter; elide: Text.ElideRight
        leftPadding: 12; rightPadding: 30
    }
    background: Rectangle {
        radius: 10; color: control.hovered ? "#363e42" : "#20272b"
        border.width: 1; border.color: control.activeFocus ? "#9fe3cd" : "#3a4347"
    }
    indicator: Text { x: control.width - 24; y: 10; text: "⌄"; color: "#9fe3cd" }
    delegate: ItemDelegate {
        id: option
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        required property var modelData
        required property int index
        width: control.width
        text: modelData.label
        enabled: modelData.available !== false
        highlighted: control.highlightedIndex === index
        contentItem: Text { text: option.modelData.label; color: option.enabled ? "#e5ecea" : "#677479"; font: control.font; wrapMode: Text.Wrap }
        background: Rectangle { color: option.highlighted ? "#364a44" : "#242c30"; radius: 6 }
    }
    popup: Popup {
        y: control.height + 4; width: control.width; padding: 6
        implicitHeight: Math.min(contentItem.implicitHeight + 12, 240)
        contentItem: ListView {
            clip: true; implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            ScrollIndicator.vertical: ScrollIndicator {}
        }
        background: Rectangle { color: "#242c30"; radius: 12; border.color: "#46544f" }
    }
}
