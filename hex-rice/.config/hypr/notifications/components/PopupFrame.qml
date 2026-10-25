// Shared window behavior only. Calendar and notification content remain separate.
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../../bar"
import "../../bar/services"
PanelWindow {
    id: window
    property bool shown: false
    property bool animated: false
    property real cornerRadius: Settings.panelRadius
    property bool lingering: false
    onShownChanged: {
        if (shown) { exitDelay.stop(); lingering = true; }
        else if (animated) exitDelay.restart();
        else lingering = false;
    }
    Timer { id: exitDelay; interval: 200; onTriggered: window.lingering = false }
    property Component body
    // Callers may override just the outer shell (notifications are transparent).
    property color backgroundColor: Settings.panelBackground
    property color borderColor: Settings.panelBorder
    signal dismissed()
    screen: HyprlandService.screen
    visible: (shown || (animated && lingering)) && HyprlandService.screen !== null && !SessionService.locked
    anchors.top: true
    margins.top: Settings.topMargin + Settings.height + Settings.panelGap
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: background; radius: background.radius }
    HyprlandFocusGrab {
        windows: [window]
        active: window.visible && window.shown
        onCleared: window.dismissed()
    }
    onVisibleChanged: { if (visible) background.forceActiveFocus(); }
    Rectangle {
        id: background
        anchors.fill: parent
        color: window.backgroundColor
        radius: window.cornerRadius
        opacity: !window.animated || window.shown ? 1 : 0
        scale: !window.animated || window.shown ? 1 : 0.97
        transformOrigin: Item.Top
        Behavior on opacity { NumberAnimation { duration: window.animated ? 180 : 0 } }
        Behavior on scale { NumberAnimation { duration: window.animated ? 220 : 0; easing.type: Easing.OutCubic } }
        border.color: window.borderColor
        border.width: 1
        focus: true
        Keys.onEscapePressed: window.dismissed()
        Loader { anchors.fill: parent; anchors.margins: Settings.panelPadding; sourceComponent: window.body }
    }
}
