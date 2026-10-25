// BlueZ chooses the prompt type: PIN input, passkey display, or confirmation.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../core"
ColumnLayout {
    id: form
    readonly property string kind: BluetoothState.prompt ? BluetoothState.prompt.kind : ""
    spacing: Settings.bluetoothSpacing
    Text {
        text: form.kind === "display" ? "Type this code on the other device, then press Enter:"
            : form.kind === "confirm" ? "Does this code match the one on your device?"
            : form.kind === "authorize" ? "Allow pairing with this device?"
            : "Enter the PIN or passkey from the other device."
        color: Settings.bluetoothText; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize
        Layout.fillWidth: true; wrapMode: Text.Wrap
    }
    Text {
        visible: form.kind === "display" || form.kind === "confirm"
        text: BluetoothState.prompt ? BluetoothState.prompt.code || "" : ""
        color: Settings.bluetoothAccent; font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTitleSize + 6
        Layout.alignment: Qt.AlignHCenter
    }
    TextField {
        id: code
        objectName: "bluetoothPairingCode"
        visible: form.kind === "pin" || form.kind === "passkey"
        Layout.fillWidth: true; implicitHeight: Settings.wifiPasswordHeight
        placeholderText: form.kind === "passkey" ? "Numeric passkey" : "PIN code"
        maximumLength: form.kind === "passkey" ? 6 : 16
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        echoMode: TextInput.Password
        color: Settings.bluetoothText; placeholderTextColor: Settings.bluetoothMuted
        font.family: Settings.bluetoothFont; font.pixelSize: Settings.bluetoothTextSize
        leftPadding: Settings.bluetoothSpacing
        background: Rectangle { color: Settings.bluetoothCard; radius: Settings.bluetoothSpacing; border.width: 1; border.color: code.activeFocus ? Settings.bluetoothAccent : Settings.bluetoothHover }
        onAccepted: { if (text.length > 0) BluetoothState.respond(true, text); }
    }
    RowLayout {
        Layout.fillWidth: true
        BluetoothButton { text: "Cancel"; Layout.fillWidth: true; onClicked: BluetoothState.cancelPairing() }
        BluetoothButton {
            visible: form.kind !== "display"
            text: form.kind === "confirm" || form.kind === "authorize" ? "Confirm" : "Submit"
            enabled: !code.visible || code.text.length > 0
            primary: true; Layout.fillWidth: true
            onClicked: BluetoothState.respond(true, code.text)
        }
    }
    Connections { target: BluetoothState; function onClearCode() { code.clear(); } }
    onVisibleChanged: { if (visible && code.visible) code.forceActiveFocus(); else code.clear(); }
}
