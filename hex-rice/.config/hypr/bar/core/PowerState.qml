// Small shared state for the far-right power button and its popup.
// Keep the selected tile and action routing out of the visual layout files.
pragma Singleton
import QtQuick
import "../services"
QtObject {
    id: root
    property bool opened: false
    property int selected: 0
    // Row order in the two-column grid: Lock / Sleep, Restart / Power off.
    readonly property var choices: [
        {action: "lock", label: "Lock", icon: "lock-keyhole"},
        {action: "sleep", label: "Sleep", icon: "moon"},
        {action: "restart", label: "Restart", icon: "rotate-cw"},
        {action: "poweroff", label: "Power off", icon: "power"}
    ]
    function toggle(): void {
        SoundState.close();
        if (opened) close();
        else { WallpaperState.close(); WifiState.close(); BluetoothState.close(); selected = 0; opened = true; }
    }
    function close(): void { opened = false; }
    function activate(action: string): void {
        if (!choices.some(choice => choice.action === action)) return;
        // Release keyboard focus before a lock or system authentication dialog.
        close();
        Actions.power(action);
    }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections fullscreen: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
}
