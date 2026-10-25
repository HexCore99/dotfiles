// Read the laptop battery through UPower. Its percentage is a fraction
// (0 to 1), so multiply by 100 only for display. AC-only systems show AC.
pragma Singleton
import QtQuick
import Quickshell.Services.UPower
QtObject {
    readonly property var device: UPower.displayDevice
    readonly property bool available: device && device.ready && device.isPresent
    readonly property int percent: available ? Math.round(device.percentage * 100) : 0
    readonly property bool charging: available && device.state === UPowerDeviceState.Charging
    readonly property string label: available ? percent + "%" : "AC"
    readonly property string detail: !available ? "External power" : charging ? "Charging · " + percent + "%" : percent + "% remaining"
}
