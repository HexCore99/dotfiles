# Prefer Arch's maintained Zsh; keep the bundled copy as a fallback on the
# original machine. Bundled modules must never override system Zsh modules.
typeset -g HYPR_TERMINAL="$HOME/.config/hypr/terminal"
if [[ ! -x /usr/bin/zsh && -d "$HYPR_TERMINAL/vendor/usr/lib/zsh/5.9.2" ]]; then
    module_path=("$HYPR_TERMINAL/vendor/usr/lib/zsh/5.9.2" $module_path)
    fpath=("$HYPR_TERMINAL/vendor/usr/share/zsh/functions"/**/*(N/) $fpath)
fi
typeset -U path PATH
path=("$HYPR_TERMINAL/tools/bin" $path)
