// Quickshell-hosted tests use fake network objects. No test changes the radio,
// joins a real network, reads stored credentials or interrupts the connection.
import QtQuick
import Quickshell
import Quickshell.Networking
import "../core"
import "../components"
Scope {
    id: test
    property Component formFactory: Component { WifiPasswordForm { visible: false } }
    property int clears: 0
    property QtObject network: QtObject {
        property string name: "Test network"
        property bool known: false
        property bool connected: false
        property bool stateChanging: false
        property int security: WifiSecurityType.Wpa2Psk
        property int connects: 0
        property int passwords: 0
        signal connectionFailed(int reason)
        function connect(): void { connects++; }
        function connectWithPsk(password: string): void { passwords++; }
    }
    Connections { target: WifiState; function onClearPassword() { test.clears++; } }
    function check(value, message): void { if (!value) throw new Error(message); }
    Timer {
        interval: 50; running: true
        onTriggered: {
            try {
                const form = test.formFactory.createObject(null);
                const field = form.children.find(item => item.objectName === "wifiPassword");
                test.check(field !== undefined, "Password field created");
                WifiState.choose(test.network);
                test.check(WifiState.passwordRequired && test.network.connects === 0, "New secured network prompts before connecting");
                WifiState.submit("");
                test.check(!WifiState.connecting && WifiState.error !== "", "Empty password rejected");
                field.text = "test-password-only";
                WifiState.submit(field.text);
                test.check(field.text === "", "Password field cleared after submission");
                test.check(test.network.passwords === 1 && WifiState.connecting, "Password sent to network API");
                test.network.connectionFailed(ConnectionFailReason.NoSecrets);
                test.check(WifiState.passwordRequired && !WifiState.connecting, "Authentication failure permits retry");
                test.network.connected = true;
                test.check(!WifiState.passwordRequired && WifiState.message !== "", "Connection success clears prompt");
                WifiState.reset(); test.network.connected = false; test.network.known = true;
                WifiState.choose(test.network);
                test.check(test.network.connects === 1 && !WifiState.passwordRequired, "Saved network reuses stored credentials");
                test.network.connectionFailed(ConnectionFailReason.NoSecrets);
                test.check(WifiState.passwordRequired, "Saved network with missing credentials requests password");
                WifiState.reset(); test.network.known = false; test.network.security = WifiSecurityType.Open;
                WifiState.choose(test.network);
                test.check(test.network.connects === 2 && !WifiState.passwordRequired, "Open network connects without password");
                WifiState.reset(); test.network.security = WifiSecurityType.Wpa2Eap;
                WifiState.choose(test.network);
                test.check(!WifiState.connecting && WifiState.error !== "", "Enterprise network directs to advanced setup");
                const before = test.clears;
                field.text = "temporary-test-value";
                WifiState.close(); test.check(test.clears > before && field.text === "", "Closing clears typed password");
                WifiState.reset(); form.destroy();
                console.log("WIFI_FLOW_TESTS_PASSED"); Qt.exit(0);
            } catch (error) { console.error("WIFI_FLOW_TEST_FAILED", error); Qt.exit(1); }
        }
    }
}
