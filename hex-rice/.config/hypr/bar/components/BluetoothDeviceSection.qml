// Connected, saved and nearby lists share the same modular section renderer.
import QtQuick
import ".."
Column {
    id: section
    required property string title
    required property var devices
    visible: devices.length > 0
    spacing: Settings.bluetoothSpacing
    Text { text: section.title; color: Settings.bluetoothMuted; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize - 1 }
    Repeater {
        model: section.devices
        BluetoothDeviceRow { required property var modelData; device: modelData; width: section.width }
    }
}
