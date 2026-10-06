# -----------------------------------------------------
# ALIASES
# -----------------------------------------------------

# -----------------------------------------------------
# General
# -----------------------------------------------------
alias c='clear'
alias nf='fastfetch'
alias pf='fastfetch'
alias ff='fastfetch'
alias ls='eza -a --icons=always'
alias ll='eza -l --icons=always'
alias lt='eza -a --tree --level=1 --icons=always'
# color directories cyan (bold cyan) rather than the default bold-blue slot
set -gx EZA_COLORS "di=1;36"
alias shutdown='systemctl poweroff'
alias v='$EDITOR'
alias vim='$EDITOR'
alias wifi='nmtui'

# -----------------------------------------------------
# Window Managers
# -----------------------------------------------------

# Hyprland with Hyprland

# -----------------------------------------------------
# Git
# -----------------------------------------------------
alias gs="git status"
alias ga="git add"
alias gc="git commit -m"
alias gp="git push"
alias gpl="git pull"
alias gst="git stash"
alias gsp="git stash; git pull"
alias gfo="git fetch origin"
alias gcheck="git checkout"
alias gcredential="git config credential.helper store"

# Claude

function codex
    if contains -- --yolo $argv
        command codex --dangerously-bypass-hook-trust $argv
    else
        command codex $argv
    end
end
