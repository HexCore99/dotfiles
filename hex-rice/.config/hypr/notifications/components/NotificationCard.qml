pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../bar"
import "../../bar/components"
import "../services"
Rectangle {
    id: card
    required property var entry
    // The server may destroy the object before the removal transition finishes.
    readonly property var notification: entry.notification || ({id: -1, urgency: 0, appIcon: "", appName: "", summary: "", body: "", image: "", actions: []})
    implicitHeight: content.implicitHeight + 28
    radius: 18
    color: hover.hovered ? NotificationTheme.hover : NotificationTheme.card
    border.color: notification?.urgency === 2 ? NotificationTheme.accent : NotificationTheme.control
    border.width: notification?.urgency === 2 || hover.hovered ? 1 : 0
    Behavior on color { ColorAnimation { duration: 160 } }
    HoverHandler { id: hover; cursorShape: Qt.PointingHandCursor }
    MouseArea { anchors.fill: parent; onClicked: NotificationStore.activate((card.notification?.id ?? -1)) }
    ColumnLayout {
        id: content
        anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
        spacing: 9
        RowLayout {
            Layout.fillWidth: true; spacing: 9
            Rectangle {
                implicitWidth: 32; implicitHeight: 32; radius: 10; color: NotificationTheme.control
                SvgIcon { anchors.centerIn: parent; name: "bell"; color: NotificationTheme.accent; visible: appImage.status !== Image.Ready || !appImage.source.toString() }
                Image {
                    id: appImage
                    readonly property string icon: (card.notification?.appIcon ?? "")
                    readonly property string candidate: !icon ? "" : icon.includes(":") || icon.startsWith("/") ? icon : Quickshell.hasThemeIcon(icon) ? Quickshell.iconPath(icon) : ""
                    source: candidate
                    anchors.fill: parent; anchors.margins: 6
                    sourceSize.width: 40; sourceSize.height: 40; fillMode: Image.PreserveAspectFit
                }
            }
            Text {
                Layout.fillWidth: true
                text: (card.notification?.appName ?? "") || "Notification"; textFormat: Text.PlainText
                elide: Text.ElideRight; color: NotificationTheme.muted
                font { family: Settings.notificationFont; pixelSize: 12; weight: Font.Medium }
            }
            Text { text: NotificationStore.age(card.entry.received); color: NotificationTheme.muted; font { family: Settings.notificationFont; pixelSize: 11 } }
            Rectangle { visible: card.entry.unread; implicitWidth: 6; implicitHeight: 6; radius: 3; color: NotificationTheme.accent }
            NotificationControl { text: "×"; outlined: true; implicitWidth: 28; implicitHeight: 28; Accessible.name: "Dismiss notification"; onClicked: NotificationStore.dismiss((card.notification?.id ?? -1)) }
        }
        Text {
            Layout.fillWidth: true
            text: (card.notification?.summary ?? ""); textFormat: Text.PlainText
            color: NotificationTheme.text
            font { family: Settings.notificationFont; pixelSize: 15; weight: Font.DemiBold }
            wrapMode: Text.Wrap; maximumLineCount: 3; elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true; visible: text !== ""
            text: (card.notification?.body ?? ""); textFormat: Text.PlainText
            color: NotificationTheme.muted; lineHeight: 1.25
            font { family: Settings.notificationFont; pixelSize: 13 }
            wrapMode: Text.Wrap; maximumLineCount: 6; elide: Text.ElideRight
        }
        Image {
            Layout.fillWidth: true; Layout.preferredHeight: visible ? 120 : 0
            visible: !!(card.notification?.image ?? "") && !(card.notification?.image ?? "").startsWith("image://icon/") && status === Image.Ready
            source: (card.notification?.image ?? "") && !(card.notification?.image ?? "").startsWith("image://icon/") ? (card.notification?.image ?? "") : ""
            fillMode: Image.PreserveAspectFit; sourceSize.width: 400; sourceSize.height: 240
        }
        Flow {
            Layout.fillWidth: true
            Layout.preferredHeight: childrenRect.height
            spacing: 8
            Repeater {
                model: (card.notification?.actions ?? [])
                NotificationControl {
                    required property var modelData
                    text: modelData.text || (modelData.identifier === "default" ? "Open" : "Action")
                    onClicked: NotificationStore.invoke((card.notification?.id ?? -1), modelData.identifier)
                }
            }
        }
    }
}
