# Slim Quickshell bar

A set of separate rounded charcoal cards: Arch icon and workspace dots on
the left, a centered notification/time card, then memory, open apps,
connectivity/audio, battery and power cards on the right. Open apps have their
own card immediately left of Wi-Fi; it disappears when no windows are open.
The spaces between cards are transparent and
pass pointer input through to the desktop. Workspace selection uses a short
width/color transition; other bar controls and popups remain animation-free.
Its far-right power button opens a
separate rounded menu with volume and brightness sliders above a 2×2 power grid.

The Arch button and Super+R share a translucent Quickshell application launcher. Its
search, favorites and usage are documented in [../launcher/README.md](../launcher/README.md).

## Customize

Start with **Settings.qml**. It controls the height, margins, colors, font,
preferred monitor and number of persistent workspace dots. Saving imported QML
files reloads the bar automatically. The current style is 34 px high, 2 px from the top and sides, with eight workspace
circles. The active workspace is muted salmon (`#ad685a`), occupied workspaces are
gray (`#4d4d4d`) and empty ones darker gray (`#2c2c2c`) on charcoal (`#1d2021`).

The font is JetBrains Mono Bold, chosen as a close match to the screenshot.
`fontSize` sets status labels; `clockFontSize` sets the larger clock.
`clockFormat` controls the date wording. `workspaceWidth` controls dot spacing,
and `workspaceDotSize` controls circle diameter.

The active workspace dot smoothly expands into a pill. `workspaceAnimations`
enables this effect, `workspaceAnimationDuration` sets its duration (180 ms),
and `workspaceActiveDotWidth` controls the pill width (25 px). Selection from
clicks, scrolling and keyboard shortcuts uses the same animation. The button
width stays fixed, so neighboring controls do not shift.

`barGroupGap` sets the gaps between the right-hand cards; `barGroupPadding`
and `barGroupSpacing` set internal spacing. `barRadius`, `barGroupBorderWidth`
and `barGroupOpacity` style every card consistently. The shared frame lives
in `components/BarGroup.qml`; `Bar.qml` arranges the groups. The existing
top strip remains reserved for windows, while only the cards receive clicks.

Icons now use **local Lucide SVGs**, not Nerd Font glyphs. The Arch logo uses a
separate Simple Icons SVG. `iconSize` (currently 18) controls icons independently
of `fontSize`; `iconSpacing` controls the gap between an icon and its label.
`workspaceDotSize` controls the real circle shapes used for workspace indicators.
Keep the bar height at least four pixels larger than the icon size.

Files are in `assets/icons/lucide/` and `assets/icons/brands/`. To choose a different
Lucide icon, change the module's `icon` name and add that SVG to the local folder.
`components/SvgIcon.qml` handles scaling and tinting. Source revisions and upstream
licenses are included in `assets/icons/SOURCES.md` and the license files.

Every source file has a short explanation. Important bindings and lifecycle
choices have comments beside them; visual modules do not contain process scripts.

## Files and responsibilities

```text
bar/
  shell.qml                 Entry point: Bar + diagnostic IPC
  Settings.qml              Your appearance and layout preferences
  Bar.qml                   Only the left / center / right layout
  components/BarButton.qml  Shared icon/text row, tooltip and mouse signals
  components/SvgIcon.qml    Local SVG rendering, size and tint
  assets/icons/             Lucide SVGs, Arch logo and upstream licenses
  modules/                  One file per bar item
    Launcher.qml            Arch icon / application launcher
    Workspaces.qml          Persistent clickable workspace dots
    Clock.qml               Centered date/time; separate calendar action
    Notifications.qml       Bell immediately left of the date
    Network.qml             Icon-only Wi-Fi / Ethernet status and overlay
    RunningApps.qml         Icons for open apps on every workspace
    Bluetooth.qml           Adapter and connected-device status
    Battery.qml             UPower battery percentage
    Cpu.qml                 CPU utilization
    Memory.qml              RAM usage
    Volume.qml              PipeWire volume and mute
  services/                 System data adapters, independent of UI layout
    HyprlandService.qml     Workspaces, monitor and fullscreen
    NetworkService.qml      NetworkManager events
    BluetoothService.qml    BlueZ adapter/devices
    BatteryService.qml      UPower events
    AudioService.qml        PipeWire output tracking
    SystemService.qml       Receives CPU/RAM samples
    system-stats.py         One /proc sampler, every two seconds
    SessionService.qml      Lock state
    session-watch.py        Login1/Hyprlock watcher
  core/Actions.qml          Dispatches external app/menu actions
  core/actions.py           Fuzzel menus and external apps
  modules/Power.qml         Far-right power button
  popups/PowerMenu.qml       Sliders above a 2×2 power-action grid
  components/LevelSlider.qml  Shared volume/brightness control
  services/BrightnessService.qml  Coalesced brightnessctl writes and live reads
  components/PowerTile.qml  One icon/label tile
  core/PowerState.qml        Menu selection and dismissal
  core/power_actions.py      Allowlisted system action commands
  core/Ipc.qml              Diagnostic endpoint
  core/WifiState.qml        Network selection, scans and connection state
  popups/WifiMenu.qml       Native Wi-Fi overlay
  components/WifiNetworkRow.qml  Available/connected network row
  components/WifiPasswordForm.qml  Masked password input
  components/WifiButton.qml  Shared network controls
```

`qmldir` files register shared QML types. Services are singletons, so multiple
modules using one service do not create duplicate subscriptions or samplers.

## Controls

| Item | Left-click | Right-click / scroll |
| --- | --- | --- |
| Arch icon | Fuzzel applications | Session/power menu |
| Workspace dot | Switch workspace | Scroll to previous/next dot |
| Bell beside date | Notification center | — |
| Clock | Calendar only | — |
| Open app | Switch to its workspace and focus its window; repeated clicks cycle through that app's windows | Right-click: Open or force Quit |
| Wi-Fi | Native network overlay and password prompt | Toggle Wi-Fi |
| Bluetooth | Native device overlay and pairing prompts | Toggle Bluetooth |
| Battery | Battery details | — |
| CPU / memory | btop in Foot | — |
| Volume | pwvucontrol | Right-click mute; scroll ±5% |
| Power (far right) | Volume, brightness and 2×2 power options | — |

The power menu has a **volume slider**, then a **brightness slider**, with four
power options below in a 2×2 grid: **Lock / Sleep**, **Restart / Power off**.
Volume controls the current PipeWire output, caps at 100%, and unmutes when raised.
Brightness uses the actual screen backlight and follows hardware-key changes while
the menu is open. Brightness is kept at a minimum of 1%. Writes are coalesced during
dragging; unavailable controls are disabled with an explanation.

Tab moves between the sliders and action buttons. Left/Right adjusts a focused
slider; arrow keys navigate within the action grid. Enter/Space activates only a
focused action button. Escape or an outside click closes the menu. Opening it
never performs a power action, resizes windows, or changes levels.

Change `powerMenuWidth`, `powerMenuPadding`, `powerMenuSpacing`, `powerTileHeight`,
`powerAccent` and the other `power…` settings in Settings.qml. `powerTileWidth` is
derived from the menu width to keep two equal columns. The popup has no animations.
The launcher right-click shortcut still opens the same menu.

Lock uses your existing Hyprlock configuration. Sleep uses systemctl suspend and
Hypridle's existing lock-before-sleep hook. Restart/power off use systemctl reboot
and poweroff. Opening or closing the menu never performs a system action.

Bluetooth has a matching native overlay with a radio switch, connected devices,
paired devices and nearby discovery. Click Pair or Connect; connected devices have
a Disconnect button. PIN entry, displayed passkeys and numeric confirmation stay
inside the overlay. A private application-specific BlueZ agent handles these
requests without replacing another application's default pairing agent. Scanning
runs only while the overlay is open. Closing during pairing cancels authentication.
Battery percentage is shown when the device reports it. No device names are
evaluated as shell commands.

The Wi-Fi item is an icon only. Clicking opens the native overlay with a radio
switch, connected network and nearby networks. New WPA/WPA2/WPA3 personal networks
show a masked password field. Saved networks reuse NetworkManager credentials;
authentication errors allow retry. Advanced setup opens nmtui for enterprise or
legacy authentication. Scanning runs while the overlay is open. CPU is computed
from /proc/stat deltas; memory uses MemAvailable so reclaimable cache is excluded.
Battery and audio percentages come from live UPower and PipeWire services.
Missing network/adapter/battery state is shown as offline, off, or AC.

Existing app, media, lock and screenshot shortcuts remain available. Hardware
volume/mute/brightness keys use **scripts/bar-level** and continue to work if the
bar exits. **Super+N** opens Quickshell notification history. The old island's
Super+I dashboard shortcut has been removed.

## Startup, notifications and fallback

**scripts/start-desktop.sh** launches an independent Quickshell notification shell
and the bar supervisor.
**scripts/start-bar.sh** waits for the bar's IPC endpoint before stopping Waybar.
If the bar fails, it restores Waybar. A lock prevents duplicate bar supervisors.
The bar never takes keyboard focus and hides during fullscreen and screen lock.

The independent notification shell owns the notification daemon, popup cards,
history and a separate calendar. The bell opens history; date/time opens the
calendar. Its components and guide are in `../notifications/`; all appearance
constants are in `Settings.qml`. Restarting the bar preserves notification history.

```sh
~/.config/hypr/scripts/barctl status
~/.config/hypr/scripts/barctl restart
~/.config/hypr/scripts/barctl notifications
~/.config/hypr/scripts/barctl power
```

Return to Waybar persistently:

```sh
~/.config/hypr/scripts/rollback-bar.sh
```

Re-enable with `barctl restart`. The `bar/disabled` marker controls this choice.
Logs are in `$XDG_RUNTIME_DIR/hypr-minimal/bar.log` and `bar-session.log`.

The rejected island and its scripts are removed from the active setup. Old snapshots have been removed from the config folder. No Caelestia code is used.

## Dependencies

Uses the installed Quickshell, Python/PyGObject, NetworkManager, UPower, PipeWire,
WirePlumber, Fuzzel, Foot, btop, pwvucontrol, bluez-utils and util-linux.
Text uses the installed JetBrainsMono Nerd Font family with bold weight. Icons no longer
depend on its glyphs. SVG tinting uses the installed Qt5Compat GraphicalEffects
module (`qt6-5compat` on Arch).
No JavaScript package manager, additional desktop framework or compiled plugin.


Power action routing can be tested without changing your session:

```sh
python -B -m unittest discover -s ~/.config/hypr/bar/tests -v
```

These tests mock system commands; they do not sleep, lock, restart or power off.

Wi-Fi appearance constants are grouped under `wifi…` in Settings.qml, including
panel size, colors and background opacity. Passwords go directly through
Quickshell's NetworkManager API, never through shell arguments or diagnostics.
The overlay clears its password field after submission, cancellation and dismissal.
NetworkManager manages saved credentials. Escape or an outside click closes it.

Wi-Fi connection flow tests use fake networks and preserve the current connection:

```sh
sh ~/.config/hypr/scripts/test-wifi.sh
```

Bluetooth constants are grouped under `bluetooth…` in Settings.qml. By default
they follow the Wi-Fi colors and dimensions, with independent overrides available.
`core/BluetoothState.qml` owns the overlay state, `popups/BluetoothMenu.qml` owns
layout, and `components/BluetoothDeviceRow.qml`, `BluetoothDeviceSection.qml`,
`BluetoothPairingForm.qml` and `BluetoothButton.qml` own individual UI pieces.
`services/bluetooth-agent.py` performs asynchronous BlueZ operations and responds
to agent requests only after input from the pairing form. It never logs PINs.
The helper exits with its parent shell and is restarted automatically if it fails.

Agent tests run without pairing or disconnecting any hardware:

```sh
python -B -m unittest discover -s ~/.config/hypr/bar/tests -v
```
## Wallpaper grid

**Super+Shift+W** opens the modular wallpaper popup using installed Hyprpaper.
The collection is `~/Pictures/Wallpapers`; add images and press Refresh.
Appearance and collection settings are the `wallpaper*` constants in `Settings.qml`.
See [../wallpaper/README.md](../wallpaper/README.md) for architecture, persistence,
commands, logs and validation.

