# Wallpaper switcher

Press **Super+Shift+W** to open or close the native Quickshell grid. Add images to
`~/Pictures/Wallpapers`, then press the circular Refresh button. Subfolders are
included; unfinished downloads, hidden files and unsupported formats are ignored.
JPG/JPEG, PNG, WebP and BMP are supported. Unreadable images are skipped with a
visible count. New thumbnails appear in batches; you can select a loaded image
while the remaining collection is still being processed. The counter shows scan
progress. Cached thumbnails are reused on subsequent opens.

Click a thumbnail, or Tab to a tile and use Enter/Space. Arrow keys move between
tiles. A blue border and **Active** badge indicate the wallpaper actually reported
by Hyprpaper. Escape, the close button, a second shortcut press, or clicking away
dismisses the popup. The popup also closes on lock/fullscreen and when another
bar menu opens. No tooltips or animated transitions are added.

## Customization

All UI settings are in `../bar/Settings.qml`, under the wallpaper comment:

- `wallpaperFolder`: collection path; `~` is supported.
- `wallpaperFit`: `cover` (default), `contain`, `tile`, or `fit`.
- `wallpaperWidth`, `wallpaperHeight`, `wallpaperColumns`,
  `wallpaperMinimumTileWidth`: panel and grid sizing.
- `wallpaperPadding`, `wallpaperSpacing`, `wallpaperRadius`,
  `wallpaperCardRadius`, `wallpaperLabelHeight`: layout and rounding.
- `wallpaperBackgroundOpacity`: background only; thumbnails and text stay opaque.
- Other `wallpaper*` constants: colors, font, text/icon sizes, button dimensions,
  thumbnail resolution and scrollbar width.

The target display uses the existing `monitor` setting. Change the opening
shortcut near the end of `../config/keybinds.lua`, then reload Hyprland.

## Files and responsibilities

- `../bar/popups/WallpaperMenu.qml`: overlay, grid layout and focus handling.
- `../bar/components/WallpaperTile.qml`: rounded thumbnail, filename and active badge.
- `../bar/components/WallpaperButton.qml`: refresh/close action styling.
- `../bar/core/WallpaperState.qml`: popup state and dismissal coordination.
- `../bar/services/WallpaperService.qml`: asynchronous JSON adapter for the UI.
- `../bar/services/wallpaper_backend.py`: scanning, thumbnail cache, image validation,
  Hyprpaper startup/IPC, state persistence and restore. Filenames are passed in
  argument arrays; safe cache symlinks avoid Hyprpaper's comma-separated syntax.
- `hyprpaper.conf`: minimal IPC-enabled config used only if the helper starts
  Hyprpaper. An already-running Hyprpaper is reused.
- `../bar/assets/icons/lucide/{image,x}.svg`: local SVG symbols matching the bar.
- `../bar/tests/test_wallpaper_backend.py`: isolated backend regression tests.

The shell and local `qmldir` files register these pieces. `../bar/core/Ipc.qml`
exposes the menu and diagnostics; the existing Wi-Fi, Bluetooth and power menu
state files dismiss this panel when their menus open. The existing bar layout
is unchanged; opening uses the shortcut rather than a new bar button.

## Remembering the choice

After Hyprpaper confirms a successful apply, the helper atomically saves the
original image path, monitor and fit mode in `state.json` beside this README.
It also updates the `current` symlink for the native Hyprlock background. The
locker reads that image directly, without running this helper at lock time.
`../scripts/start-desktop.sh` invokes `restore` at login, independently of the
bar and notification process. With no saved choice, it leaves the background
alone and does not start Hyprpaper. If a saved image is moved or deleted, the
helper keeps the saved state and reports the failure in the restore log.

Thumbnails and safe backend symlinks live in `$XDG_CACHE_HOME/hypr-wallpapers`
(normally `~/.cache/hypr-wallpapers`). Modified images get new thumbnails.
The cache can be removed while the picker is closed; opening/Refresh rebuilds
it. Original images are never moved or edited. Old cache entries are not pruned
automatically. Keep the cache directory path free of commas/newlines.

The integration uses installed Hyprpaper 0.8.4 and Python Pillow. Its current IPC
commands are documented in the [Hyprpaper wiki](https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/#ipc).

## Commands and validation

```sh
sh ~/.config/hypr/scripts/barctl wallpaper
sh ~/.config/hypr/scripts/barctl wallpaper-status
python3 -B -m unittest discover -s ~/.config/hypr/bar/tests -p test_wallpaper_backend.py
```

Logs: `$XDG_RUNTIME_DIR/hypr-minimal/hyprpaper.log`,
`wallpaper-restore.log` and the existing `bar.log` in the same directory.
The restore log is created when desktop startup runs.

Validation used temporary images/state for real Hyprpaper apply and restore,
including a filename with spaces, a comma, `#` and an apostrophe. Both empty and
populated grids were rendered. The original background was restored afterwards;
no production wallpaper was selected. Networking and power actions were not run.
