# Quickshell application launcher

Open with Super+R, a tap of left Super, or the bar's Arch button.
The shared `../scripts/launcher` command starts one Quickshell instance on demand
and toggles it on later calls.

- Type to filter installed desktop applications by name, description or keyword.
  Exact names and name prefixes rank first.
- Click an application or use Up/Down and Enter to launch it.
- Click a star or press Ctrl+P on the selected result to toggle a favorite.
- Favorites appear above the full alphabetical application list. The row scrolls
  horizontally when needed; Tab also reaches favorite buttons.
- Escape or clicking outside closes the panel. Opening it again clears search.
- Terminal applications launch through kitty, matching `config/programs.lua`.

Favorites persist in `favorites.json` beside `shell.qml`; the initial favorites
are Firefox, kitty, Files and Code OSS, when installed. An empty saved list stays
empty. Application discovery comes from Quickshell's live desktop-entry index.

Appearance is in `shell.qml`: panel color `#e01b1e27` (alpha first), 28px corners,
blue accents, 160ms fades, 240ms scale entrance, and animated hover/selection.
Launcher-only background blur is configured in `../config/appearance.lua`.

Commands:

```sh
sh ~/.config/hypr/scripts/launcher
sh ~/.config/hypr/scripts/launcher --search firefox
sh ~/.config/hypr/scripts/launcher --close
sh ~/.config/hypr/scripts/launcher --status
quickshell -p ~/.config/hypr/launcher log --no-color -t 40
```

The old Fuzzel theme and private binary remain available for rollback. Clipboard
history and other dmenu actions continue using system Fuzzel. To open the old
application launcher directly:

```sh
~/.config/hypr/launcher/bin/fuzzel --config ~/.config/hypr/launcher/fuzzel.ini
```
