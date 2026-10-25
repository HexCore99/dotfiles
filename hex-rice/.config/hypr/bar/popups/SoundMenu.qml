pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
import ".."
import "../audio"
import "../core"
import "../services"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    visible: (SoundState.opened || surface.opacity > 0) && HyprlandService.screen !== null && !SessionService.locked
    anchors { top: true; right: true }
    margins { top: Settings.topMargin + Settings.height + 10; right: 12 }
    implicitWidth: Math.min(620, screen ? screen.width - 24 : 620)
    implicitHeight: Math.min(720, screen ? screen.height - 70 : 720)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-sound-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: SoundState.opened ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    mask: Region { item: surface; radius: 26 }
    HyprlandFocusGrab { windows: [window]; active: SoundState.opened && window.visible; onCleared: SoundState.close() }
    IpcHandler {
        target: "sound"
        function page(name: string): void {
            const index = window.tabs.map(t => t.toLowerCase()).indexOf(name.toLowerCase());
            if (index < 0) return;
            window.tab = index;
            if (!SoundState.opened) SoundState.toggle();
        }
    }
    property int tab: 0
    property bool editing: false
    readonly property var tabs: ["Output", "Input", "Apps", "Cards"]
    readonly property var descriptions: ["Choose where your sound plays", "Microphones and capture devices", "Individual playback and recording levels", "Choose an audio profile for your hardware"]
    readonly property var entries: tab === 0 ? SoundService.data.outputs : tab === 1 ? SoundService.data.inputs : tab === 2 ? SoundService.data.playback.concat(SoundService.data.recording) : SoundService.data.cards
    function sync() {
        if (editing) return;
        // Preserve delegates and keyboard focus when values update in place.
        const rows = entries;
        for (let i = 0; i < rows.length; i++) {
            const key = rows[i].kind + rows[i].id;
            if (i >= items.count) items.append({key: key, payload: rows[i]});
            else if (items.get(i).key !== key) { items.remove(i); items.insert(i, {key: key, payload: rows[i]}); }
            else if (JSON.stringify(items.get(i).payload) !== JSON.stringify(rows[i])) items.setProperty(i, "payload", rows[i]);
        }
        while (items.count > rows.length) items.remove(items.count - 1);
    }
    onEntriesChanged: sync()
    onEditingChanged: if (!editing) sync()
    onTabChanged: { list.contentY = 0; switchAnimation.restart(); }
    ListModel { id: items; dynamicRoles: true }
    Connections {
        target: SoundState
        function onOpenedChanged() {
            SoundService.watching = SoundState.opened;
            if (SoundState.opened) surface.forceActiveFocus();
        }
    }
    Rectangle {
        id: surface
        anchors.fill: parent
        radius: 26; color: "#191f23"; border.width: 1; border.color: "#3b4b46"
        opacity: SoundState.opened ? 1 : 0
        scale: SoundState.opened ? 1 : 0.96
        transformOrigin: Item.TopRight
        Behavior on opacity { NumberAnimation { duration: 170 } }
        Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
        Keys.onEscapePressed: SoundState.close()
        ColumnLayout {
            anchors.fill: parent; anchors.margins: 24; spacing: 18
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true; spacing: 3
                    Text { text: "SOUND STUDIO"; color: "#9fe3cd"; font { family: "Noto Sans"; pixelSize: 10; letterSpacing: 2; weight: Font.Bold } }
                    Text { text: "Make it sound right."; color: "#eff7f3"; font { family: "Noto Sans"; pixelSize: 27; weight: Font.DemiBold } }
                }
                Item { Layout.fillWidth: true }
                SoundButton { text: "✕"; Accessible.name: "Close sound settings"; onClicked: SoundState.close() }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 88; radius: 18; color: "#293e36"
                RowLayout {
                    anchors.fill: parent; anchors.margins: 18; spacing: 16
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 4
                        Text { text: AudioService.muted ? "OUTPUT MUTED" : "MASTER OUTPUT"; color: "#b4d8c9"; font { family: "Noto Sans"; pixelSize: 10; letterSpacing: 1.2 } }
                        Text { text: AudioService.sink ? AudioService.sink.description : "No output device"; Layout.fillWidth: true; elide: Text.ElideRight; color: "#edf8f2"; font { family: "Noto Sans"; pixelSize: 14 } }
                    }
                    Text { text: AudioService.percent + "%"; color: "#b9f2da"; font { family: "Noto Sans"; pixelSize: 32; weight: Font.Light } }
                    SoundButton { text: AudioService.muted ? "Unmute" : "Mute"; enabled: AudioService.audio !== null; selected: AudioService.muted; onClicked: AudioService.toggleMute() }
                }
            }
            Rectangle {
                Layout.fillWidth: true; implicitHeight: 44; color: "#252c30"; radius: 14
                Rectangle {
                    x: 4 + window.tab * ((parent.width - 8) / 4); y: 4
                    width: (parent.width - 8) / 4; height: 36; radius: 11; color: "#9fe3cd"
                    Behavior on x { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
                }
                Row {
                    anchors.fill: parent; anchors.margins: 4
                    Repeater {
                        model: window.tabs
                        Button {
                            id: tabButton
                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            required property int index
                            required property string modelData
                            width: parent.width / 4; height: 36
                            background: Rectangle { color: "transparent"; radius: 11; border.width: tabButton.visualFocus ? 1 : 0; border.color: "#edf8f2" }
                            contentItem: Text { text: tabButton.modelData; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; color: window.tab === tabButton.index ? "#142a25" : "#acbdb5"; font { family: "Noto Sans"; pixelSize: 13; weight: Font.DemiBold } Behavior on color { ColorAnimation { duration: 160 } } }
                            onClicked: window.tab = index
                        }
                    }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Text { text: window.descriptions[window.tab]; Layout.fillWidth: true; wrapMode: Text.Wrap; color: "#a0b0a9"; font { family: "Noto Sans"; pixelSize: 12 } }
                Text { text: items.count.toString().padStart(2, "0"); color: "#9fe3cd"; font { family: "Noto Sans"; pixelSize: 12 } }
            }
            Text { visible: SoundService.error !== ""; text: SoundService.error; Layout.fillWidth: true; wrapMode: Text.Wrap; color: "#f0b59f"; font { family: "Noto Sans"; pixelSize: 12 } }
            ListView {
                id: list
                Layout.fillWidth: true; Layout.fillHeight: true
                clip: true; spacing: 10; boundsBehavior: Flickable.StopAtBounds
                model: items
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                delegate: SoundCard {
                    required property var payload
                    width: list.width; item: payload
                    onEditing: active => window.editing = active
                }
                Text {
                    anchors.centerIn: parent; width: parent.width - 40
                    visible: items.count === 0
                    text: SoundService.loading ? "Finding audio devices…" : window.tab === 2 ? "Nothing playing or recording yet.\nOpen an app to adjust its sound here." : "No devices available.\nConnect an audio device to get started."
                    horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; lineHeight: 1.5
                    color: "#a0b0a9"; font { family: "Noto Sans"; pixelSize: 14 }
                }
                SequentialAnimation {
                    id: switchAnimation
                    PropertyAction { target: list; property: "opacity"; value: 0.35 }
                    NumberAnimation { target: list; property: "opacity"; to: 1; duration: 200; easing.type: Easing.OutCubic }
                }
            }
            RowLayout {
                Layout.fillWidth: true
                Rectangle { implicitWidth: 6; implicitHeight: 6; radius: 3; color: SoundService.error ? "#f0b59f" : "#9fe3cd" }
                Text { text: SoundService.busy ? "Applying changes…" : "PipeWire audio · volume capped at 100%"; Layout.fillWidth: true; color: "#82968c"; font { family: "Noto Sans"; pixelSize: 11 } }
                SoundButton { text: "Refresh"; onClicked: { SoundService.error = ""; SoundService.refresh(); } }
            }
        }
    }
}
