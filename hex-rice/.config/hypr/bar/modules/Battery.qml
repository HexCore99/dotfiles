// Real battery percentage, with a subtle warning color below 20 percent.
// Hover shows charge state; click reads detailed battery data from UPower.
import QtQuick
import ".."
import "../core"
import "../components"
import "../services"
BarButton {
    iconComponent: Component {
        BatteryIcon {
            percent: BatteryService.percent
            available: BatteryService.available
            charging: BatteryService.charging
            color: BatteryService.available && BatteryService.percent < 20 ? Settings.warning : Settings.foreground
        }
    }
    text: BatteryService.label
    foreground: BatteryService.available && BatteryService.percent < 20 ? Settings.warning : Settings.foreground
    hint: BatteryService.detail + " · click for battery details"
    onClicked: Actions.run("battery")
}
