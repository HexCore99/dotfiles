// One focus-grab popup at a time. Popups are separate and never share a layout.
pragma Singleton
import QtQuick
import "../../bar/services"
QtObject {
    id: root
    property string opened: ""
    function toggle(name: string): void { opened = opened === name ? "" : name; }
    function close(): void { opened = ""; }
    property Connections session: Connections {
        target: SessionService
        function onLockedChanged() { if (SessionService.locked) root.close(); }
    }
    property Connections desktop: Connections {
        target: HyprlandService
        function onFullscreenChanged() { root.close(); }
    }
}
