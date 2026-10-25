// Read workspaces, monitor, and fullscreen state from Hyprland IPC events.
// Keep Lua dispatcher syntax compatible with your installed Hyprland version.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
QtObject {
    id: root
    readonly property var screen: Quickshell.screens.find(s => s.name === Settings.monitor) || Quickshell.screens[0] || null
    readonly property var monitor: screen ? Hyprland.monitorFor(screen) : null
    readonly property var workspace: monitor ? monitor.activeWorkspace : null
    readonly property string workspaceName: workspace ? workspace.name : "1"
    readonly property var workspaces: Hyprland.workspaces.values.filter(w => w.id > 0 && (!monitor || w.monitor === monitor))
    readonly property bool fullscreen: Hyprland.toplevels.values.some(w => {
        const o = w.lastIpcObject;
        return o && o.fullscreen >= 2 && workspace && o.workspace
            && o.workspace.id === workspace.id && (!monitor || o.monitor === monitor.id);
    })
    function focusWorkspace(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua ? 'hl.dsp.focus({workspace = ' + id + '})' : 'workspace ' + id);
    }
    function toplevelAddress(toplevel): string {
        const rawAddress = toplevel ? String(toplevel.address || "") : "";
        const address = rawAddress.startsWith("0x") ? rawAddress : "0x" + rawAddress;
        return /^0x[0-9a-f]+$/i.test(address) ? address : "";
    }
    property string pendingFocusAddress: ""
    function dispatchToplevelFocus(address: string): void {
        Hyprland.dispatch(Hyprland.usingLua
            ? 'hl.dsp.focus({window = "address:' + address + '"})'
            : 'focuswindow address:' + address);
    }
    function focusToplevel(toplevel): void {
        const address = toplevelAddress(toplevel);
        if (!address) return;
        const targetWorkspace = toplevel.workspace;
        if (targetWorkspace && targetWorkspace.id > 0
            && (!Hyprland.focusedWorkspace || Hyprland.focusedWorkspace.id !== targetWorkspace.id)) {
            pendingFocusAddress = address;
            focusWorkspace(targetWorkspace.id);
            focusWindowDelay.restart();
        } else {
            focusWindowDelay.stop();
            pendingFocusAddress = "";
            dispatchToplevelFocus(address);
        }
    }
    function forceKillToplevel(toplevel): void {
        const address = toplevelAddress(toplevel);
        if (!address) return;
        Hyprland.dispatch(Hyprland.usingLua
            ? 'hl.dsp.window.kill({window = "address:' + address + '"})'
            : 'killwindow address:' + address);
    }
    property Timer focusWindowDelay: Timer {
        interval: 90
        onTriggered: {
            if (root.pendingFocusAddress) root.dispatchToplevelFocus(root.pendingFocusAddress);
            root.pendingFocusAddress = "";
        }
    }
    property Connections events: Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (["fullscreen", "activewindowv2", "movewindowv2", "openwindow", "closewindow"].includes(event.name))
                refresh.restart();
        }
    }
    property Timer refresh: Timer {
        interval: 60
        onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors(); }
    }
}
