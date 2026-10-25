// The small Arch icon at the left edge. Left-click opens applications;
// right-click opens the same four-option power menu as the rightmost power button.
import QtQuick
import ".."
import "../core"
import "../components"
BarButton {
    icon: "archlinux" // Separate brand SVG; Lucide does not supply brand logos.
    hint: "Applications · right-click for session menu"
    horizontalPadding: 10
    foreground: Settings.muted
    onClicked: Actions.run("launcher")
    onRightClicked: PowerState.toggle()
}
