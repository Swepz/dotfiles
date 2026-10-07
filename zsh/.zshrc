mkdir -p "$HOME/.local/state/zsh" "$HOME/.cache/zsh"
HISTFILE="$HOME/.local/state/zsh/history"
HISTSIZE=100000
SAVEHIST=100000
setopt share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks extended_history
setopt auto_cd interactive_comments no_beep
bindkey -e

autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

export GPG_TTY=$TTY
export MANPAGER="less -R --use-color -Dd+r -Du+b"
export MANROFFOPT="-P -c"
export EZA_COLORS="di=1;36"

alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'
alias ls='eza -a --icons=always'
alias ll='eza -l --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'
alias wifi='nmtui'
alias gs='git status'
alias ga='git add'
alias gc='git commit -m'
alias gp='git push'
alias gpl='git pull'
alias gst='git stash'
alias gsp='git stash; git pull'
alias gfo='git fetch origin'
alias gcheck='git checkout'
alias gcredential='git config credential.helper store'

claude() {
    python3 -c '
import json, os, sys, tempfile

path = os.path.expanduser("~/.claude.json")
cwd = sys.argv[1]
with open(path) as fh:
    config = json.load(fh)
project = config.setdefault("projects", {}).setdefault(cwd, {})
if project.get("hasTrustDialogAccepted") is not True:
    project["hasTrustDialogAccepted"] = True
    fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
    with os.fdopen(fd, "w") as fh:
        json.dump(config, fh, indent=2)
    os.replace(tmp, path)
' "$PWD" || return
    command claude --dangerously-skip-permissions "$@"
}

y() {
    local tmp cwd
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    command yazi "$@" --cwd-file="$tmp"
    IFS= read -r -d '' cwd < "$tmp"
    [[ -n "$cwd" && "$cwd" != "$PWD" && -d "$cwd" ]] && builtin cd -- "$cwd"
    command rm -f -- "$tmp"
}

source <(fzf --zsh)
eval "$(zoxide init zsh --cmd cd)"
eval "$(starship init zsh)"
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
