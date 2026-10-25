// One independent bar card. Modules keep their existing actions and sizing;
// this reusable frame adds only a background, border and horizontal padding.
import QtQuick
import ".."
Rectangle {
    id: root
    default property alias content: controls.data
    property alias spacing: controls.spacing
    implicitWidth: controls.implicitWidth + Settings.barGroupPadding * 2
    implicitHeight: Settings.height
    radius: Settings.barRadius
    color: Qt.rgba(Settings.background.r, Settings.background.g, Settings.background.b,
        Math.max(0, Math.min(1, Settings.barGroupOpacity)))
    border.width: Settings.barGroupBorderWidth
    border.color: Settings.border
    Row {
        id: controls
        anchors.centerIn: parent
        spacing: Settings.barGroupSpacing
    }
}
