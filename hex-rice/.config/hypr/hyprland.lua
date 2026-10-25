-- Minimal Hyprland setup. Each file below has one job.
-- Start with config/programs.lua, config/appearance.lua and config/keybinds.lua.
hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")

require("config.monitors")
require("config.appearance")
require("config.input")
require("config.keybinds")
require("config.autostart")
