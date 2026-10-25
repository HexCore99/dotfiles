local programs = require("config.programs")
local mainMod = "SUPER"

-- Programs and window actions
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(programs.terminal))
hl.bind(mainMod .. " + Q", hl.dsp.window.close())

hl.bind(mainMod .. " + SHIFT + Escape", hl.dsp.exec_cmd(
    "command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch 'hl.dsp.exit()'"
))

hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(programs.fileManager))
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(programs.menu))
hl.bind(mainMod .. " + ALT + Space", hl.dsp.window.float({ action = "toggle" }))
-- Tap the left Super key to open the launcher on release.
hl.bind(mainMod .. " + Super_L", hl.dsp.exec_cmd(programs.menu), { release = true })
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))

-- Move focus
-- Cycle windows in the focused monitor's current workspace.
hl.bind("ALT + Tab", hl.dsp.window.cycle_next({ next = true }))
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))

hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())

-- Caelestia-style scratchpad: toggle it anywhere, or send the focused window there.
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-- SUPER + number: switch workspace
-- SUPER + SHIFT + number: move window to workspace
for i = 1, 10 do
    local key = i % 10

    hl.bind(
        mainMod .. " + " .. key,
        hl.dsp.focus({ workspace = i })
    )

    hl.bind(
        mainMod .. " + SHIFT + " .. key,
        hl.dsp.window.move({ workspace = i })
    )
end

-- Scroll through workspaces
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

-- Move and resize windows with SUPER + mouse buttons
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), {
    mouse = true,
})

hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), {
    mouse = true,
})

-- Volume
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level volume up"
), { locked = true, repeating = true })

hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level volume down"
), { locked = true, repeating = true })

hl.bind("XF86AudioMute", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level volume mute"
), { locked = true, repeating = true })

hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level microphone mute"
), { locked = true, repeating = true })

-- Brightness
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level brightness up"
), { locked = true, repeating = true })

hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level brightness down"
), { locked = true, repeating = true })

hl.bind(mainMod .. " + SHIFT + left", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level brightness down"
))

hl.bind(mainMod .. " + SHIFT + right", hl.dsp.exec_cmd(
    "sh ~/.config/hypr/scripts/bar-level brightness up"
))

-- Media controls: requires playerctl
hl.bind("XF86AudioNext", hl.dsp.exec_cmd(
    "playerctl next"
), { locked = true })

hl.bind("XF86AudioPause", hl.dsp.exec_cmd(
    "playerctl play-pause"
), { locked = true })

hl.bind("XF86AudioPlay", hl.dsp.exec_cmd(
    "playerctl play-pause"
), { locked = true })

hl.bind("XF86AudioPrev", hl.dsp.exec_cmd(
    "playerctl previous"
), { locked = true })

-- Full-screen screenshot to clipboard
hl.bind("Print", hl.dsp.exec_cmd(
    [[grim - | wl-copy --type image/png]]
))

-- Selected-region screenshot to clipboard
hl.bind("ALT + grave", hl.dsp.exec_cmd(
    [[grim -g "$(slurp)" - | wl-copy --type image/png]]
))

-- Selected-region screenshot to file and clipboard
hl.bind("ALT + 1", hl.dsp.exec_cmd(
    [[region=$(slurp) && directory="$HOME/Pictures/screenshot" && mkdir -p "$directory" && file="$directory/$(date +%Y-%m-%d_%H-%M-%S-%N).png" && grim -g "$region" "$file" && wl-copy --type image/png < "$file"]]
))

-- Independent lock screen and reload; no shell IPC needed.
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("pgrep -x hyprlock >/dev/null || hyprlock -c ~/.config/hypr/hyprlock.conf"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd(
    "command -v zen-browser >/dev/null 2>&1 && exec zen-browser || exec firefox"
))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("sh ~/.config/hypr/scripts/barctl sound"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd(
    [[region=$(slurp) && grim -g "$region" - | wl-copy --type image/png]]
))
-- Clipboard history, shown in the same simple launcher.
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd(
    [[cliphist list | fuzzel --dmenu | cliphist decode | wl-copy]]
))

-- Quickshell notification history; the bell beside the date opens the same panel.
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("sh ~/.config/hypr/scripts/barctl notifications"))

-- Native wallpaper grid. This opens the menu without changing the wallpaper.
hl.bind(mainMod .. " + SHIFT + W", hl.dsp.exec_cmd("sh ~/.config/hypr/scripts/barctl wallpaper"))
