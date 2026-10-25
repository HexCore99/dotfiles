// Layout only: independent rounded cards with transparent space between.
// Each child module is responsible for its own text, tooltip, and click actions.
import QtQuick
import Quickshell
import Quickshell.Wayland
import "services"
import "modules"
import "components"
PanelWindow {
    id: bar
    screen: HyprlandService.screen
    visible: HyprlandService.screen !== null && !SessionService.locked && !HyprlandService.fullscreen
    // Three edge anchors make the panel span the monitor width.
    anchors { top: true; left: true; right: true }
    margins { top: Settings.topMargin; left: Settings.sideMargin; right: Settings.sideMargin }
    implicitHeight: Settings.height
    // Reserve a fixed strip so tiled windows sit below the bar.
    exclusiveZone: Settings.height
    color: "transparent"
    WlrLayershell.namespace: "quickshell-flatbar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Only the cards accept pointer input. Transparent gaps pass through
    // to the desktop; the original top-strip reservation stays the same.
    mask: Region {
        Region { item: workspaceGroup; radius: workspaceGroup.radius }
        Region {
            x: timeGroup.x; y: timeGroup.y
            width: timeGroup.visible ? timeGroup.width : 0
            height: timeGroup.height; radius: timeGroup.radius
        }
        Region { item: connectivityGroup; radius: connectivityGroup.radius }
        Region { item: appsGroup; radius: appsGroup.radius }
        Region { item: usageGroup; radius: usageGroup.radius }
        Region { item: batteryGroup; radius: batteryGroup.radius }
        Region { item: powerGroup; radius: powerGroup.radius }
    }
    Item {
        anchors.fill: parent
        // Each module owns its own display and interactions. No animation layer.
        BarGroup {
            id: workspaceGroup
            anchors { left: parent.left; verticalCenter: parent.verticalCenter }
            Launcher {}
            Workspaces {}
        }
        // Center the combined notification/time card independently of side widths.
        BarGroup {
            id: timeGroup
            anchors.centerIn: parent
            spacing: Settings.iconSpacing
            visible: x > workspaceGroup.width + Settings.barCenterMinimumGap
                && x + width + Settings.barCenterMinimumGap < usageGroup.x
            Notifications {}
            Clock {}
        }

        BarGroup {
            id: usageGroup
            anchors { right: appsGroup.left; rightMargin: appsGroup.visible ? Settings.barGroupGap : 0; verticalCenter: parent.verticalCenter }
            Memory {}
        }
        BarGroup {
            id: appsGroup
            anchors { right: connectivityGroup.left; rightMargin: Settings.barGroupGap; verticalCenter: parent.verticalCenter }
            visible: runningApps.itemCount > 0
            width: visible ? implicitWidth : 0
            RunningApps { id: runningApps }
        }
        BarGroup {
            id: connectivityGroup
            anchors { right: batteryGroup.left; rightMargin: Settings.barGroupGap; verticalCenter: parent.verticalCenter }
            Network {}
            Bluetooth {}
            Volume {}

        }
        BarGroup {
            id: batteryGroup
            anchors { right: powerGroup.left; rightMargin: Settings.barGroupGap; verticalCenter: parent.verticalCenter }
            Battery {}
        }
        BarGroup {
            id: powerGroup
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            Power {}
        }
    }
}
