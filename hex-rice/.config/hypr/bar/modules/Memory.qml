// RAM percentage uses MemAvailable, so reclaimable caches are not counted
// as unavailable memory. Click opens btop for a detailed breakdown.
import QtQuick
import "../core"
import "../components"
import "../services"
BarButton {
    icon: "memory-stick" // Lucide SVG, sized through Settings.iconSize.
    text: SystemService.memory + "%"
    hint: "RAM usage · click for system monitor"
    onClicked: Actions.run("monitor")
}
