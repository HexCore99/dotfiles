pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import Quickshell.Wayland
import "../../bar"
import "../../bar/components"
import "../components"
import "../services"
import "../core"
PopupFrame {
    id: center
    property bool unreadOnly: false
    readonly property var entries: unreadOnly ? NotificationStore.history.filter(e => e.unread) : NotificationStore.history
    ListModel { id: notificationRows; dynamicRoles: true }
    function synchronize() {
        const wanted = entries;
        for (let i = 0; i < wanted.length; i++) {
            const entry = wanted[i];
            let found = -1;
            for (let j = i; j < notificationRows.count; j++)
                if (notificationRows.get(j).key === entry.notification.id) { found = j; break; }
            if (found < 0) notificationRows.insert(i, {key: entry.notification.id, payload: entry});
            else {
                if (found !== i) notificationRows.move(found, i, 1);
                notificationRows.setProperty(i, "payload", entry);
            }
        }
        if (notificationRows.count > wanted.length) notificationRows.remove(wanted.length, notificationRows.count - wanted.length);
    }
    onEntriesChanged: synchronize()
    Component.onCompleted: synchronize()
    shown: PanelState.opened === "notifications"
    animated: true
    cornerRadius: 26
    backgroundColor: NotificationTheme.background
    borderColor: NotificationTheme.border
    Behavior on backgroundColor { ColorAnimation { duration: 400 } }
    implicitWidth: Math.min(460, screen ? screen.width - 24 : 460)
    implicitHeight: Math.min(740, screen ? screen.height - margins.top - 16 : 740)
    WlrLayershell.namespace: "quickshell-notification-center"
    onDismissed: PanelState.close()
    body: ColumnLayout {
        spacing: 16
        RowLayout {
            Layout.fillWidth: true
            ColumnLayout {
                Layout.fillWidth: true; spacing: 5
                Text { text: "YOUR DAY, AT A GLANCE"; color: NotificationTheme.accent; font { family: Settings.notificationFont; pixelSize: 10; letterSpacing: 1.7; weight: Font.Bold } }
                Text { text: "Notifications"; color: NotificationTheme.text; font { family: Settings.notificationFont; pixelSize: 28; weight: Font.DemiBold } }
            }
            Item { Layout.fillWidth: true }
            NotificationControl { text: "×"; outlined: true; implicitWidth: 36; Accessible.name: "Close notifications"; onClicked: PanelState.close() }
        }
        DndControl { Layout.fillWidth: true }
        RowLayout {
            Layout.fillWidth: true; spacing: 8
            NotificationControl { text: "All  " + NotificationStore.count; accent: !center.unreadOnly; onClicked: center.unreadOnly = false }
            NotificationControl { text: "Unread  " + NotificationStore.unreadCount; accent: center.unreadOnly; onClicked: center.unreadOnly = true }
            Item { Layout.fillWidth: true }
            NotificationControl { text: "Read all"; outlined: true; enabled: NotificationStore.unreadCount > 0; onClicked: NotificationStore.markAllRead() }
        }
        Rectangle { Layout.fillWidth: true; implicitHeight: 1; color: NotificationTheme.control }
        Item {
            Layout.fillWidth: true; Layout.fillHeight: true
            ColumnLayout {
                anchors.centerIn: parent; width: parent.width - 36; spacing: 12
                visible: center.entries.length === 0
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 76; implicitHeight: 76; radius: 26; color: NotificationTheme.card
                    SvgIcon { anchors.centerIn: parent; name: "bell"; width: 28; height: 28; color: NotificationTheme.accent }
                }
                Text { Layout.fillWidth: true; text: center.unreadOnly ? "You're all caught up" : "A little peace and quiet"; horizontalAlignment: Text.AlignHCenter; color: NotificationTheme.text; font { family: Settings.notificationFont; pixelSize: 19; weight: Font.DemiBold } }
                Text { Layout.fillWidth: true; text: center.unreadOnly ? "No unread notifications to check." : "Your notifications will collect here.\nEnjoy the moment."; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; lineHeight: 1.4; color: NotificationTheme.muted; font { family: Settings.notificationFont; pixelSize: 13 } }
            }
            ListView {
                id: feed
                anchors.fill: parent; clip: true; spacing: 12
                model: notificationRows
                boundsBehavior: Flickable.StopAtBounds
                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
                add: Transition { NumberAnimation { properties: "opacity"; from: 0; to: 1; duration: 180 } NumberAnimation { properties: "x"; from: 18; to: 0; duration: 220; easing.type: Easing.OutCubic } }
                displaced: Transition { NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic } }
                delegate: Column {
                    id: group
                    required property var payload
                    required property int index
                    width: feed.width; spacing: 10
                    readonly property string day: Qt.formatDateTime(payload.received, "yyyy-MM-dd")
                    readonly property bool section: index === 0 || day !== Qt.formatDateTime(center.entries[index - 1].received, "yyyy-MM-dd")
                    Text {
                        visible: group.section
                        text: group.day === Qt.formatDateTime(NotificationStore.now, "yyyy-MM-dd") ? "TODAY" : Qt.formatDateTime(group.payload.received, "ddd, d MMM").toUpperCase()
                        color: NotificationTheme.muted; leftPadding: 4
                        font { family: Settings.notificationFont; pixelSize: 10; letterSpacing: 1.3; weight: Font.DemiBold }
                    }
                    NotificationCard { entry: group.payload; width: group.width }
                }
            }
        }
        RowLayout {
            Layout.fillWidth: true
            Text { Layout.fillWidth: true; text: NotificationStore.dnd ? "Quiet mode is on" : "Up to date · " + Qt.formatDateTime(NotificationStore.now, "h:mm AP"); color: NotificationTheme.muted; font { family: Settings.notificationFont; pixelSize: 11 } }
            NotificationControl { text: "Clear all"; enabled: NotificationStore.count > 0; onClicked: NotificationStore.clear() }
        }
    }
}
