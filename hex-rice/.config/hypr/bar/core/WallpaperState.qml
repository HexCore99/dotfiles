// Shared popup state; visual layout and backend operations live in other files.
pragma Singleton
import QtQuick
import "../services"
QtObject {
    id: root
    property bool opened: false
    function toggle(): void {
        SoundState.close();
        if (opened) close();
        else { PowerState.close(); WifiState.close(); BluetoothState.close(); opened = true; WallpaperService.refresh(); }
    }
    function close(): void { opened = false; }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections fullscreen: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
}
