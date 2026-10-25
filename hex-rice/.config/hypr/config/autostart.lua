-- This script also supports starting the components in the current session.
hl.on("hyprland.start", function()
    hl.exec_cmd("sh ~/.config/hypr/scripts/start-desktop.sh")
end)
