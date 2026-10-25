// The bell immediately left of the date toggles notification history only.
import QtQuick
import "../components"
import "../core"
BarButton {
    icon: "bell"
    horizontalPadding: 6
    onClicked: Actions.run("notifications")
}
