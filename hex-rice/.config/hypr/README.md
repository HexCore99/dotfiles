# Your Hyprland desktop

## Move this desktop to a new Arch install

This config targets the Lua configuration used by current Hyprland. It was
prepared against Hyprland 0.56.2 and Quickshell 0.3.2. On this PC, make a clean
copy (the destination must not exist):

```sh
sh ~/.config/hypr/scripts/export-portable ~/hypr-portable
```

Copy the **contents** of `~/hypr-portable` to the new PC at
`~/.config/hypr`. If you already have a Hyprland config there, back it up
first. Then, as your normal user on the new Arch system, run:

```sh
sh ~/.config/hypr/scripts/setup-arch
```

The setup script installs the required Arch packages, enables NetworkManager
and Bluetooth, adds a Kitty include, recreates the local pywal Python
environment and Zsh integrations, and validates the Lua config. It needs
internet access and sudo for package installation. It does not change your
login shell. Log into Hyprland after setup.

The export excludes machine-specific wallpaper history and binaries. The lock
screen starts with a neutral dark image. Put your pictures in
`~/Pictures/Wallpapers`, then press **Super+Shift+W** to choose one. The bar
automatically chooses the first connected monitor; set `monitor` in
`bar/Settings.qml` if you want a particular output. `config/monitors.lua`
uses the display's preferred mode. Super+W opens Zen Browser when installed,
or Firefox otherwise. If you copy this live directory without exporting it,
run `setup-arch` to clear a wallpaper path that does not exist on the new PC.

The standalone `~/.config/kitty/kitty.conf` include is needed for the themed
terminal; the setup script creates it. Other application settings outside this
directory are not part of the portable copy.

The modular, monochrome Quickshell bar is documented in [bar/README.md](bar/README.md).
Start with `bar/Settings.qml` for appearance and `bar/modules/` for individual items.
Each file includes comments explaining its role and the relevant system bindings.

- Click the Arch icon for applications; right-click for session actions.
- Click workspace dots to switch workspaces.
- Click the bell left of the date for notifications; click the date for the calendar.
- Click Wi-Fi for the network list, on/off switch and password prompt.
- Click Bluetooth for nearby/paired devices, connection controls and pairing prompts.
- Click other status indicators for their corresponding controls.
- The far-right power icon opens volume and brightness sliders above a 2×2 grid
  of Lock, Sleep, Restart and Power off tiles.
- Click volume or press **Ctrl+Alt+V** for the animated Sound Studio panel.
  Configure outputs, microphones, app volumes/routing and hardware profiles.
  Right-click volume to mute; scroll it to change volume.
  See [sound controls](bar/audio/README.md).
- **Super+N** opens the Quickshell notification center.
- **Super+S** shows or hides the special workspace. **Super+Alt+S** sends the
  focused window there; use Super+Shift+number to move it back to a regular workspace.
- **Super+Shift+W** opens the wallpaper grid. Add images to `~/Pictures/Wallpapers`
  and press Refresh; successful selections are restored at login.

Regular shortcuts: Super+R launcher, Super+T terminal, Super+E files, Super+L lock,
Super+V clipboard, Super+Shift+S screenshot, Super+Shift+R Hyprland reload.

`config/` holds your Hyprland input, window styling, applications and shortcuts.
`scripts/start-desktop.sh` launches the bar and independent desktop services.
The old Dynamic Island is removed from the active setup.

Restore Waybar with `~/.config/hypr/scripts/rollback-bar.sh`.
Re-enable Quickshell with `~/.config/hypr/scripts/barctl restart`.
Old setup snapshots and unused installation files have been removed.

Notification appearance and behavior: [notifications/README.md](notifications/README.md).

Wallpaper files, settings and diagnostics: [wallpaper/README.md](wallpaper/README.md).

Lock-screen appearance and wallpaper integration: [lockscreen/README.md](lockscreen/README.md).

Application launcher appearance and commands: [launcher/README.md](launcher/README.md).
