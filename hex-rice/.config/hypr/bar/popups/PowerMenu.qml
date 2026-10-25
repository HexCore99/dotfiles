// Volume and brightness controls above a 2x2 power-action grid.
// Sliders and tiles are reusable components; system integrations stay in services.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../components"
import "../core"
import "../services"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    visible: PowerState.opened && HyprlandService.screen !== null && !SessionService.locked
    anchors.top: true
    margins.top: Settings.topMargin + Settings.height + Settings.panelGap
    implicitWidth: Settings.powerMenuWidth
    implicitHeight: content.implicitHeight + Settings.powerMenuPadding * 2
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-power-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: background; radius: background.radius }
    HyprlandFocusGrab { windows: [window]; active: window.visible; onCleared: PowerState.close() }
    onVisibleChanged: {
        BrightnessService.watching = visible;
        if (visible) { BrightnessService.refresh(); volume.focusSlider(); entrance.restart(); }
    }
    Rectangle {
        id: background
        anchors.fill: parent
        color: Qt.rgba(Settings.powerMenuBackground.r, Settings.powerMenuBackground.g,
            Settings.powerMenuBackground.b, Math.max(0, Math.min(1, Settings.powerMenuOpacity)))
        radius: Settings.powerMenuRadius
        border.width: 1; border.color: "#30c3dfd8"
        transformOrigin: Item.Top
        ParallelAnimation {
            id: entrance
            NumberAnimation { target: background; property: "opacity"; from: 0; to: 1; duration: 180 }
            NumberAnimation { target: background; property: "scale"; from: 0.96; to: 1; duration: 240; easing.type: Easing.OutCubic }
        }
        // Escape works from sliders or buttons. Activation keys are handled only
        // by the focused tile, so Enter on a slider cannot trigger a power action.
        Keys.onEscapePressed: PowerState.close()
        ColumnLayout {
            id: content
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: Settings.powerMenuPadding }
            spacing: Settings.powerMenuSpacing
            RowLayout {
                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 2
                    Text {
                        text: "Quick controls"
                        color: Settings.powerText
                        font { family: Settings.powerFont; pixelSize: 21; weight: Font.DemiBold }
                    }
                    Text {
                        text: "Sound, display & session"
                        color: Settings.powerMuted
                        font { family: Settings.powerFont; pixelSize: 11 }
                    }
                }
                Rectangle {
                    implicitWidth: 34; implicitHeight: 34; radius: 12
                    color: "#199fe3d5"
                    SvgIcon { anchors.centerIn: parent; name: "power"; color: Settings.powerAccent; width: 16; height: 16 }
                }
            }
            LevelSlider {
                id: volume
                Layout.fillWidth: true
                title: AudioService.muted ? "Volume · muted" : "Volume"
                icon: AudioService.muted ? "volume-x" : "volume-2"
                level: AudioService.percent
                available: AudioService.audio !== null
                onAdjusted: value => AudioService.setPercent(value)
            }
            LevelSlider {
                Layout.fillWidth: true
                title: "Brightness"; icon: "sun"
                level: BrightnessService.percent
                minimum: Settings.brightnessMinimum
                available: BrightnessService.available
                onAdjusted: value => BrightnessService.setPercent(value)
            }
            Text {
                visible: BrightnessService.error !== ""
                Layout.fillWidth: true
                text: BrightnessService.error; wrapMode: Text.Wrap
                color: Settings.warning; font.family: Settings.powerFont; font.pixelSize: Settings.powerTextSize - 1
            }
            Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#18ffffff" }
            Text {
                text: "SESSION"
                color: Settings.powerMuted
                font { family: Settings.powerFont; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.7 }
            }
            GridLayout {
                id: grid
                Layout.fillWidth: true
                columns: 2
                columnSpacing: Settings.powerMenuSpacing
                rowSpacing: Settings.powerMenuSpacing
                // Arrow navigation applies only within the action grid. Sliders
                // retain their own Left/Right handling; Tab follows normal order.
                Keys.onPressed: event => {
                    let step = 0;
                    if (event.key === Qt.Key_Left) step = -1;
                    else if (event.key === Qt.Key_Right) step = 1;
                    else if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) step = 2;
                    else return;
                    const next = (PowerState.selected + step + 4) % 4;
                    tiles.itemAt(next).forceActiveFocus();
                    event.accepted = true;
                }
                Repeater {
                    id: tiles
                    model: PowerState.choices
                    PowerTile {
                        required property var modelData
                        required property int index
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        title: modelData.label; iconName: modelData.icon
                        subtitle: ["Keep things private", "Take a break", "Start fresh", "End your session"][index]
                        destructive: modelData.action === "poweroff"
                        onActiveFocusChanged: { if (activeFocus) PowerState.selected = index; }
                        onActivated: PowerState.activate(modelData.action)
                    }
                }
            }
        }
    }
}
