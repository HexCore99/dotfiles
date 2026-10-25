# Kitty terminal

Open Kitty as usual with **Super+T**. It starts Arch's Zsh when installed, with
a fallback to the locally bundled Zsh on the original machine, and uses a
minimal, two-line Starship prompt, translucent dark background, JetBrains Mono
Nerd Font, and accents extracted from your current wallpaper by **pywal16**.
A compact Fastfetch banner with a random local image appears once per new Kitty
pane, before the first prompt. It uses Kitty's native graphics protocol.

Startup uses pre-generated native shell integrations rather than spawning their
generators each time. The first prompt has no temporary `%` marker or separate
right-prompt render. Kitty's shell integration keeps its cursor steady, and tiled
resize notifications use a 10 ms debounce to avoid a late prompt redraw.
After upgrading Starship, zoxide or fzf, regenerate their integrations with
`sh ~/.config/hypr/scripts/update-terminal-shell`.

## Customize

- `kitty.conf`: font size (12 pt), padding (18 px), background opacity (0.86),
  cursor, scrolling and tabs. Lower opacity makes the wallpaper more visible.
  `remember_window_size no` prevents Kitty from restoring a maximized state over
  other tiled windows; Hyprland controls its tiled size.
- `starship.toml`: prompt layout, directory, Git information and language context.
  ANSI color names let the prompt follow the wallpaper palette.
- `zsh/.zshrc`: aliases, completion, history and plugins.
- `fastfetch.jsonc`: startup system information, labels, spacing and colors.
- `zsh/fastfetch.zsh`: image rotation, image size and once-per-pane startup guard.
  Images live in `~/.config/fastfetch/images/`; add or remove PNGs there to change
  the rotation. Run `fastfetch` to display it again. Arguments such as
  `fastfetch --help` retain the normal CLI behavior. Your existing global
  `~/.config/fastfetch/config.jsonc` is preserved; `command fastfetch` uses it.
  Goku and Zoro were recovered from commit `deee249` of
  [Ronin-CK/fastfetchPNG-images](https://github.com/Ronin-CK/fastfetchPNG-images),
  since the latest revision deletes both PNGs. The clone is kept in
  `terminal/fastfetchPNG-images/`; originals were copied to the images folder.
- `../scripts/terminal-theme`: palette generation. The fixed `181b20` background
  and `e5e8eb` foreground keep the terminal dark and legible across wallpapers.
- `colors.conf`: generated palette; manual edits are overwritten on regeneration.

Kitty's standard **Ctrl+Shift+F5** reloads its configuration. Font zoom uses
**Ctrl+Shift+Plus / Minus**, and **Ctrl+Shift+Backspace** resets the font size.
Open a new Kitty window after changing its shell configuration.

## Shell tools

- **Right arrow** accepts a muted autosuggestion from your history.
- **Tab** completes commands and paths; **Ctrl+R** searches command history.
- **Ctrl+T** searches files; **Alt+C** finds directories.
- `z name` jumps to a frequently visited directory using zoxide.
- `ll`, `la`, `tree` use eza; `catp file` displays a file with bat highlighting.
- `wallpaper-colors` refreshes the palette if the source changed.
- `sh ~/.config/hypr/scripts/terminal-theme --force` forces regeneration.

## Wallpaper integration

The wallpaper backend queues `scripts/terminal-theme` after a successful apply
or login restore. It runs separately from wallpaper loading, serializes requests,
and reads the latest `wallpaper/current` symlink after acquiring its lock.
Completed palettes are reused. Filenames are passed as quoted arguments.

Pywal runs with `-n -s -t -e`: Hyprpaper stays in charge of wallpaper, other
terminal types and desktop components are unaffected. Kitty reloads its native
configuration with SIGUSR1 after the palette is written atomically; running
commands stay open. Palette failures leave the previous colors usable.

Logs: `${XDG_RUNTIME_DIR}/hypr-minimal/terminal-theme.log`.
Cache: `~/.cache/hypr-terminal/`. Zsh history: `~/.local/state/zsh/history`.

## Local dependencies and rollback

`vendor/` contains Zsh 5.9.2, fzf 0.74.5, autosuggestions 0.7.1, syntax
highlighting 0.8.0, extracted from signed Arch
packages verified against your existing Arch keyring. Licenses remain in
`vendor/usr/share/licenses/`; package checksums are in `packages.sha256`.
`tools/` is an isolated Python environment with pywal16 3.8.15, ColorThief 0.2.1
and Pillow 13.0.0. ColorThief extracts the palette without requiring ImageMagick.
These local dependencies are not updated by pacman. The portable export omits
`vendor/` and `tools/`; `scripts/setup-arch` installs system Zsh, fzf and
plugins, then recreates the Python environment and generated integrations.

`~/.config/kitty/kitty.conf` includes this directory's `kitty.conf`. Your existing
`~/.config/starship.toml`, Bash files, login shell and desktop startup are preserved.
Zsh runs only in Kitty through its `shell` wrapper and private `ZDOTDIR`.
Remove that include to restore Kitty's defaults. Remove the optional theming
block in `bar/services/wallpaper_backend.py` to disable automatic palette updates.

References: [Kitty configuration](https://sw.kovidgoyal.net/kitty/conf/),
[Starship configuration](https://starship.rs/config/),
[pywal16](https://github.com/eylles/pywal16).
