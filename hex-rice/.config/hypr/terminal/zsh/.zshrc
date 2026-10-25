# Interactive Kitty shell. No framework or network operations during startup.
[[ -o interactive ]] || return
# Zsh otherwise briefly draws an inverse '%' before rendering the first prompt.
PROMPT_EOL_MARK=''
typeset -U path PATH
path=("$HOME/.local/bin" "$HOME/.cargo/bin" $path)

# Share history between terminals and avoid saving duplicate commands or commands
# prefixed with a space. History files are private to your user.
typeset _previous_umask=$(umask)
umask 077
mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/zsh"
HISTFILE="${XDG_STATE_HOME:-$HOME/.local/state}/zsh/history"
touch "$HISTFILE"
chmod 600 "$HISTFILE"
umask "$_previous_umask"
unset _previous_umask
HISTSIZE=20000
SAVEHIST=20000
setopt SHARE_HISTORY HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS
setopt AUTO_CD INTERACTIVE_COMMENTS COMPLETE_IN_WORD
bindkey -e
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# Cache completion metadata; rebuild after package changes or once each day.
autoload -Uz compinit
typeset _completion_cache="${XDG_CACHE_HOME:-$HOME/.cache}/hypr-terminal/zcompdump"
mkdir -p "${_completion_cache:h}"
if [[ -n ${_completion_cache}(#qN.mh-24) ]]; then
    compinit -C -d "$_completion_cache"
else
    compinit -d "$_completion_cache"
fi
unset _completion_cache
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Keep familiar commands available; the enhanced variants are opt-in aliases.
alias ls='eza --group-directories-first'
alias ll='eza -lh --icons=auto --group-directories-first'
alias la='eza -lah --icons=auto --group-directories-first'
alias tree='eza --tree --level=2 --icons=auto'
alias catp='bat --paging=never'
alias grep='grep --color=auto'
alias wallpaper-colors='sh "$HOME/.config/hypr/scripts/terminal-theme"'
export LESS='-R'
export BAT_THEME='ansi'
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border=rounded --info=inline --color=16'

# These native integration scripts are generated once by update-terminal-shell.
# Sourcing them avoids spawning generators before the first prompt on every open.
source "$HYPR_TERMINAL/generated/zoxide.zsh"
# Ctrl+R searches command history; Ctrl+T searches files; Alt+C finds directories.
source "$HYPR_TERMINAL/generated/fzf.zsh"
if [[ -r /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
elif [[ -r "$HYPR_TERMINAL/vendor/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]]; then
    source "$HYPR_TERMINAL/vendor/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
# Our widget setup is static; bind once rather than wrapping it on every prompt.
ZSH_AUTOSUGGEST_MANUAL_REBIND=1
export STARSHIP_CONFIG="$HOME/.config/hypr/terminal/starship.toml"
source "$HYPR_TERMINAL/generated/starship.zsh"
# Job information lives in the left prompt. Avoid launching Starship a second
# time just to render a usually empty right prompt.
RPROMPT=''
# Syntax highlighting belongs last, after widgets and prompt initialization.
if [[ -r /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
    source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
elif [[ -r "$HYPR_TERMINAL/vendor/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]]; then
    source "$HYPR_TERMINAL/vendor/usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Print the optional image banner once, after setup and before the first prompt.
source "$HYPR_TERMINAL/zsh/fastfetch.zsh"
