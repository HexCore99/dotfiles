// One icon per open application, across all Hyprland workspaces.
import QtQuick
import QtQuick.Controls.Basic
import Quickshell
import Quickshell.Hyprland
import ".."
import "../services"

Item {
    id: root
    readonly property var appIds: {
        const ids = [];
        Hyprland.toplevels.values.forEach(window => {
            const appId = idFor(window);
            if (appId && !ids.some(id => id.toLowerCase() === appId.toLowerCase())) ids.push(appId);
        });
        return ids;
    }
    readonly property int itemCount: appIds.length
    implicitWidth: icons.implicitWidth
    implicitHeight: Settings.height - 2
    property string menuAppId: ""
    property Item menuAnchor: null
    onAppIdsChanged: {
        if (menuAppId && !appIds.some(id => id.toLowerCase() === menuAppId.toLowerCase()))
            appMenu.visible = false;
    }

    function idFor(window): string {
        if (!window) return "";
        const ipc = window.lastIpcObject;
        return String((ipc && ipc.class) || (window.handle && window.handle.appId) || "");
    }

    function windowsFor(appId): var {
        return Hyprland.toplevels.values.filter(window => idFor(window).toLowerCase() === appId.toLowerCase());
    }

    function entryFor(appId): var {
        // Reading the live list makes existing buttons update after its async scan.
        // Looking up only through byId()/heuristicLookup() leaves startup windows
        // stuck with their initial missing-entry result.
        return DesktopEntries.applications.values.find(entry =>
            entry.id.toLowerCase() === appId.toLowerCase())
            || DesktopEntries.heuristicLookup(appId);
    }

    function activate(appId): void {
        const windows = windowsFor(appId);
        if (windows.length === 0) return;
        const activeIndex = windows.findIndex(window => window.activated);
        const target = windows[activeIndex < 0 ? 0 : (activeIndex + 1) % windows.length];
        HyprlandService.focusToplevel(target);
    }

    function forceQuit(appId): void {
        // A grouped icon may represent windows owned by different processes.
        const addresses = [];
        windowsFor(appId).forEach(window => {
            const address = HyprlandService.toplevelAddress(window);
            if (address && !addresses.includes(address)) {
                addresses.push(address);
                HyprlandService.forceKillToplevel(window);
            }
        });
    }

    function showMenu(appId, item): void {
        appMenu.visible = false;
        menuAppId = appId;
        menuAnchor = item;
        appMenu.visible = true;
    }

    PopupWindow {
        id: appMenu
        anchor.item: root.menuAnchor
        anchor.edges: Edges.Bottom | Edges.Left
        anchor.gravity: Edges.Bottom | Edges.Right
        implicitWidth: 140
        implicitHeight: 76
        visible: false
        grabFocus: true
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            radius: Settings.barRadius
            color: Settings.background
            border.width: Settings.barGroupBorderWidth
            border.color: Settings.border

            MouseArea {
                anchors.fill: parent
                onClicked: appMenu.visible = false
            }

            Column {
                anchors.fill: parent
                anchors.margins: 4
                spacing: 2

                Repeater {
                    model: ["Open", "Quit"]
                    delegate: Rectangle {
                        required property string modelData
                        width: parent.width
                        height: 33
                        radius: 6
                        color: actionMouse.containsMouse ? Settings.hover : "transparent"

                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: modelData
                            color: modelData === "Quit" ? Settings.warning : Settings.foreground
                            font.family: Settings.font
                            font.pixelSize: Settings.fontSize - 2
                        }

                        MouseArea {
                            id: actionMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                appMenu.visible = false;
                                if (modelData === "Open") root.activate(root.menuAppId);
                                else root.forceQuit(root.menuAppId);
                            }
                        }
                    }
                }
            }
        }
    }

    Row {
        id: icons
        anchors.centerIn: parent
        spacing: Settings.barGroupSpacing

        Repeater {
            model: root.appIds

            delegate: Item {
                id: appButton
                required property string modelData
                readonly property var entry: root.entryFor(modelData)
                readonly property string appName: entry ? entry.name : modelData.split(".").pop()
                readonly property string iconName: entry ? entry.icon : ""
                readonly property string iconSource: iconName.startsWith("/")
                    ? iconName : Quickshell.iconPath(iconName || modelData, true)
                readonly property bool active: Hyprland.activeToplevel !== null
                    && root.windowsFor(modelData).some(window => window.activated)
                readonly property int windowCount: root.windowsFor(modelData).length
                implicitWidth: Settings.iconSize + 14
                implicitHeight: Settings.height - 2

                Rectangle {
                    anchors.fill: parent
                    radius: Settings.barRadius
                    color: pointer.containsMouse ? Settings.hover : "transparent"
                }

                Image {
                    anchors.centerIn: parent
                    width: Settings.iconSize
                    height: Settings.iconSize
                    source: appButton.iconSource
                    sourceSize.width: Settings.iconSize
                    sourceSize.height: Settings.iconSize
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: appButton.iconSource !== ""
                }

                Text {
                    anchors.centerIn: parent
                    text: appButton.appName.slice(0, 1).toUpperCase()
                    color: Settings.foreground
                    font.family: Settings.font
                    font.pixelSize: Settings.fontSize
                    font.weight: Settings.fontWeight
                    visible: appButton.iconSource === ""
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: appButton.active ? 14 : 5
                    height: 2
                    radius: 1
                    color: appButton.active ? Settings.active : Settings.workspaceOccupied
                }

                MouseArea {
                    id: pointer
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: event => {
                        if (event.button === Qt.RightButton) root.showMenu(appButton.modelData, appButton);
                        else root.activate(appButton.modelData);
                    }
                }

                ToolTip {
                    visible: Settings.showTooltips && pointer.containsMouse
                    delay: 700
                    text: appButton.appName + (appButton.windowCount > 1 ? " (" + appButton.windowCount + " windows)" : "")
                    enter: null
                    exit: null
                    background: Rectangle { color: Settings.background; border.color: Settings.border; border.width: 1 }
                    contentItem: Text { text: appButton.appName + (appButton.windowCount > 1 ? " (" + appButton.windowCount + " windows)" : ""); color: Settings.foreground; font.family: Settings.font; font.pixelSize: Settings.fontSize }
                }
            }
        }
    }
}
