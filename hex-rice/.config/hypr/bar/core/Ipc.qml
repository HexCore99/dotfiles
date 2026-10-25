// Diagnostic and workspace commands for barctl and verification.
// The powerMenu command toggles the popup but never executes a system action.
import QtQuick
import Quickshell.Io
import "../services"
IpcHandler {
    target: "bar"
    function soundMenu(): void { SoundState.toggle(); }
    function soundStatus(): string { return JSON.stringify({opened: SoundState.opened, error: SoundService.error, data: SoundService.data}); }
    function wallpaperMenu(): void { WallpaperState.toggle(); }
    function wallpaperStatus(): string {
        return JSON.stringify({opened: WallpaperState.opened, loading: WallpaperService.loading,
            applying: WallpaperService.applying, active: WallpaperService.activePath,
            folder: WallpaperService.folder, count: WallpaperService.items.length, error: WallpaperService.error});
    }
    // This toggles the menu only; it cannot execute a system power action.
    function powerMenu(): void { PowerState.toggle(); }
    function bluetoothMenu(): void { BluetoothState.toggle(); }
    function bluetoothStatus(): string {
        return JSON.stringify({opened: BluetoothState.opened, enabled: BluetoothState.enabled,
            ready: BluetoothState.ready, busy: BluetoothState.busy, error: BluetoothState.error,
            connected: BluetoothState.connected.map(d => d.name),
            paired: BluetoothState.saved.map(d => d.name), nearby: BluetoothState.nearby.map(d => d.name)});
    }
    function wifiMenu(): void { WifiState.toggle(); }
    function wifiStatus(): string {
        // Deliberately exclude secrets from diagnostics.
        return JSON.stringify({opened: WifiState.opened, enabled: WifiState.enabled,
            available: WifiState.available, connected: WifiState.connected ? WifiState.connected.name : "",
            networks: WifiState.others.map(n => ({name: n.name, known: n.known, security: WifiState.securityLabel(n)})),
            passwordRequired: WifiState.passwordRequired, connecting: WifiState.connecting, error: WifiState.error});
    }
    function status(): string {
        return JSON.stringify({powerMenuOpen: PowerState.opened, workspace: HyprlandService.workspaceName,
            fullscreen: HyprlandService.fullscreen, locked: SessionService.locked,
            network: NetworkService.label, signal: NetworkService.signal,
            bluetooth: BluetoothService.detail, battery: BatteryService.label,
            cpu: SystemService.cpu, memory: SystemService.memory,
            volume: AudioService.percent, muted: AudioService.muted});
    }
    function workspace(id: int): void { HyprlandService.focusWorkspace(id); }
}
