// Passive, event-driven volume feedback beneath the centered clock card.
// No focus or input region: clicks continue through to the application below.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import ".."
import "../components"
import "../services"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    anchors.top: true
    margins.top: Settings.topMargin + Settings.height + 10
    implicitWidth: Settings.volumeOsdWidth
    implicitHeight: 96
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    visible: presented && HyprlandService.screen !== null && !SessionService.locked
    WlrLayershell.namespace: "quickshell-volume-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    mask: Region {}

    property bool ready: false
    property bool presented: false
    property bool expanded: false
    function reveal() {
        if (!ready || !AudioService.audio || SessionService.locked) return;
        retire.stop();
        presented = true;
        expanded = true;
        dismiss.restart();
    }
    // Ignore the initial PipeWire subscription and config reload.
    Timer { interval: 800; running: true; onTriggered: window.ready = true }
    Timer {
        id: dismiss
        interval: Settings.volumeOsdTimeout
        onTriggered: { window.expanded = false; retire.restart(); }
    }
    Timer { id: retire; interval: 220; onTriggered: window.presented = false }
    Connections {
        target: AudioService
        function onPercentChanged() { window.reveal(); }
        function onMutedChanged() { window.reveal(); }
    }
    Connections {
        target: SessionService
        function onLockedChanged() {
            if (SessionService.locked) {
                dismiss.stop(); retire.stop(); window.expanded = false; window.presented = false;
            }
        }
    }
    Rectangle {
        id: bubble
        width: parent.width; height: 82
        y: window.expanded ? 0 : -10
        radius: 22
        color: "#1c2626"
        border.width: 1; border.color: "#456358"
        opacity: window.expanded ? 1 : 0
        scale: window.expanded ? 1 : 0.94
        transformOrigin: Item.Top
        Behavior on y { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
        RowLayout {
            anchors { fill: parent; margins: 16 }
            spacing: 14
            Rectangle {
                implicitWidth: 44; implicitHeight: 44; radius: 15
                color: AudioService.muted ? "#453836" : "#304c41"
                Behavior on color { ColorAnimation { duration: 140 } }
                SvgIcon {
                    anchors.centerIn: parent
                    name: AudioService.muted || AudioService.percent === 0 ? "volume-x" : "volume-2"
                    color: AudioService.muted ? "#efb7a8" : "#b5efcf"
                }
            }
            ColumnLayout {
                Layout.fillWidth: true; spacing: 9
                RowLayout {
                    Layout.fillWidth: true
                    Text {
                        Layout.fillWidth: true
                        text: AudioService.muted ? "Muted" : "Volume"
                        color: "#d7e6df"
                        font { family: Settings.powerFont; pixelSize: 13; weight: Font.Medium }
                    }
                    Text {
                        text: AudioService.percent + "%"
                        color: AudioService.muted ? "#efb7a8" : "#b5efcf"
                        font { family: Settings.powerFont; pixelSize: 22; weight: Font.DemiBold }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 5; radius: 3; color: "#3c4b45"
                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(100, AudioService.percent)) / 100
                        height: parent.height; radius: parent.radius
                        color: AudioService.muted ? "#9d7e76" : "#a5e4c7"
                        Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: 140 } }
                    }
                }
            }
        }
    }
}
