# Quickshell notifications and separate calendar

The bell immediately **left of the date** opens notification history. Clicking the
date/time opens **only the calendar**. Super+N opens notification history too.
Escape or an outside click closes a panel. Opening one panel closes the other.
The center opens with a scale/fade transition; cards animate into place, and
buttons and the Quiet mode switch provide animated feedback.

The separate `../notification-shell.qml` process owns the standard desktop
notification service. It remains running when the bar restarts or returns to
Waybar. The root entry point lets both shells import the same `bar/Settings.qml`
singleton and session services without duplicating constants or helper scripts.
SwayNC and the GTK calendar companion are no longer started or used.

## Customize in one place

Edit **`../bar/Settings.qml`**. The commented notification/calendar section holds
the panel colors, radius, padding, widths/heights, card/icon sizes, calendar clock
size, normal popup timeout, and maximum history size. Text uses the existing
shared `font` setting for the calendar; notifications use `notificationFont`.
Notification-only colors and sizes have `notification` prefixes.
The adaptive notification center uses an opaque background for consistent contrast.
The notification center and toast cards now use `NotificationTheme.qml`: the
active wallpaper's dominant chromatic hue supplies dark surfaces and a pastel
accent with readable text. `palette.py` samples a small image via Pillow off the
UI thread; a file watcher recomputes colors when `wallpaper/state.json` changes.
Missing wallpaper files retain the previous usable palette. The calendar keeps
its own styling. Notification color constants in Settings are legacy fallbacks;
edit NotificationTheme.qml/palette.py to customize the adaptive palette.

All and Unread filters preserve the history. Read all clears unread flags; Clear
all dismisses notifications. Quiet mode is the existing Do Not Disturb control.
The center uses compact date-grouped cards, app actions, and a dedicated empty
state. Buttons and interactive cards show pointer cursors.
Clicking a card invokes the sending app's default action when available, closes
the panel or popup, and marks it read. Cards without a default action are marked
read when clicked. Notifications remain in history until dismissed. Timestamps
show relative age. Saving QML reloads the affected shell automatically.

The calendar uses system local time (Asia/Dhaka on this desktop), displaying a
12-hour clock and AM/PM. Use the month arrows to browse, click a date to select it,
and click Today to return to the current date. It does not create appointments.

## Files and responsibilities

```text
notification-shell.qml              Independent entry point and IPC commands
notifications/
  services/NotificationStore.qml     Receives notifications, history, DND, expiry
  core/PanelState.qml                Which independent popup is open
  components/PopupFrame.qml          Window, outside-click dismissal, Escape
  components/PanelButton.qml         Shared button appearance
  components/NotificationCard.qml    App icon/image, text, close and action buttons
  components/CalendarGrid.qml        Month navigation and date selection
  popups/NotificationCenter.qml      History, Clear All, DND
  popups/NotificationToasts.qml      Passive top-center popup stack
  popups/CalendarPopup.qml           Separate clock and calendar
scripts/start-notifications.sh       Starts one independent daemon using a lock
bar/modules/Notifications.qml        Bell button
bar/modules/Clock.qml                Date/time button
```

Popups disappear after five seconds by default, including critical ones, while
history and actions remain available. App-requested timeouts are respected;
explicitly persistent popups stay until dismissed. DND suppresses popups and keeps history.
Transient notifications skip history. Replacement notifications update the same
entry. Clear All dismisses history; action buttons invoke the sending app's action.
History is bounded by `notificationHistoryLimit` to avoid unlimited memory growth.

History survives **bar restarts** and QML reloads. It is session memory: fully
restarting the notification process or logging out clears it. Existing SwayNC
history is not imported. No notification text is written to a history file.

## Commands and diagnostics

```sh
~/.config/hypr/scripts/barctl notifications
~/.config/hypr/scripts/barctl calendar
quickshell -p ~/.config/hypr/notification-shell.qml ipc call notifications status
quickshell -p ~/.config/hypr/notification-shell.qml ipc call notifications close
quickshell -p ~/.config/hypr/notification-shell.qml ipc call notifications dnd true
notify-send 'Hello' 'A popup, then an entry in history.'
```

Logs are in `$XDG_RUNTIME_DIR/hypr-minimal/notifications.log`. Startup is independent
of `scripts/start-bar.sh`; only `notification-shell.qml` owns the notification bus.
Do not start another notification daemon alongside it.
