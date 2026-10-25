// CPU utilization, computed from changes in /proc/stat rather than load average.
// Clicking opens btop in a terminal so the displayed number is inspectable.
import QtQuick
import "../core"
import "../components"
import "../services"
BarButton {
    icon: "cpu" // Lucide SVG, sized through Settings.iconSize.
    text: SystemService.cpu + "%"
    hint: "CPU usage · click for system monitor"
    onClicked: Actions.run("monitor")
}
