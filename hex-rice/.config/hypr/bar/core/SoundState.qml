pragma Singleton
import QtQuick
import "../services"
QtObject {
    id: root
    property bool opened: false
    function toggle() {
        if (opened) close();
        else { PowerState.close(); WifiState.close(); BluetoothState.close(); WallpaperState.close(); opened = true; }
    }
    function close() { opened = false; }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections fullscreen: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
}
