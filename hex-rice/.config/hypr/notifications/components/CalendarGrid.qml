// Calendar arithmetic uses noon to avoid daylight-saving changes at midnight.
// Adjacent-month days stay selectable, and Today always returns to this month.
import QtQuick
import QtQuick.Layouts
import "../../bar"
ColumnLayout {
    id: grid
    property date today: new Date()
    property date selected: today
    property int month: today.getMonth()
    property int year: today.getFullYear()
    readonly property date first: new Date(year, month, 1, 12)
    readonly property string title: Qt.formatDateTime(first, "MMMM yyyy")
    function move(delta): void {
        const date = new Date(year, month + delta, 1, 12);
        year = date.getFullYear(); month = date.getMonth();
    }
    function reset(): void { selected = today; year = today.getFullYear(); month = today.getMonth(); }
    spacing: Settings.panelGap
    RowLayout {
        Layout.fillWidth: true
        PanelButton { text: "‹"; onClicked: grid.move(-1) }
        Text { text: grid.title; color: Settings.panelAccent; font.family: Settings.font; font.pixelSize: Settings.panelFontSize; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        PanelButton { text: "›"; onClicked: grid.move(1) }
    }
    GridLayout {
        Layout.fillWidth: true
        columns: 7; rowSpacing: 2; columnSpacing: 2
        Repeater {
            model: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
            Text { required property string modelData; text: modelData; color: Settings.panelAccent; font.family: Settings.font; font.pixelSize: Settings.panelFontSize - 1; Layout.fillWidth: true; horizontalAlignment: Text.AlignHCenter }
        }
        Repeater {
            model: 42
            PanelButton {
                required property int index
                readonly property date day: new Date(grid.year, grid.month, index - grid.first.getDay() + 1, 12)
                text: day.getDate()
                selected: day.toDateString() === grid.selected.toDateString()
                opacity: day.getMonth() === grid.month ? 1 : 0.4
                Layout.fillWidth: true; Layout.preferredWidth: 1
                implicitHeight: Settings.calendarCellHeight
                onClicked: { grid.selected = day; grid.year = day.getFullYear(); grid.month = day.getMonth(); }
            }
        }
    }
    PanelButton { text: "Today"; Layout.fillWidth: true; onClicked: grid.reset() }
}
