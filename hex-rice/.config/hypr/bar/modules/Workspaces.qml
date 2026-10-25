// Large workspace circles: muted salmon for active, gray for occupied,
// darker gray for unused. Active dots ease into a pill when selection changes.
// Click or scroll to switch; Settings controls size, timing and animation toggle.
import QtQuick
import ".."
import "../services"
import "../components"
Row {
    id: root
    spacing: 0
    // Start with the configured dots, then include any extra occupied workspace.
    readonly property var requestedIds: {
        const ids = Array.from({length: Settings.workspaceCount}, (_, i) => i + 1);
        HyprlandService.workspaces.forEach(w => { if (!ids.includes(w.id)) ids.push(w.id); });
        return ids.sort((a, b) => a - b);
    }
    property var ids: []
    // Hyprland creates/removes empty workspaces as you switch. Keep the same
    // delegates when the displayed IDs haven't changed, so animations can finish.
    function syncIds(): void {
        if (ids.join(",") !== requestedIds.join(",")) ids = requestedIds;
    }
    onRequestedIdsChanged: syncIds()
    Component.onCompleted: syncIds()
    Repeater {
        model: root.ids
        BarButton {
            id: button
            required property int modelData
            readonly property bool active: HyprlandService.workspace && HyprlandService.workspace.id === modelData
            readonly property bool occupied: HyprlandService.workspaces.some(w => w.id === modelData)
            implicitWidth: Settings.workspaceWidth
            // Animate width and color only. Hit areas and the group stay fixed,
            // and switching again smoothly retargets the current animation.
            Rectangle {
                anchors.centerIn: parent
                width: button.active ? Settings.workspaceActiveDotWidth : Settings.workspaceDotSize
                height: Settings.workspaceDotSize
                radius: height / 2
                color: button.foreground
                Behavior on width {
                    enabled: Settings.workspaceAnimations
                    NumberAnimation { duration: Settings.workspaceAnimationDuration; easing.type: Easing.OutCubic }
                }
                Behavior on color {
                    enabled: Settings.workspaceAnimations
                    ColorAnimation { duration: Settings.workspaceAnimationDuration; easing.type: Easing.OutCubic }
                }
            }
            foreground: active ? Settings.active : occupied ? Settings.workspaceOccupied : Settings.workspaceEmpty
            // Workspace dots stay quiet on hover; no tooltip overlay.
            hint: ""
            onClicked: HyprlandService.focusWorkspace(modelData)
            onScrolled: up => {
                const ids = root.ids;
                const at = ids.indexOf(HyprlandService.workspace ? HyprlandService.workspace.id : 1);
                HyprlandService.focusWorkspace(ids[(at + (up ? -1 : 1) + ids.length) % ids.length]);
            }
        }
    }
}
