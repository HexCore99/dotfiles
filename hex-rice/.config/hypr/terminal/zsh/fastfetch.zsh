# Native Fastfetch with one randomly selected local image. Zsh arrays preserve
# filenames with spaces, and $RANDOM avoids spawning a picker process.
# Passing arguments keeps Fastfetch's normal CLI available (e.g. --help).
fastfetch() {
    if (( $# )); then
        command fastfetch "$@"
        return
    fi
    local folder="${HYPR_FASTFETCH_IMAGES:-${XDG_CONFIG_HOME:-$HOME/.config}/fastfetch/images}"
    local -a images
    images=("$folder"/*.(png|PNG|jpg|jpeg|webp)(N.))
    local width=24 height=12
    (( COLUMNS < 70 || LINES < 23 )) && { width=16; height=8; }
    if [[ -n $KITTY_WINDOW_ID ]] && (( ${#images} )); then
        local image=${images[$(( RANDOM % ${#images} + 1 ))]}
        command fastfetch --config "$HYPR_TERMINAL/fastfetch.jsonc" \
            --kitty-direct "$image" --logo-width "$width" --logo-height "$height"
    else
        # Missing images or another terminal: use the small native ASCII logo.
        command fastfetch --config "$HYPR_TERMINAL/fastfetch.jsonc"
    fi
}

# Show once per Kitty pane, before its first prompt. Keep it synchronous so image
# placement cannot race with typing or redraw the prompt later in the background.
# Nested shells and `exec zsh` in the same pane do not print a second banner.
if [[ -t 1 && -n $KITTY_WINDOW_ID && -z $ZSH_EXECUTION_STRING &&
      ${HYPR_FASTFETCH_SHOWN:-} != "$KITTY_PID:$KITTY_WINDOW_ID" ]] &&
      (( $+commands[fastfetch] )); then
    export HYPR_FASTFETCH_SHOWN="$KITTY_PID:$KITTY_WINDOW_ID"
    fastfetch
fi
