import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../services"
import "../components"
Rectangle {
    id: card
    required property var item
    readonly property bool isDevice: item.kind === "sink" || item.kind === "source"
    enabled: !isDevice || !!item.available
    opacity: enabled ? 1 : 0.42
    Behavior on opacity { NumberAnimation { duration: 180 } }
    function selectDevice() {
        if (enabled && isDevice && !item.default) SoundService.change("default", item, null);
    }
    HoverHandler { id: cardHover; cursorShape: Qt.PointingHandCursor }
    // Behind the controls: sliders and buttons handle their own clicks.
    MouseArea {
        anchors.fill: parent
        enabled: card.isDevice
        onClicked: card.selectDevice()
    }
    property bool dragging: volume.pressed
    signal editing(bool active)
    implicitHeight: body.implicitHeight + 32
    radius: 18
    color: item.default ? "#253b35" : "#252c30"
    border.width: 1; border.color: item.default ? "#527e6d" : cardHover.hovered ? "#668d7e" : "#333d40"
    Behavior on color { ColorAnimation { duration: 180 } }
    ColumnLayout {
        id: body
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 16 }
        spacing: 10
        RowLayout {
            Layout.fillWidth: true
            Rectangle {
                implicitWidth: 40; implicitHeight: 40; radius: 13; color: card.item.default ? "#35584a" : "#343d42"
                SvgIcon { anchors.centerIn: parent; name: card.item.kind === "card" ? "volume-2" : card.item.kind.indexOf("source") >= 0 ? "mic" : "volume-2"; color: "#b1e8d4" }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 3
                Text { Layout.fillWidth: true; text: card.item.title; color: "#edf4f1"; font { family: "Noto Sans"; pixelSize: 15; weight: Font.DemiBold } elide: Text.ElideRight }
                Text {
                    Layout.fillWidth: true
                    text: card.item.kind === "card" ? "Hardware profile" : !card.item.available ? "Not connected" : card.item.default ? "Default device" : card.item.kind === "sink-input" ? "Playback · " + card.item.detail : card.item.kind === "source-output" ? "Recording · " + card.item.detail : card.item.detail
                    color: "#a5b6af"; font { family: "Noto Sans"; pixelSize: 11 } elide: Text.ElideRight
                }
            }
            SoundButton {
                visible: card.item.kind === "sink" || card.item.kind === "source"
                text: !card.item.available ? "Disconnected" : card.item.default ? "✓ Default" : "Use device"; selected: !!card.item.default
                Accessible.name: "Use " + card.item.title
                onClicked: card.selectDevice()
            }
        }
        RowLayout {
            visible: card.item.kind !== "card"
            Layout.fillWidth: true; spacing: 12
            SoundButton {
                text: card.item.muted ? "Unmute" : "Mute"; selected: !!card.item.muted
                Accessible.name: text + " " + card.item.title
                onClicked: SoundService.change("mute", card.item, !card.item.muted)
            }
            Slider {
                id: volume
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                Layout.fillWidth: true
                from: 0; to: 100; stepSize: 1; value: card.item.volume || 0
                enabled: !!card.item.hasVolume
                implicitHeight: 32; wheelEnabled: true
                Accessible.name: card.item.title + " volume"
                onPressedChanged: card.editing(pressed)
                onMoved: SoundService.change("volume", card.item, Math.round(value))
                background: Rectangle {
                    x: volume.leftPadding; y: (volume.height - height) / 2
                    width: volume.availableWidth; height: 7; radius: 4; color: "#414c4e"
                    Rectangle { width: volume.visualPosition * parent.width; height: parent.height; radius: 4; color: card.item.muted ? "#7e9090" : "#9fe3cd" }
                }
                handle: Rectangle {
                    x: volume.leftPadding + volume.visualPosition * (volume.availableWidth - width)
                    y: (volume.height - height) / 2
                    implicitWidth: 18; implicitHeight: 18; radius: 9; color: "#e4fff4"
                    scale: volume.pressed ? 1.2 : 1
                    border.width: volume.visualFocus ? 3 : 0; border.color: "#6fb497"
                    Behavior on scale { NumberAnimation { duration: 120 } }
                }
            }
            Text { text: Math.round(volume.value) + "%"; Layout.preferredWidth: 42; horizontalAlignment: Text.AlignRight; color: "#c3d8cf"; font { family: "Noto Sans"; pixelSize: 13 } }
        }
        SoundSelect {
            Layout.fillWidth: true
            visible: card.item.kind === "card" || (card.item.ports || []).length > 1 || card.item.kind === "sink-input" || card.item.kind === "source-output"
            property bool stream: card.item.kind === "sink-input" || card.item.kind === "source-output"
            model: card.item.kind === "card" ? card.item.profiles : stream ? (card.item.kind === "sink-input" ? SoundService.data.outputs : SoundService.data.inputs).map(d => ({name: d.id, label: d.title, available: d.available})) : (card.item.ports || [])
            selectedName: card.item.kind === "card" ? card.item.profile : stream ? card.item.route : card.item.port
            Accessible.name: card.item.kind === "card" ? "Hardware profile" : stream ? "Route audio to device" : "Device port"
            onActivated: SoundService.change(card.item.kind === "card" ? "profile" : stream ? "route" : "port", card.item, currentValue)
        }
    }
}
