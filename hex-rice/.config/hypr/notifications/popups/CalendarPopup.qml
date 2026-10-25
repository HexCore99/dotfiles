// Independent calendar with a live 12-hour clock. Uses the system's Dhaka timezone.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import "../../bar"
import "../components"
import "../core"
PopupFrame {
    shown: PanelState.opened === "calendar"
    implicitWidth: Settings.calendarWidth
    implicitHeight: Math.min(Settings.calendarHeight, screen ? screen.height - margins.top - 16 : Settings.calendarHeight)
    WlrLayershell.namespace: "quickshell-calendar"
    onDismissed: PanelState.close()
    body: ColumnLayout {
        spacing: Settings.panelGap
        SystemClock { id: clock; precision: SystemClock.Minutes }
        Text { text: Qt.formatDateTime(clock.date, "h:mm AP").split(" ")[0]; color: Settings.panelText; font.family: Settings.font; font.pixelSize: Settings.calendarClockSize; font.bold: true; Layout.alignment: Qt.AlignHCenter }
        Text { text: Qt.formatDateTime(clock.date, "AP · dddd, d MMMM"); color: Settings.panelMuted; font.family: Settings.font; font.pixelSize: Settings.panelFontSize; Layout.alignment: Qt.AlignHCenter }
        Rectangle {
            Layout.fillWidth: true; Layout.fillHeight: true
            color: Settings.panelCard; radius: Settings.panelRadius
            CalendarGrid { anchors.fill: parent; anchors.margins: Settings.panelGap; today: clock.date }
        }
    }
}
