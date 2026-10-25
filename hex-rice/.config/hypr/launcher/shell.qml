//@ pragma IconTheme Papirus-Dark
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

ShellRoot {
    id: root
    property bool opened: false
    property string query: ""
    property var favoriteIds: ["firefox", "kitty", "org.gnome.Nautilus", "code-oss"]
    property string saveError: ""
    readonly property var apps: DesktopEntries.applications.values.filter(a => !a.noDisplay).slice().sort((a,b) => a.name.localeCompare(b.name))
    readonly property var favorites: favoriteIds.map(id => apps.find(a => a.id === id)).filter(a => a)
    readonly property var results: {
        const q = query.trim().toLowerCase();
        if (!q) return apps;
        const words = q.split(/\s+/);
        return apps.filter(a => words.every(w => [a.name, a.genericName, a.comment, a.id, ...a.keywords].join(" ").toLowerCase().includes(w)))
            .sort((a,b) => rank(a, q) - rank(b, q) || a.name.localeCompare(b.name));
    }
    function rank(app, q) { const n = app.name.toLowerCase(); return n === q ? 0 : n.startsWith(q) ? 1 : n.includes(q) ? 2 : 3; }
    function isFavorite(app) { return favoriteIds.includes(app.id); }
    function pin(app) {
        favoriteIds = isFavorite(app) ? favoriteIds.filter(id => id !== app.id) : favoriteIds.concat([app.id]);
        saved.setText(JSON.stringify(favoriteIds, null, 2) + "\n");
    }
    function show() {
        closeTimer.stop();
        query = "";
        window.visible = true;
        opened = true;
        search.forceActiveFocus();
        list.currentIndex = 0;
    }
    function close() { opened = false; closeTimer.restart(); }
    function launch(app) {
        if (!app) return;
        if (app.runInTerminal) Quickshell.execDetached({command: ["kitty", "--", ...app.command], workingDirectory: app.workingDirectory});
        else app.execute();
        close();
    }
    function move(step) {
        if (results.length === 0) return;
        list.currentIndex = Math.max(0, Math.min(results.length - 1, list.currentIndex + step));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }
    FileView {
        id: saved
        path: Qt.resolvedUrl("favorites.json")
        printErrors: false
        blockLoading: true
        onLoaded: {
            try {
                const value = JSON.parse(text());
                if (Array.isArray(value) && value.every(v => typeof v === "string")) root.favoriteIds = value;
            } catch (e) { root.saveError = "Could not read saved favorites."; }
        }
        onSaveFailed: root.saveError = "Could not save favorites. Check launcher folder permissions."
        onSaved: root.saveError = ""
    }
    Timer { id: closeTimer; interval: 170; onTriggered: window.visible = false }
    IpcHandler {
        target: "launcher"
        function toggle(): void { if (root.opened) root.close(); else root.show(); }
        function open(): void { root.show(); }
        function close(): void { root.close(); }
        function search(text: string): void { root.show(); root.query = text; }
        function favoriteSelected(): void { const app = root.results[list.currentIndex]; if (app) root.pin(app); }
        function status(): string { return JSON.stringify({open: root.opened, apps: root.apps.length, results: root.results.length, favorites: root.favoriteIds, query: root.query}); }
    }
    PanelWindow {
        id: window
        visible: false
        screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) || Quickshell.screens[0]
        anchors { top: true; bottom: true; left: true; right: true }
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.namespace: "quickshell-app-launcher"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        // Capture outside clicks explicitly, including when keyboard focus is exclusive.
        // This also prevents the dismissal click from activating an underlying app.
        MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons; onClicked: root.close() }
        Rectangle {
            id: panel
            anchors.centerIn: parent
            width: Math.min(644, window.width - 56)
            height: Math.min(704, window.height - 96)
            radius: 28
            color: "#e01b1e27"
            border.color: "#38b4c5e4"
            border.width: 1
            opacity: root.opened ? 1 : 0
            scale: root.opened ? 1 : 0.96
            Behavior on opacity { NumberAnimation { duration: 160 } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Keys.onEscapePressed: root.close()
            // Consume clicks on panel padding before they reach the outside catcher.
            MouseArea { anchors.fill: parent; acceptedButtons: Qt.AllButtons }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 26
                spacing: 16
                RowLayout {
                    Layout.fillWidth: true
                    ColumnLayout {
                        spacing: 3
                        Text { text: "Applications"; color: "#f1f4fb"; font { family: "Noto Sans"; pixelSize: 26; weight: Font.DemiBold } }
                        Text { text: "Your next idea starts here"; color: "#9ca8bd"; font { family: "Noto Sans"; pixelSize: 12 } }
                    }
                    Item { Layout.fillWidth: true }
                    Button {
                        text: "Esc"
                        focusPolicy: Qt.NoFocus
                        onClicked: root.close()
                        contentItem: Text { text: parent.text; color: "#aebbd1"; font.pixelSize: 11; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                        background: Rectangle { implicitWidth: 40; implicitHeight: 28; radius: 8; color: parent.hovered ? "#354155" : "#252d3b"; border.color: "#405069" }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 58
                    radius: 16
                    color: "#a0121721"
                    border.color: search.activeFocus ? "#8ab4ff" : "#465269"
                    Behavior on border.color { ColorAnimation { duration: 160 } }
                    RowLayout {
                        anchors.fill: parent; anchors.leftMargin: 18; anchors.rightMargin: 12; spacing: 12
                        Text { text: "⌕"; color: "#8ab4ff"; font.pixelSize: 28 }
                        TextField {
                            id: search
                            Layout.fillWidth: true
                            text: root.query
                            onTextChanged: { root.query = text; list.currentIndex = 0; }
                            placeholderText: "Search applications…"
                            placeholderTextColor: "#7f8ba0"
                            color: "#f1f4fb"
                            font { family: "Noto Sans"; pixelSize: 16 }
                            background: Item {}
                            selectByMouse: true
                            Keys.onDownPressed: root.move(1)
                            Keys.onUpPressed: root.move(-1)
                            Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
                            Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
                            Keys.onEscapePressed: root.close()
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_P && (event.modifiers & Qt.ControlModifier)) {
                                    const app = root.results[list.currentIndex];
                                    if (app) root.pin(app);
                                    event.accepted = true;
                                }
                            }
                        }
                        ToolButton { text: "×"; visible: root.query.length > 0; focusPolicy: Qt.NoFocus; onClicked: { root.query = ""; search.forceActiveFocus(); } }
                    }
                }
                ColumnLayout {
                    Layout.fillWidth: true
                    visible: !root.query.trim()
                    spacing: 10
                    Text { text: "FAVORITES"; color: "#93a4bf"; font { family: "Noto Sans"; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.8 } }
                    ListView {
                        Layout.fillWidth: true
                        implicitHeight: root.favorites.length ? 98 : 36
                        orientation: ListView.Horizontal
                        spacing: 10
                        clip: true
                        model: root.favorites
                        ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }
                        Text { visible: !root.favorites.length; text: "Star an app below to keep it close."; color: "#9ca8bd"; font.pixelSize: 13; anchors.verticalCenter: parent.verticalCenter }
                        delegate: Button {
                            id: favorite
                            required property var modelData
                            width: 100; height: 88
                            onClicked: root.launch(modelData)
                            ToolTip.visible: hovered
                            ToolTip.text: modelData.name
                            background: Rectangle {
                                radius: 16; color: favorite.hovered || favorite.activeFocus ? "#66516a91" : "#302f3d55"
                                border.color: favorite.hovered || favorite.activeFocus ? "#688ab4ff" : "#204e6180"
                                Behavior on color { ColorAnimation { duration: 140 } }
                            }
                            contentItem: Item {
                                Column {
                                  anchors.centerIn: parent
                                  width: parent.width
                                  spacing: 8
                                  Item {
                                      anchors.horizontalCenter: parent.horizontalCenter; width: 32; height: 32
                                      Text { anchors.centerIn: parent; visible: favoriteIcon.status !== Image.Ready; text: favorite.modelData.name.charAt(0); color: "#a9c9ff"; font.pixelSize: 24 }
                                      Image { id: favoriteIcon; anchors.fill: parent; source: Quickshell.iconPath(favorite.modelData.icon, "application-x-executable"); sourceSize.width: 32; sourceSize.height: 32 }
                                  }
                                  Text { width: parent.width; text: favorite.modelData.name; color: "#e5ecf9"; elide: Text.ElideRight; horizontalAlignment: Text.AlignHCenter; font { family: "Noto Sans"; pixelSize: 11 } }
                                }
                            }
                            Keys.onEscapePressed: root.close()
                        }
                    }
                }
                RowLayout {
                    Layout.fillWidth: true
                    Text { text: root.query.trim() ? "SEARCH RESULTS" : "ALL APPLICATIONS"; color: "#93a4bf"; font { family: "Noto Sans"; pixelSize: 10; weight: Font.DemiBold; letterSpacing: 1.8 } }
                    Item { Layout.fillWidth: true }
                    Text { text: root.results.length; color: "#74859f"; font.pixelSize: 11 }
                }
                ListView {
                    id: list
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 5
                    model: root.results
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                    delegate: Rectangle {
                        id: row
                        required property var modelData
                        required property int index
                        width: list.width - 12
                        height: 62
                        radius: 14
                        color: ListView.isCurrentItem ? "#554c6d9e" : rowMouse.containsMouse ? "#303f4e68" : "transparent"
                        border.color: ListView.isCurrentItem ? "#507da9ee" : "transparent"
                        Behavior on color { ColorAnimation { duration: 120 } }
                        MouseArea { id: rowMouse; anchors.fill: parent; hoverEnabled: true; onClicked: root.launch(row.modelData) }
                        RowLayout {
                            anchors.fill: parent; anchors.margins: 10; spacing: 13
                            Item {
                                Layout.preferredWidth: 34; Layout.preferredHeight: 34
                                Text { anchors.centerIn: parent; visible: appIcon.status !== Image.Ready; text: row.modelData.name.charAt(0); color: "#a9c9ff"; font.pixelSize: 24 }
                                Image { id: appIcon; anchors.fill: parent; source: Quickshell.iconPath(row.modelData.icon, "application-x-executable"); sourceSize.width: 34; sourceSize.height: 34 }
                            }
                            ColumnLayout {
                                Layout.fillWidth: true; spacing: 3
                                Text { Layout.fillWidth: true; text: row.modelData.name; color: "#edf2fc"; elide: Text.ElideRight; font { family: "Noto Sans"; pixelSize: 14; weight: Font.Medium } }
                                Text { Layout.fillWidth: true; text: row.modelData.genericName || row.modelData.comment || "Application"; color: "#95a4bb"; elide: Text.ElideRight; font { family: "Noto Sans"; pixelSize: 11 } }
                            }
                            Button {
                                id: star
                                readonly property bool pinned: root.isFavorite(row.modelData)
                                text: pinned ? "★" : "☆"
                                focusPolicy: Qt.NoFocus
                                onClicked: root.pin(row.modelData)
                                ToolTip.visible: hovered
                                ToolTip.text: pinned ? "Remove from favorites" : "Add to favorites"
                                Accessible.name: ToolTip.text + ": " + row.modelData.name
                                contentItem: Text { text: star.text; color: star.pinned ? "#a9c9ff" : "#8b9bb3"; font.pixelSize: 23; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { implicitWidth: 36; implicitHeight: 36; radius: 10; color: star.hovered ? "#455774" : "transparent" }
                            }
                        }
                    }
                    Column {
                        visible: root.results.length === 0
                        anchors.centerIn: parent; spacing: 10
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No applications found"; color: "#e5ecf9"; font.pixelSize: 17 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "Try another name or keyword."; color: "#95a4bb"; font.pixelSize: 12 }
                    }
                }
                Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: "#20a9c0e5" }
                Text { Layout.fillWidth: true; text: root.saveError || "↑ ↓  Navigate     ↵  Open     Ctrl P  Favorite     Esc  Close"; color: root.saveError ? "#ffb4ab" : "#8192ae"; font { family: "Noto Sans"; pixelSize: 11 } elide: Text.ElideRight }
            }
        }
    }
}
