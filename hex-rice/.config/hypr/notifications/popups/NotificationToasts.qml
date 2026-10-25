// Passive popup stack: no keyboard focus or outside-click grab.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../bar"
import "../../bar/services"
import "../components"
import "../services"
import "../core"
PanelWindow {
    screen: HyprlandService.screen
    visible: HyprlandService.screen !== null && NotificationStore.popups.length > 0 && PanelState.opened === "" && !SessionService.locked
    anchors.top: true
    margins.top: Settings.topMargin + Settings.height + Settings.panelGap
    implicitWidth: Settings.notificationPopupWidth
    implicitHeight: stack.implicitHeight
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-notification-toasts"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    Column {
        id: stack
        width: parent.width
        spacing: Settings.panelGap
        Repeater {
            model: NotificationStore.popups
            NotificationCard { required property var modelData; entry: modelData; width: stack.width }
        }
    }
}
