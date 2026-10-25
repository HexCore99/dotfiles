// Entry point: create the bar window and its small diagnostic IPC interface.
// The actual modules and system integrations live in separate folders.
//@ pragma IconTheme Papirus-Dark
import Quickshell
import "core"
import "popups"
ShellRoot {
    Bar {}
    Ipc {}
    PowerMenu {}
    WifiMenu {}
    BluetoothMenu {}
    WallpaperMenu {}
    SoundMenu {}
    VolumeOsd {}
}
