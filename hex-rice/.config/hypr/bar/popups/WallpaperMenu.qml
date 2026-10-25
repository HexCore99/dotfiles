// The wallpaper window owns layout and focus only. Settings.qml owns appearance,
// WallpaperState owns dismissal and WallpaperService owns scans and application.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "../core"
import "../services"
import "../components"
PanelWindow {
    id: window
    screen: HyprlandService.screen
    visible: WallpaperState.opened && HyprlandService.screen !== null && !SessionService.locked
    anchors.top: true
    margins.top: Settings.topMargin + Settings.height + Settings.panelGap
    implicitWidth: Math.min(Settings.wallpaperWidth, screen ? screen.width - Settings.sideMargin * 2 : Settings.wallpaperWidth)
    implicitHeight: Math.min(Settings.wallpaperHeight, screen ? screen.height - margins.top - Settings.wallpaperPadding : Settings.wallpaperHeight)
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    WlrLayershell.namespace: "quickshell-wallpaper"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    mask: Region { item: background; radius: background.radius }
    HyprlandFocusGrab { windows: [window]; active: window.visible; onCleared: WallpaperState.close() }
    onVisibleChanged: {
        WallpaperService.watching = visible;
        if (visible) background.forceActiveFocus();
    }
    Rectangle {
        id: background
        anchors.fill: parent; radius: Settings.wallpaperRadius
        color: Qt.rgba(Settings.wallpaperBackground.r, Settings.wallpaperBackground.g,
            Settings.wallpaperBackground.b, Math.max(0, Math.min(1, Settings.wallpaperBackgroundOpacity)))
        border.width: 1; border.color: Settings.wallpaperBorder
        Keys.onEscapePressed: WallpaperState.close()
        ColumnLayout {
            anchors.fill: parent; anchors.margins: Settings.wallpaperPadding
            spacing: Settings.wallpaperSpacing
            RowLayout {
                Layout.fillWidth: true; spacing: Settings.wallpaperSpacing
                SvgIcon {
                    name: "image"; color: Settings.wallpaperAccent
                    width: Settings.wallpaperTitleSize; height: width
                    Layout.preferredWidth: width; Layout.preferredHeight: height
                }
                Text {
                    text: "Wallpapers"; Layout.fillWidth: true
                    color: Settings.wallpaperText; font.family: Settings.wallpaperFont
                    font.pixelSize: Settings.wallpaperTitleSize; font.bold: true
                }
                WallpaperButton {
                    text: "Refresh"; iconName: "rotate-cw"
                    enabled: !WallpaperService.loading && !WallpaperService.applying
                    onClicked: WallpaperService.refresh()
                }
                WallpaperButton { text: "Close"; iconName: "x"; onClicked: WallpaperState.close() }
            }
            Text {
                Layout.fillWidth: true
                text: WallpaperService.folder; textFormat: Text.PlainText; elide: Text.ElideMiddle
                color: Settings.wallpaperMuted; font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize
            }
            Text {
                Layout.fillWidth: true
                visible: text !== ""
                text: WallpaperService.error || (WallpaperService.applying ? "Applying wallpaper…" : WallpaperService.loading ? "Loading thumbnails · " + WallpaperService.processed + " / " + WallpaperService.total : WallpaperService.skipped ? WallpaperService.skipped + " unreadable image(s) skipped" : "")
                textFormat: Text.PlainText; wrapMode: Text.Wrap
                color: WallpaperService.error ? Settings.wallpaperError : Settings.wallpaperMuted
                font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize
            }
            Item {
                Layout.fillWidth: true; Layout.fillHeight: true
                GridView {
                    id: grid
                    objectName: "wallpaperGrid"
                    anchors.fill: parent
                    clip: true
                    model: WallpaperService.model
                    readonly property int columns: Math.max(1, Math.min(Settings.wallpaperColumns, Math.floor(width / Settings.wallpaperMinimumTileWidth)))
                    cellWidth: width / columns
                    cellHeight: (cellWidth - Settings.wallpaperSpacing) * Settings.wallpaperThumbnailHeight / Settings.wallpaperThumbnailWidth + Settings.wallpaperLabelHeight + Settings.wallpaperSpacing
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true; highlightMoveDuration: 0
                    ScrollBar.vertical: ScrollBar {
                        id: scrollbar
                        policy: ScrollBar.AsNeeded
                        padding: 0
                        // Replace Basic's default animated fade with a fixed thumb.
                        contentItem: Rectangle {
                            implicitWidth: Settings.wallpaperScrollBarWidth
                            implicitHeight: Settings.wallpaperScrollBarWidth
                            radius: width / 2
                            color: Settings.wallpaperMuted
                            visible: scrollbar.size < 1
                        }
                        background: Item {}
                    }
                    delegate: WallpaperTile {
                        required property string path
                        required property string name
                        required property string thumbnail
                        required property int index
                        wallpaper: ({path: path, name: name, thumbnail: thumbnail})
                        current: WallpaperService.activePath === path
                        width: grid.cellWidth - Settings.wallpaperSpacing
                        height: grid.cellHeight - Settings.wallpaperSpacing
                        enabled: !WallpaperService.applying
                        onClicked: WallpaperService.apply(path)
                        onActiveFocusChanged: {
                            if (activeFocus) { grid.currentIndex = index; grid.positionViewAtIndex(index, GridView.Contain); }
                        }
                        // Arrow keys keep focus on a real button; Enter/Space activate it.
                        Keys.onPressed: event => {
                            let step = 0;
                            if (event.key === Qt.Key_Left) step = -1;
                            else if (event.key === Qt.Key_Right) step = 1;
                            else if (event.key === Qt.Key_Up) step = -grid.columns;
                            else if (event.key === Qt.Key_Down) step = grid.columns;
                            else return;
                            grid.currentIndex = Math.max(0, Math.min(grid.count - 1, index + step));
                            grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
                            if (grid.currentItem) grid.currentItem.forceActiveFocus();
                            event.accepted = true;
                        }
                    }
                }
                Column {
                    anchors.centerIn: parent; width: parent.width
                    spacing: Settings.wallpaperSpacing
                    visible: !WallpaperService.loading && WallpaperService.items.length === 0
                    SvgIcon { anchors.horizontalCenter: parent.horizontalCenter; name: "image"; color: Settings.wallpaperMuted; width: Settings.wallpaperTitleSize * 2; height: width }
                    Text {
                        width: parent.width; text: "Your next backdrop starts here"
                        color: Settings.wallpaperText; horizontalAlignment: Text.AlignHCenter
                        font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTitleSize - 4
                    }
                    Text {
                        width: parent.width; text: "Add JPG, PNG, WebP or BMP images to this folder,\nthen press Refresh. Subfolders are included."
                        color: Settings.wallpaperMuted; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap
                        font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize
                    }
                }
            }
            Text {
                Layout.fillWidth: true
                text: WallpaperService.items.length + " wallpapers  ·  Click to apply  ·  Esc to close"
                color: Settings.wallpaperMuted; font.family: Settings.wallpaperFont; font.pixelSize: Settings.wallpaperTextSize - 1
            }
        }
    }
}
