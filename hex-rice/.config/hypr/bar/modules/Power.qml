// The rightmost bar item. It toggles the native four-tile Quickshell power menu.
import QtQuick
import "../components"
import "../core"
BarButton {
    icon: "power"
    horizontalPadding: 6
    hint: "Power menu · Lock, Sleep, Restart, Power off"
    onClicked: PowerState.toggle()
}
