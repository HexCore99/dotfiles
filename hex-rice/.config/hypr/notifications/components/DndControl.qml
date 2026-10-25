// Focus-mode card with an animated, keyboard-accessible DND switch.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import "../../bar"
import "../../bar/components"
import "../services"
Rectangle {
    implicitHeight: Settings.notificationDndHeight
    color: NotificationStore.dnd ? Qt.tint(NotificationTheme.card, Qt.rgba(NotificationTheme.accent.r, NotificationTheme.accent.g, NotificationTheme.accent.b, 0.12)) : NotificationTheme.card
    border.width: 1
    border.color: NotificationStore.dnd ? NotificationTheme.accent : NotificationTheme.control
    Behavior on color { ColorAnimation { duration: 180 } }
    radius: Settings.notificationRadius
    RowLayout {
        anchors.fill: parent
        anchors.margins: Settings.notificationCardPadding
        spacing: Settings.notificationSpacing
        Rectangle {
            Layout.preferredWidth: Settings.notificationIconSize - 4
            Layout.preferredHeight: Settings.notificationIconSize - 4
            color: NotificationTheme.control
            radius: Settings.notificationSpacing + 4
            SvgIcon { anchors.centerIn: parent; name: "moon"; width: 24; height: 24; color: NotificationTheme.muted }
        }
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0
            Text { text: "Quiet mode"; color: NotificationTheme.text; font.family: Settings.notificationFont; font.pixelSize: Settings.notificationTextSize }
            Text { text: NotificationStore.dnd ? "Saved here. No interruptions." : "Let notifications come through."; color: NotificationTheme.muted; font.family: Settings.notificationFont; font.pixelSize: Settings.notificationTextSize - 2 }
        }
        Switch {
            id: toggle
            Accessible.name: "Do not disturb"
            HoverHandler { cursorShape: Qt.PointingHandCursor }
            checked: NotificationStore.dnd
            onToggled: NotificationStore.dnd = checked
            implicitWidth: Settings.notificationSwitchWidth
            implicitHeight: Settings.notificationSwitchHeight
            padding: 0
            indicator: Rectangle {
                implicitWidth: Settings.notificationSwitchWidth
                implicitHeight: Settings.notificationSwitchHeight
                radius: height / 2
                color: toggle.checked ? NotificationTheme.accent : NotificationTheme.control
                Behavior on color { ColorAnimation { duration: 160 } }
                border.width: toggle.visualFocus ? 1 : 0
                border.color: NotificationTheme.text
                Rectangle {
                    width: parent.height - 8; height: width
                    x: toggle.checked ? parent.width - width - 4 : 4
                    Behavior on x { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                    anchors.verticalCenter: parent.verticalCenter
                    radius: width / 2
                    color: "white"
                }
            }
        }
    }
}
