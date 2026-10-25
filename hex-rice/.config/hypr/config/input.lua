hl.config({
    input = {
        kb_layout = "us",
        follow_mouse = 1,
        sensitivity = 0,
        repeat_delay = 250,
        repeat_rate = 35,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            scroll_factor = 0.3,
        },
    },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
