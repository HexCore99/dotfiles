// A masked password exists only in this TextField. Clear it after submission,
// cancellation, changing networks or closing the overlay.
import QtQuick
import QtQuick.Controls.Basic
import QtQuick.Layouts
import ".."
import "../core"
ColumnLayout {
    id: form
    spacing: Settings.wifiSpacing
    Text {
        text: WifiState.selected ? "Connect to " + WifiState.selected.name : ""
        textFormat: Text.PlainText; wrapMode: Text.Wrap
        color: Settings.wifiText; font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize
        Layout.fillWidth: true
    }
    TextField {
        id: password
        objectName: "wifiPassword"
        Layout.fillWidth: true
        implicitHeight: Settings.wifiPasswordHeight
        enabled: !WifiState.connecting
        placeholderText: "Wi-Fi password"
        echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
        inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        selectByMouse: true
        color: Settings.wifiText; placeholderTextColor: Settings.wifiMuted
        selectionColor: Settings.wifiAccent; selectedTextColor: Settings.wifiBackground
        font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize
        leftPadding: Settings.wifiSpacing; rightPadding: Settings.wifiSpacing
        background: Rectangle {
            color: Settings.wifiCard; radius: Settings.wifiSpacing
            border.width: 1; border.color: password.activeFocus ? Settings.wifiAccent : Settings.panelBorder
        }
        onAccepted: WifiState.submit(text)
    }
    CheckBox {
        id: showPassword
        text: "Show password"
        font.family: Settings.wifiFont; font.pixelSize: Settings.wifiTextSize - 2
        contentItem: Text { text: showPassword.text; leftPadding: showPassword.indicator.width + 8; color: Settings.wifiMuted; font: showPassword.font; verticalAlignment: Text.AlignVCenter }
    }
    RowLayout {
        Layout.fillWidth: true
        WifiButton { text: "Cancel"; enabled: !WifiState.connecting; Layout.fillWidth: true; onClicked: WifiState.reset() }
        WifiButton { text: WifiState.connecting ? "Connecting…" : "Connect"; primary: true; enabled: password.text.length > 0 && !WifiState.connecting; Layout.fillWidth: true; onClicked: WifiState.submit(password.text) }
    }
    Connections {
        target: WifiState
        function onClearPassword() { password.clear(); showPassword.checked = false; }
    }
    onVisibleChanged: { if (visible) password.forceActiveFocus(); else password.clear(); }
}
