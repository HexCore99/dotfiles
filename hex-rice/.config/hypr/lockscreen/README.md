# Native lock screen

Press **Super+L**, or choose **Lock** in the bar power menu. The existing
ten-minute idle lock and lock-before-sleep behavior also use this configuration.
The screen uses installed Hyprlock 0.9.6; it is independent of the bar and keeps
the existing PAM authentication. No session startup, authentication, or idle
settings were replaced.

The design has a dimmed, softly blurred wallpaper, a large 12-hour clock and
date, and a rounded dark sign-in card. The card shows your account name, a
password field and the active keyboard layout. Enter submits; Escape/Ctrl+U
clear the password. Blue indicates checking; the warm warning accent indicates
an authentication error or Caps Lock. Animations are disabled.

## Customize

- `theme.conf`: colors, card opacity, fonts, sizes, positions, rounding and
  wallpaper brightness/blur. The alpha in `$lock_card` controls card opacity
  (`ed` is about 93%, `ff` is solid). Positive center Y offsets move up.
- `../hyprlock.conf`: widget arrangement, displayed text, clock/date formatting
  and behavior. Each section explains its role.
- `lock.png`: 88-pixel rasterization of the bar's local Lucide lock SVG, displayed
  at 22 pixels by default. Hyprlock uses a PNG rather than an icon-font glyph.
- `hyprlock.previous.conf`: the original minimal config, kept for rollback.

Hyprlock reads native Hyprlang settings, so its appearance file is independent
of `bar/Settings.qml`. See the [Hyprlock configuration reference](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/)
for additional native options.

## Wallpaper integration

The existing wallpaper helper now atomically updates `../wallpaper/current`
after successful apply/restore. This symlink points to your original chosen
image, so locking needs no thumbnail scan, extra Python process, or shell parser.
The link was initialized from your existing saved choice. Changing the desktop
wallpaper updates the next lock screen automatically. Original images are
never modified; keep the selected image at its saved path.

The existing `config/keybinds.lua`, `bar/core/power_actions.py`, and
`hypridle.conf` already reference `hyprlock.conf`; their lock actions did not
need changes. New appearance settings apply the next time you lock.

## Validation

The installed Hyprlock parser was checked using an explicitly nonexistent
Wayland display. This parses the real config and its theme while preventing any
connection to your desktop. A deliberately invalid configuration was checked as
a negative control. The expected display-connection failure occurs after parsing.
The current session was not locked, and no password was submitted during testing.
Wallpaper tests cover updating the lock-background symlink and preserving the
existing wallpaper apply/restore behavior.
