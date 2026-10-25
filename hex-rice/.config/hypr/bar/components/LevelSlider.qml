// Reusable labelled level control. Only onMoved emits a write request, so
// external volume/brightness updates cannot cause a feedback loop.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
Item {
    id: root
    required property string title
    required property string icon
    property real level: 0
    property real minimum: 0
    property bool available: true
    signal adjusted(real value)
    implicitHeight: Settings.powerSliderRowHeight
    Rectangle {
        parent: root
        anchors.fill: parent
        anchors.margins: -6
        z: -1
        radius: 12
        color: "#0affffff"
    }
    function focusSlider(): void { slider.forceActiveFocus(); }
    ColumnLayout {
        anchors.fill: parent
        spacing: 6
    RowLayout {
        Layout.fillWidth: true
        SvgIcon { name: root.icon; color: root.available ? Settings.powerText : Settings.powerMuted }
        Text { text: root.title; color: Settings.powerText; font.family: Settings.powerFont; font.pixelSize: Settings.powerTextSize; Layout.fillWidth: true }
        Text { text: root.available ? Math.round(slider.value) + "%" : "Unavailable"; color: root.available ? Settings.powerAccent : Settings.powerMuted; font.family: Settings.powerFont; font.weight: Font.DemiBold; font.pixelSize: Settings.powerTextSize - 1 }
    }
    Slider {
        id: slider
        objectName: "levelSlider"
        Layout.fillWidth: true
        implicitHeight: Settings.powerSliderHandleSize + 10
        from: root.minimum; to: 100; stepSize: 1
        value: root.level
        enabled: root.available
        wheelEnabled: true
        hoverEnabled: true
        Accessible.name: root.title
        onMoved: root.adjusted(value)
        background: Rectangle {
            x: slider.leftPadding
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            width: slider.availableWidth
            height: Settings.powerSliderTrackHeight
            radius: height / 2
            color: Settings.powerTileBackground
            Rectangle { width: slider.visualPosition * parent.width; height: parent.height; radius: parent.radius; color: Settings.powerAccent; opacity: root.available ? 1 : 0.4 }
        }
        handle: Rectangle {
            x: slider.leftPadding + slider.visualPosition * (slider.availableWidth - width)
            y: slider.topPadding + slider.availableHeight / 2 - height / 2
            implicitWidth: Settings.powerSliderHandleSize; implicitHeight: Settings.powerSliderHandleSize
            radius: width / 2
            scale: slider.pressed ? 1.25 : slider.hovered ? 1.12 : 1
            Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
            color: slider.enabled ? Settings.powerText : Settings.powerMuted
            border.width: slider.visualFocus ? 2 : 0; border.color: Settings.powerAccent
        }
    }
}

}
