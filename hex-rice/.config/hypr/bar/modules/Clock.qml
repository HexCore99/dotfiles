// The clock shares a centered card with notifications, arranged by Bar.qml.
// SystemClock updates once per minute; clicking opens an informational calendar.
import QtQuick
import Quickshell
import ".."
import "../core"
import "../components"
BarButton {
    SystemClock { id: clock; precision: SystemClock.Minutes }
    // Match the reference wording while always displaying the real current date.
    text: Qt.formatDateTime(clock.date, Settings.clockFormat)
    textSize: Settings.clockFontSize
    hint: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy") + " · click for calendar"
    onClicked: Actions.run("calendar")
}
