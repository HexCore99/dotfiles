-- Your desktop's appearance. No generated colours or theme framework.
hl.config({
    general = {
        layout = "dwindle",
        gaps_in = 4,
        gaps_out = 8,
        border_size = 2,
        col = {
            active_border = "rgb(89b4fa)",
            inactive_border = "rgb(45475a)",
        },
    },
    dwindle = { preserve_split = true },
    decoration = {
        rounding = 6,
        active_opacity = 1,
        inactive_opacity = 1,
        blur = { enabled = true },
        shadow = { enabled = true },
    },
    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        background_color = "rgb(181825)",
    },
})

-- Ease in gently, then settle into place. Keep the fade and tiled movement in sync.
hl.curve("gentleWindow", { type = "bezier", points = { { 0.45, 0.0 }, { 0.25, 1.0 } } })
hl.animation({ leaf = "windowsIn", enabled = true, speed = 5.0, bezier = "gentleWindow", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 5.0, bezier = "gentleWindow" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 4.0, bezier = "gentleWindow", style = "popin 90%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 5.0, bezier = "gentleWindow" })
hl.animation({ leaf = "fadeOut", enabled = true, speed = 4.0, bezier = "gentleWindow" })

-- Give the Super+S special workspace the same measured pace.
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5.0, bezier = "gentleWindow", style = "slidefadevert 15%" })

-- Frosted glass for the application launcher; its animations run inside QML.
hl.layer_rule({
    name = "application-launcher-glass",
    match = { namespace = "^quickshell-app-launcher$" },
    blur = true,
    ignore_alpha = 0,
})
